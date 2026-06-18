package main

import (
	"fmt"
	"log"
	"time"
)

type Pool struct {
	available chan *Worker
	args      []string
	maxUses   int
	timeout   time.Duration
}

func NewPool(size int, args []string, maxUses int, timeout time.Duration) (*Pool, error) {
	p := &Pool{
		available: make(chan *Worker, size),
		args:      args,
		maxUses:   maxUses,
		timeout:   timeout,
	}
	for i := range size {
		log.Printf("spawning worker %d/%d…", i+1, size)
		w, err := spawnWorker(args)
		if err != nil {
			return nil, fmt.Errorf("spawn worker %d: %w", i, err)
		}
		p.available <- w
	}
	log.Printf("pool ready (%d workers)", size)
	return p, nil
}

func (p *Pool) Run(id, code string) (*workerResponse, error) {
	select {
	case w := <-p.available:
		resp, err := w.Run(id, code, p.timeout)
		if err != nil || w.uses >= p.maxUses {
			w.Kill()
			go p.replenish()
		} else {
			p.available <- w
		}
		return resp, err
	case <-time.After(30 * time.Second):
		return nil, fmt.Errorf("no workers available, try again later")
	}
}

func (p *Pool) replenish() {
	for attempt := range 3 {
		w, err := spawnWorker(p.args)
		if err == nil {
			p.available <- w
			return
		}
		log.Printf("respawn attempt %d failed: %v", attempt+1, err)
		time.Sleep(time.Duration(attempt+1) * 2 * time.Second)
	}
	log.Fatal("could not respawn a Julia worker after 3 attempts")
}
