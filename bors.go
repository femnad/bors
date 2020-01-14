package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"

	"github.com/alexflint/go-arg"
)

var args struct {
	Port int    `arg:"env" default:"8080"`
	File string `arg:"required,-f"`
}

func panicOnErr(err error) {
	if err != nil {
		panic(err)
	}
}

func main() {
	arg.MustParse(&args)

	file, err := os.Open(args.File)
	panicOnErr(err)

	log.Printf("Serving %s on port %d", args.File, args.Port)

	serve := func(w http.ResponseWriter, r *http.Request) {
		_, err := io.Copy(w, file)
		if err != nil {
			log.Printf("error writing response body: %s", err)
		}
	}
	http.HandleFunc("/", serve)

	addr := fmt.Sprintf(":%d", args.Port)
	err = http.ListenAndServe(addr, nil)
	panicOnErr(err)

	log.Println("Stopped serving")
}
