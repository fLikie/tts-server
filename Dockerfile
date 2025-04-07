# Dockerfile: TTS-сервер на Go с Piper (через официальный бинарник)

FROM ubuntu:22.04

# Установка зависимостей
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    wget \
    ffmpeg \
    libsndfile1 \
    golang \
    && apt-get clean

# Загрузка и установка Piper-бинарника
RUN mkdir -p /opt/piper && \
    wget https://github.com/rhasspy/piper/releases/download/v1.2.0/piper_linux_x86_64.tar.gz -O /tmp/piper.tar.gz && \
    tar -xzf /tmp/piper.tar.gz -C /opt/piper && \
    chmod +x /opt/piper/piper && \
    rm /tmp/piper.tar.gz

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

