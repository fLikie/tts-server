package main

import (
	"bytes"
	"encoding/json"
	"io"
	"log"
	"net/http"
	"os"
	"os/exec"
	"strings"
)

type RequestBody struct {
	Text   string `json:"text"`
	Voice  string `json:"voice,omitempty"`
	Engine string `json:"engine,omitempty"` // silero (default) or piper
}

func speakHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Only POST allowed", http.StatusMethodNotAllowed)
		return
	}

	var req RequestBody
	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil || req.Text == "" {
		http.Error(w, "Invalid JSON or missing 'text'", http.StatusBadRequest)
		return
	}

	script := "synthesize.py"
	if req.Engine == "piper" {
		script = "synthesize_piper.py"
	}

	args := []string{script}
	if req.Voice != "" && req.Engine != "piper" {
		args = append(args, "--voice", req.Voice)
	}
	args = append(args, strings.Fields(req.Text)...)

	cmd := exec.Command("python3", args...)

	out, err := cmd.CombinedOutput()
	if err != nil {
		log.Println("Python error:", err)
		log.Println("Python output:", string(out)) // <--- вот это важно
		http.Error(w, "Failed to synthesize", http.StatusInternalServerError)
		return
	}

	// Конвертация .wav → .mp3
	err = exec.Command("ffmpeg", "-y", "-i", "output.wav", "output.mp3").Run()
	if err != nil {
		log.Println("FFmpeg error:", err)
		http.Error(w, "Failed to convert to mp3", http.StatusInternalServerError)
		return
	}

	f, err := os.Open("output.mp3")
	if err != nil {
		http.Error(w, "Cannot open mp3 output", http.StatusInternalServerError)
		return
	}
	defer f.Close()

	w.Header().Set("Content-Type", "audio/mpeg")
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
