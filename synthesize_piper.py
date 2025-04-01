import sys
import subprocess

text = " ".join(arg for arg in sys.argv[1:] if not arg.startswith("--"))

cmd = [
    "./piper/piper",
    "--model", "piper/models/ru/irina-medium.onnx",
    "--config", "piper/models/ru/irina-medium.onnx.json",
    "--output_file", "output.wav",
    "--sentence_silence", "0.5"
]

process = subprocess.Popen(cmd, stdin=subprocess.PIPE)
process.communicate(input=text.encode("utf-8"))