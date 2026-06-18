package main

import (
	"encoding/json"
	"log"
	"net"
	"net/http"
	"strings"
	"sync"
	"time"

	"golang.org/x/time/rate"
)

const maxCodeBytes = 64 * 1024

type runRequest struct {
	Code string `json:"code"`
}

type runResponse struct {
	Stdout    string  `json:"stdout"`
	Stderr    string  `json:"stderr"`
	ElapsedMs float64 `json:"elapsed_ms"`
}

type errResponse struct {
	Error string `json:"error"`
}

// Per-IP rate limiters. The map grows without bound — fine for a small site;
// add a cleanup sweep if traffic warrants it.
var (
	limiters   = map[string]*rate.Limiter{}
	limitersMu sync.Mutex
)

func limiter(ip string) *rate.Limiter {
	limitersMu.Lock()
	defer limitersMu.Unlock()
	l, ok := limiters[ip]
	if !ok {
		// 5 requests per minute, burst of 3.
		l = rate.NewLimiter(rate.Every(12*time.Second), 3)
		limiters[ip] = l
	}
	return l
}

func clientIP(r *http.Request) string {
	if xff := r.Header.Get("X-Forwarded-For"); xff != "" {
		first := strings.TrimSpace(strings.SplitN(xff, ",", 2)[0])
		if ip, _, err := net.SplitHostPort(first); err == nil {
			return ip
		}
		return first
	}
	host, _, _ := net.SplitHostPort(r.RemoteAddr)
	return host
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

func cors(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next(w, r)
	}
}

func runHandler(pool *Pool) http.HandlerFunc {
	return cors(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			writeJSON(w, http.StatusMethodNotAllowed, errResponse{"method not allowed"})
			return
		}

		ip := clientIP(r)
		if !limiter(ip).Allow() {
			writeJSON(w, http.StatusTooManyRequests, errResponse{"rate limit: max 5 requests/minute"})
			return
		}

		r.Body = http.MaxBytesReader(w, r.Body, maxCodeBytes)
		var req runRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			writeJSON(w, http.StatusBadRequest, errResponse{"invalid request: " + err.Error()})
			return
		}
		if strings.TrimSpace(req.Code) == "" {
			writeJSON(w, http.StatusBadRequest, errResponse{"code must not be empty"})
			return
		}

		id := newID()
		log.Printf("[%s] run from %s (%d bytes)", id[:8], ip, len(req.Code))

		result, err := pool.Run(id, req.Code)
		if err != nil {
			log.Printf("[%s] error: %v", id[:8], err)
			writeJSON(w, http.StatusInternalServerError, errResponse{err.Error()})
			return
		}

		writeJSON(w, http.StatusOK, runResponse{
			Stdout:    result.Stdout,
			Stderr:    result.Stderr,
			ElapsedMs: result.ElapsedMs,
		})
	})
}
