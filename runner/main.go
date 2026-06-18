package main

import (
	"crypto/rand"
	"encoding/hex"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"time"
)

func newID() string {
	b := make([]byte, 8)
	_, _ = rand.Read(b)
	return hex.EncodeToString(b)
}

func main() {
	addr     := flag.String("addr", ":8080", "listen address")
	poolSize := flag.Int("pool", 4, "number of persistent Julia workers")
	maxUses  := flag.Int("max-uses", 50, "recycle a worker after this many executions")
	timeout  := flag.Int("timeout", 10, "per-execution timeout in seconds")
	julia    := flag.String("julia", "julia", "Julia binary")
	script   := flag.String("script", "", "path to julia/worker.jl (default: <binary dir>/julia/worker.jl)")
	sysimage := flag.String("sysimage", "", "path to PackageCompiler sysimage .so (optional)")
	flag.Parse()

	workerScript := *script
	if workerScript == "" {
		exe, err := os.Executable()
		if err != nil {
			log.Fatalf("cannot determine executable path: %v", err)
		}
		workerScript = filepath.Join(filepath.Dir(exe), "julia", "bin", "worker.jl")
	}
	if _, err := os.Stat(workerScript); err != nil {
		log.Fatalf("worker script not found at %s", workerScript)
	}
	// Project dir is the package root (parent of bin/)
	projectDir := filepath.Dir(filepath.Dir(workerScript))

	// Build the julia command line.
	args := []string{*julia}
	if *sysimage != "" {
		args = append(args, "-J", *sysimage)
	}
	args = append(args, "--project="+projectDir, workerScript)

	log.Printf("julia command: %v", args)

	pool, err := NewPool(*poolSize, args, *maxUses, time.Duration(*timeout)*time.Second)
	if err != nil {
		log.Fatalf("pool init: %v", err)
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/api/run", runHandler(pool))
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "ok")
	})

	log.Printf("julia.kitchen runner on %s", *addr)
	if err := http.ListenAndServe(*addr, mux); err != nil {
		log.Fatalf("server: %v", err)
	}
}
