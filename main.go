// Chmouel Test
package main

import (
	"io"
	"log"
	"net/http"
	"os"
)

func main() {
	var blahBlah
	http.HandleFunc("/", ExampleHandler)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Println("** Service Started on Port " + port + " **")
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal(err)
	}
}

func ExampleHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Add("Content-Type", "application/json")
	_, err := io.WriteString(w, `{"status":"ok"}`)
	if err != nil {
		log.Fatal(err)
	}
}
