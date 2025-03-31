package main

import (
	"bytes"
	"io"
	"log"
	"net/http"
	"os"
	"os/exec"
	"strings"
)

func speakHandler(w http.ResponseWriter, r *http.Request) {
	text := r.URL.Query().Get("text")
	voice := r.URL.Query().Get("voice")

	if text == "" {
		http.Error(w, "Missing 'text' param", http.StatusBadRequest)
		return
	}

	args := []string{"synthesize.py"}
	if voice != "" {
		args = append(args, "--voice", voice)
	}
	args = append(args, strings.Fields(text)...)

	cmd := exec.Command("python3", args...)
	err := cmd.Run()
	if err != nil {
		log.Println("Python error:", err)
		http.Error(w, "Failed to synthesize", http.StatusInternalServerError)
		return
	}

	f, err := os.Open("output.wav")
	if err != nil {
		http.Error(w, "Cannot open output", http.StatusInternalServerError)
		return
	}
	defer f.Close()

	w.Header().Set("Content-Type", "audio/wav")
	io.Copy(w, f)
}

func voicesHandler(w http.ResponseWriter, r *http.Request) {
	cmd := exec.Command("python3", "synthesize.py", "--list")
	var out bytes.Buffer
	cmd.Stdout = &out
	err := cmd.Run()
	if err != nil {
		log.Println("Python error:", err)
		http.Error(w, "Failed to get voices", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	voices := strings.Split(strings.TrimSpace(out.String()), "\n")
	w.Write([]byte(`["` + strings.Join(voices, `","`) + `"]`))
}

func main() {
	http.HandleFunc("/speak", speakHandler)
	http.HandleFunc("/voices", voicesHandler)
	log.Println("Listening on :8080")
	http.ListenAndServe(":8080", nil)
}
