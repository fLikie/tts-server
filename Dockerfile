# Dockerfile: Чистый TTS-сервер на Go с Piper CLI (без Python)

FROM ubuntu:22.04

# Установка зависимостей
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    curl \
    wget \
    ffmpeg \
    libsndfile1 \
    golang \
    && apt-get clean

# Сборка Piper
RUN git clone https://github.com/rhasspy/piper.git /opt/piper
WORKDIR /opt/piper
RUN make && ls -la /opt/piper && file /opt/piper/piper || echo "❌ piper не собрался"

# Скачивание русской модели
RUN mkdir -p /opt/piper/models/ru && \
    wget https://huggingface.co/rhasspy/piper-voices/blob/main/ru/ru_RU/irina/medium/ru_RU-irina-medium.onnx -O /opt/piper/models/ru/irina.onnx && \
    wget https://huggingface.co/rhasspy/piper-voices/blob/main/ru/ru_RU/irina/medium/ru_RU-irina-medium.onnx.json -O /opt/piper/models/ru/irina.onnx.json

# Создание рабочей директории и копирование проекта
WORKDIR /app
COPY . .

# Сборка Go-сервера
RUN go build -o server main.go

# Копируем точку входа
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV PIPER_BIN=/opt/piper/piper
ENV PIPER_MODEL=/opt/piper/models/ru/irina.onnx

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
