# Dockerfile для TTS-сервера с Silero и Piper (через Python)
FROM python:3.10-slim

# Обновляем ключи и отключаем проверку GPG-подписей (временно)
RUN mkdir -p /etc/apt/keyrings && \
    apt-get update || true && \
    apt-get install -y --allow-unauthenticated \
    gnupg \
    ca-certificates \
    && curl -fsSL https://ftp-master.debian.org/keys/release-12.asc | gpg --dearmor -o /etc/apt/keyrings/debian-archive.gpg

# Устанавливаем системные зависимости
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    ffmpeg \
    libespeak-ng1 \
    libespeak-ng-dev \
    libsndfile1 \
    git \
    curl \
    wget \
    && apt-get clean

# Устанавливаем Python-библиотеки
RUN pip install --no-cache-dir \
    torch==2.1.0+cpu -f https://download.pytorch.org/whl/torch_stable.html \
    soundfile \
    git+https://github.com/snakers4/silero-models

# Установка piper-phonemize и piper-tts из исходников
RUN git clone --branch v1.1.0 https://github.com/rhasspy/piper-phonemize.git && \
    cd piper-phonemize && \
    pip install .

RUN git clone --branch v1.2.0 https://github.com/rhasspy/piper-tts.git && \
    cd piper-tts && \
    pip install .

# Создаём рабочую директорию
WORKDIR /app

# Копируем файлы проекта
COPY . .

# Сборка Go-приложения
RUN go build -o server main.go

# Устанавливаем точку входа
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
