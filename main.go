// main.go
package main

import (
	"bytes"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/exec"
	"time"
)

func main() {
	http.HandleFunc("/speak", handleSpeak)
	log.Println("Listening on :8080")
	http.ListenAndServe(":8080", nil)
}

func handleSpeak(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Only POST allowed", http.StatusMethodNotAllowed)
		return
	}

	text, err := io.ReadAll(r.Body)
	if err != nil || len(text) == 0 {
		http.Error(w, "Empty body", http.StatusBadRequest)
		return
	}

	tempWav := fmt.Sprintf("/tmp/tts_%d.wav", time.Now().UnixNano())
	tempMp3 := fmt.Sprintf("/tmp/tts_%d.mp3", time.Now().UnixNano())
	defer os.Remove(tempWav)
	defer os.Remove(tempMp3)

	cmd := exec.Command("/opt/piper/piper",
		"--model", os.Getenv("PIPER_MODEL"),
		"--output_file", tempWav,
	)
	cmd.Stdin = bytes.NewReader(text)

	out, err := cmd.CombinedOutput()
	if err != nil {
		log.Printf("Piper error: %v\n%s", err, out)
		http.Error(w, "Piper failed", 500)
		return
	}

	// Конвертация в mp3 через ffmpeg
	cmd = exec.Command("ffmpeg", "-y", "-i", tempWav, "-codec:a", "libmp3lame", tempMp3)
	out, err = cmd.CombinedOutput()
	if err != nil {
		log.Printf("FFmpeg error: %v\n%s", err, out)
		http.Error(w, "FFmpeg failed", 500)
		return
	}

	audio, err := os.ReadFile(tempMp3)
	if err != nil {
		http.Error(w, "Failed to read mp3", 500)
		return
	}

	w.Header().Set("Content-Type", "audio/mpeg")
	w.Write(audio)
}
