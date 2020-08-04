// Chmouel Test
package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
)

func main() {
	http.HandleFunc("/", ExampleHandler)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Println("** Service Started on Port " + port + " **")
	http.ListenAndServe(":"+port, nil)
}

func ExampleHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("%s has percent s")
	w.Header().Add("Content-Type", "application/json")
	_, err := io.WriteString(w, `{"status":"ok"}`)
	if err != nil {
		log.Fatal(err)
	}
}
