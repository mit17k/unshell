package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"time"
)

type Health struct {
	Status  string        `json:"status"`
	Uptime  time.Duration `json:"uptime"`
	Version string        `json:"version"`
}

var started = time.Now()

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(Health{"ok", time.Since(started), "0.1.0"}); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", healthHandler)

	srv := &http.Server{Addr: "127.0.0.1:4317", Handler: mux, ReadTimeout: 5 * time.Second}
	ctx, cancel := context.WithTimeout(context.Background(), time.Minute)
	defer cancel()

	go func() { <-ctx.Done(); _ = srv.Shutdown(context.Background()) }()
	log.Printf("listening on %s", srv.Addr)
	if err := srv.ListenAndServe(); err != http.ErrServerClosed {
		log.Fatal(err)
	}
}
