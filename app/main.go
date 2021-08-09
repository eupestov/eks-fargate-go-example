package main

import (
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/eupestov/devops_challenge/app/replacer"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var r = replacer.New(map[string]string{
	"abn":       "ABN AMRO",
	"ing":       "ING Bank",
	"rabo":      "Rabobank",
	"triodos":   "Triodos Bank",
	"volksbank": "de Volksbank",
})

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}

func handleReplace(w http.ResponseWriter, req *http.Request) {
	text := req.URL.Query().Get("text")
	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	r.ReplaceAndWrite(w, text)
}

func main() {

	http.HandleFunc("/api/v1/replace", handleReplace)
	http.Handle("/metrics", promhttp.Handler())
	http.HandleFunc("/health", func(w http.ResponseWriter, req *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	log.Fatal(http.ListenAndServe(fmt.Sprintf(":%s", getEnv("LISTEN_PORT", "8080")), nil))
}
