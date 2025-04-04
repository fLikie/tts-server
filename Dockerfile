FROM python:3.10-slim

# Установка зависимостей
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    python3 \
    python3-pip \
    git \
    ffmpeg \
    libespeak-ng1 \
    golang \
    curl \
    wget \
 && pip3 install torch soundfile git+https://github.com/snakers4/silero-models

# Скачиваем и компилируем Piper
RUN git clone https://github.com/rhasspy/piper.git && \
    cd piper && make

# Скачиваем модель ru_irina
RUN mkdir -p piper/models/ru && cd piper/models/ru && \
    wget https://huggingface.co/rhasspy/piper-voices/tree/main/ru/ru_RU/irina/medium/irina-medium.onnx && \
    wget https://huggingface.co/rhasspy/piper-voices/tree/main/ru/ru_RU/irina/medium/irina-medium.onnx.json

WORKDIR /app
COPY . .

RUN go build -o server main.go

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
