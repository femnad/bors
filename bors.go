package main

import (
	"fmt"
	"github.com/alexflint/go-arg"
	"io/ioutil"
	"log"
	"net/http"
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
	log.Printf("Serving %s on port %d", args.File, args.Port)

	serve := func(w http.ResponseWriter, r *http.Request) {
		fileBytes, err := ioutil.ReadFile(args.File)
		if err != nil {
			log.Printf("error reading file contents: %s", err)
		}
		numBytes, err := w.Write(fileBytes)
		if err != nil {
			log.Printf("error writing response body: %s", err)
		}
		log.Printf("Wrote %d bytes", numBytes)
	}
	http.HandleFunc("/", serve)

	addr := fmt.Sprintf(":%d", args.Port)
	err := http.ListenAndServe(addr, nil)
	panicOnErr(err)

	log.Println("Stopped serving")
}
