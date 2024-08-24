package main

import (
	"fmt"
	"net/http"
)

func helloService(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hello World! Go running on Raspberry!")
}

func main() {
	http.HandleFunc("/", helloService)
	fmt.Println("Server starting on port 8080...")
	http.ListenAndServe(":8080", nil)
}
