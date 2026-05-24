package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"runtime"
)

func main() {
	version := os.Getenv("APP_VERSION")
	if version == "" {
		version = "dev"
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{
			"message": "Hello from Go! 🚀",
			"version": version,
			"runtime": runtime.Version(),
		})
	})

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	fmt.Printf("go-hello v%s listening on :8080\n", version)
	http.ListenAndServe(":8080", nil)
}
