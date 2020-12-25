package main

import (
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"path"
	"strconv"
	"strings"

	"github.com/alexflint/go-arg"
	"gopkg.in/yaml.v3"
)

var args struct {
	Port       int    `arg:"-p" default:"8080" help:"port to serve on"`
	RoutesFile string `arg:"-f" default:"~/.config/bors/routes.yml" help:"routes file"`
	DataDir    string `arg:"-d" default:"~/.local/share/bors" help:"directory to look for static files"`
}

type routeMapping struct {
	Route string
	File  string
}

type routeMappingSpec struct {
	Routes []routeMapping
}

func expandUser(path string) (string, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", err
	}
	return strings.Replace(path, "~", homeDir, 1), nil
}

func getHandler(file string) func(w http.ResponseWriter, r *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {
		fileBytes, err := ioutil.ReadFile(file)
		if err != nil {
			log.Printf("Error reading file contents: %s", err)
			w.WriteHeader(http.StatusInternalServerError)
			return
		}
		contentLength := strconv.Itoa(len(fileBytes))
		w.Header().Add("content-length", contentLength)
		numBytes, err := w.Write(fileBytes)
		if err != nil {
			log.Printf("error writing response body: %s", err)
			w.WriteHeader(http.StatusInternalServerError)
			return
		}
		log.Printf("Wrote %d bytes", numBytes)
	}
}

func closeAndHandleError(closer io.Closer) {
	err := closer.Close()
	if err != nil {
		log.Fatalf("Error closing file: %v", err)
	}
}

func main() {
	arg.MustParse(&args)

	routesFile := args.RoutesFile
	routesFile, err := expandUser(routesFile)

	if err != nil {
		log.Fatalf("Error expanding routes file %s, %v", routesFile, err)
	}

	f, err := os.Open(routesFile)
	if err != nil {
		log.Fatalf("Error opening route spec file %s: %v", routesFile, err)
	}
	defer closeAndHandleError(f)

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

	dataDir, err := expandUser(args.DataDir)
	if err != nil {
		log.Fatalf("Error expanding data dir %s: %v", args.DataDir, err)
	}

	for _, route := range spec.Routes {
		routeFile := path.Join(dataDir, route.File)
		routeFn := getHandler(routeFile)
		http.HandleFunc(route.Route, routeFn)
	}

	addr := fmt.Sprintf(":%d", args.Port)
	err = http.ListenAndServe(addr, nil)
	if err != nil {
		log.Fatalf("Error serving HTTP: %v", err)
	}

	log.Println("Stopped serving")
}
