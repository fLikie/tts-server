# synthesize.py
import sys
import torch
import soundfile as sf
from silero import models

device = torch.device("cpu")
model, _ = models.get_tts_model(
    model_name='v3_1_ru',
    device=device
)

if "--list" in sys.argv:
    print("\n".join(model.speakers))
    exit(0)

text = ""
voice = None

for i, arg in enumerate(sys.argv):
    if arg == "--voice" and i + 1 < len(sys.argv):
        voice = sys.argv[i + 1]
    elif not arg.startswith("--"):
        text += arg + " "

audio = model.apply_tts(text=text.strip(), speaker=voice)
sf.write("output.wav", audio, 48000)
