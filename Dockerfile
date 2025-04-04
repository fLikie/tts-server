FROM python:3.10-slim

RUN apt-get update || true && apt-get install -y --allow-unauthenticated \
    gnupg ca-certificates

RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://ftp-master.debian.org/keys/release-12.asc | gpg --dearmor -o /etc/apt/keyrings/debian-archive.gpg

# Устанавливаем зависимости
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
# Устанавливаем Python-зависимости
# Устанавливаем Python-библиотеки
RUN pip install torch==2.1.0+cpu -f https://download.pytorch.org/whl/torch_stable.html \
    soundfile \
    git+https://github.com/snakers4/silero-models

# Установка Piper из GitHub вручную
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
