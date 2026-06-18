package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"os/exec"
	"sync"
	"time"
)

type Worker struct {
	cmd    *exec.Cmd
	stdin  io.WriteCloser
	stdout *bufio.Scanner
	mu     sync.Mutex
	uses   int
}

type workerRequest struct {
	ID   string `json:"id"`
	Code string `json:"code"`
}

type workerResponse struct {
	ID        string  `json:"id"`
	Stdout    string  `json:"stdout"`
	Stderr    string  `json:"stderr"`
	ElapsedMs float64 `json:"elapsed_ms"`
}

func spawnWorker(args []string) (*Worker, error) {
	cmd := exec.Command(args[0], args[1:]...)

	stdin, err := cmd.StdinPipe()
	if err != nil {
		return nil, err
	}
	stdoutPipe, err := cmd.StdoutPipe()
	if err != nil {
		return nil, err
	}
	// Worker process stderr goes to our stderr so startup errors are visible.
	cmd.Stderr = nil

	if err := cmd.Start(); err != nil {
		return nil, err
	}

	scanner := bufio.NewScanner(stdoutPipe)
	scanner.Buffer(make([]byte, 1<<20), 1<<20) // 1 MB per line

	// Wait for the READY signal before accepting requests.
	if !scanner.Scan() {
		_ = cmd.Process.Kill()
		return nil, fmt.Errorf("worker exited before READY: %w", scanner.Err())
	}
	if scanner.Text() != "READY" {
		_ = cmd.Process.Kill()
		return nil, fmt.Errorf("unexpected worker init output: %q", scanner.Text())
	}

	return &Worker{cmd: cmd, stdin: stdin, stdout: scanner}, nil
}

func (w *Worker) Run(id, code string, timeout time.Duration) (*workerResponse, error) {
	w.mu.Lock()
	defer w.mu.Unlock()

	payload, _ := json.Marshal(workerRequest{ID: id, Code: code})
	payload = append(payload, '\n')

	if _, err := w.stdin.Write(payload); err != nil {
		return nil, fmt.Errorf("write to worker stdin: %w", err)
	}

	type scanResult struct {
		resp workerResponse
		err  error
	}
	ch := make(chan scanResult, 1)

	go func() {
		if w.stdout.Scan() {
			var r workerResponse
			ch <- scanResult{r, json.Unmarshal([]byte(w.stdout.Text()), &r)}
		} else {
			ch <- scanResult{err: fmt.Errorf("worker stdout closed: %w", w.stdout.Err())}
		}
	}()

	select {
	case res := <-ch:
		if res.err != nil {
			return nil, res.err
		}
		w.uses++
		return &res.resp, nil
	case <-time.After(timeout):
		return nil, fmt.Errorf("execution timed out after %s", timeout)
	}
}

func (w *Worker) Kill() {
	_ = w.stdin.Close()
	_ = w.cmd.Process.Kill()
	_ = w.cmd.Wait()
}
