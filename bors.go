package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"

	"github.com/alexflint/go-arg"
	"gopkg.in/yaml.v3"
)

var args struct {
	Port int    `arg:"env" default:"8080" help:"port to serve on"`
	File string `arg:"required,-f" help:"routes file"`
}

type routeMapping struct {
	Route string
	File string
}

type routeMappingSpec struct {
	Routes []routeMapping
}

func getHandler(file string) func(w http.ResponseWriter, r *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {
		fileBytes, err := ioutil.ReadFile(file)
		if err != nil {
			log.Printf("error reading file contents: %s", err)
			w.WriteHeader(500)
		}
		numBytes, err := w.Write(fileBytes)
		if err != nil {
			log.Printf("error writing response body: %s", err)
			w.WriteHeader(500)
		}
		log.Printf("Wrote %d bytes", numBytes)
	}
}

func main() {
	arg.MustParse(&args)

	routesFile := args.File

	f, err := os.Open(routesFile)
	if err != nil {
		log.Fatalf("Error opening route spec file %s: %v", routesFile, err)
	}
	defer f.Close()

	routeSpecContent, err := ioutil.ReadAll(f)
	if err != nil {
		log.Fatalf("Error reading routes file %s: %v", routesFile, err)
	}

	var spec routeMappingSpec

	err = yaml.Unmarshal(routeSpecContent, &spec)
	if err != nil {
		log.Fatalf("Error deserializing routes file %s: %v", routesFile, err)
	}

	log.Printf("Serving routes from %s on port %d", routesFile, args.Port)

	for _, route := range spec.Routes {
		routeFn := getHandler(route.File)
		http.HandleFunc(route.Route, routeFn)
	}

	addr := fmt.Sprintf(":%d", args.Port)
	err = http.ListenAndServe(addr, nil)
	if err != nil {
		log.Fatalf("Error serving HTTP: %v", err)
	}

	log.Println("Stopped serving")
}
