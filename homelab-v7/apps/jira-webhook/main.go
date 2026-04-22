package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
)

type jiraIssue struct {
	Key    string `json:"key"`
	Fields struct {
		Summary     string `json:"summary"`
		Description string `json:"description"`
	} `json:"fields"`
}

type jiraPayload struct {
	Issue jiraIssue `json:"issue"`
}

type coderTaskRequest struct {
	Input string `json:"input"`
}

func main() {
	coderURL := mustEnv("CODER_URL")
	coderToken := mustEnv("CODER_TOKEN")

	http.HandleFunc("/webhook", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}

		body, err := io.ReadAll(r.Body)
		if err != nil {
			http.Error(w, "failed to read body", http.StatusBadRequest)
			return
		}

		var payload jiraPayload
		if err := json.Unmarshal(body, &payload); err != nil {
			http.Error(w, "invalid json", http.StatusBadRequest)
			return
		}

		issue := payload.Issue
		if issue.Key == "" {
			http.Error(w, "missing issue key", http.StatusBadRequest)
			return
		}

		parts := []string{
			fmt.Sprintf("%s: %s", issue.Key, issue.Fields.Summary),
		}
		if issue.Fields.Description != "" {
			parts = append(parts, "", issue.Fields.Description)
		}
		input := strings.Join(parts, "\n")

		if err := createCoderTask(coderURL, coderToken, input); err != nil {
			log.Printf("error creating coder task: %v", err)
			http.Error(w, "failed to create task", http.StatusInternalServerError)
			return
		}

		log.Printf("task created for issue %s", issue.Key)
		w.WriteHeader(http.StatusOK)
		fmt.Fprintf(w, `{"status":"ok","issue":"%s"}`, issue.Key)
	})

	http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	log.Println("jira-webhook-receiver listening on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}

func createCoderTask(coderURL, token, input string) error {
	payload, _ := json.Marshal(coderTaskRequest{Input: input})
	req, err := http.NewRequest(http.MethodPost, coderURL+"/api/tasks", bytes.NewReader(payload))
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", "application/json")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 300 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("coder api returned %d: %s", resp.StatusCode, body)
	}
	return nil
}

func mustEnv(key string) string {
	v := os.Getenv(key)
	if v == "" {
		log.Fatalf("required env var %s is not set", key)
	}
	return v
}
