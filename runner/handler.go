package main

import (
	"encoding/json"
	"fmt"
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
	ImageData string  `json:"image_data,omitempty"`
}

type errResponse struct {
	Error string `json:"error"`
}

// idleEvict is how long an IP's limiter is kept after its last request before
// the sweeper reclaims it, bounding the map under high unique-IP traffic.
const idleEvict = 10 * time.Minute

type ipLimiter struct {
	*rate.Limiter
	lastSeen time.Time
}

// Per-IP rate limiters, reclaimed by sweepLimiters after idleEvict of silence.
var (
	limiters   = map[string]*ipLimiter{}
	limitersMu sync.Mutex

	// Configured by configureRateLimit. Defaults match production: 5 req/min,
	// burst 3. Set perMinute to 0 (via the -rate flag) to disable limiting,
	// e.g. for local development.
	ratePerMinute = 5
	rateBurst     = 3
)

// configureRateLimit sets the per-IP request rate. perMinute <= 0 disables
// rate limiting entirely. Call before serving.
func configureRateLimit(perMinute, burst int) {
	ratePerMinute = perMinute
	rateBurst = burst
	if perMinute > 0 {
		go sweepLimiters()
	}
}

// sweepLimiters periodically drops limiters for IPs idle longer than idleEvict,
// so the map can't grow without bound (e.g. under spoofed/rotating source IPs).
func sweepLimiters() {
	for range time.Tick(idleEvict) {
		limitersMu.Lock()
		for ip, l := range limiters {
			if time.Since(l.lastSeen) > idleEvict {
				delete(limiters, ip)
			}
		}
		limitersMu.Unlock()
	}
}

// limiter returns the per-IP limiter, or nil if rate limiting is disabled.
func limiter(ip string) *rate.Limiter {
	if ratePerMinute <= 0 {
		return nil
	}
	limitersMu.Lock()
	defer limitersMu.Unlock()
	l, ok := limiters[ip]
	if !ok {
		l = &ipLimiter{Limiter: rate.NewLimiter(rate.Every(time.Minute/time.Duration(ratePerMinute)), rateBurst)}
		limiters[ip] = l
	}
	l.lastSeen = time.Now()
	return l.Limiter
}

// clientIP returns the requester's IP for rate limiting. The runner only ever
// receives traffic from the trusted edge proxy (Caddy), which APPENDS the real
// client to X-Forwarded-For — so the last entry is the one Caddy saw and the
// only one a client can't spoof. Reading the first (leftmost) entry instead
// would let anyone bypass the per-IP limit by sending a random X-Forwarded-For
// on every request. ponytail: single trusted proxy assumed; if you add more
// hops, count from the right by the number of trusted proxies.
func clientIP(r *http.Request) string {
	if xff := r.Header.Get("X-Forwarded-For"); xff != "" {
		parts := strings.Split(xff, ",")
		last := strings.TrimSpace(parts[len(parts)-1])
		if ip, _, err := net.SplitHostPort(last); err == nil {
			return ip
		}
		return last
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
		if l := limiter(ip); l != nil && !l.Allow() {
			writeJSON(w, http.StatusTooManyRequests, errResponse{fmt.Sprintf("rate limit: max %d requests/minute", ratePerMinute)})
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
			ImageData: result.ImageData,
		})
	})
}
