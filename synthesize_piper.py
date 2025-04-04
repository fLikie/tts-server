from piper_tts import PiperVoice
import sys

text = " ".join(arg for arg in sys.argv[1:] if not arg.startswith("--"))

# Загрузка модели (скачает автоматически при первом запуске)
voice = PiperVoice.load(voice="ru-irina-medium")

# Генерация и сохранение
audio = voice.synthesize(text)
voice.save_wav(audio, "output.wav")