# synthesize.py
import sys
import torch
import soundfile as sf

device = torch.device("cpu")

result = torch.hub.load(
    repo_or_dir='snakers4/silero-models',
    model='silero_tts',
    language='ru',
    speaker='v3_1_ru',
    device=device
)

# Распаковка: если кортеж — берём первый элемент
if isinstance(result, tuple):
    model = result[0]
else:
    model = result

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
