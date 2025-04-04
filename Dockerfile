FROM python:3.10-slim

# Установка зависимостей
RUN apt-get update && apt-get install -y \
  build-essential cmake git curl wget ffmpeg \
  python3 python3-pip libespeak-ng1 golang \
  && apt-get clean

# Устанавливаем Python-библиотеки
RUN pip3 install --no-cache-dir \
  torch \
  soundfile \
  git+https://github.com/snakers4/silero-models

# Сборка Piper
WORKDIR /app
RUN git clone https://github.com/rhasspy/piper.git && \
    cd piper && make

# Скачиваем модель ru_irina
RUN mkdir -p piper/models/ru && cd piper/models/ru && \
    wget https://huggingface.co/rhasspy/piper-voices/blob/main/ru/ru_RU/irina/medium/ru_RU-irina-medium.onnx && \
    wget https://huggingface.co/rhasspy/piper-voices/blob/main/ru/ru_RU/irina/medium/ru_RU-irina-medium.onnx.json

WORKDIR /app
COPY . .

RUN go build -o server main.go

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
