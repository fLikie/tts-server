# Dockerfile для TTS-сервера с Silero и Piper (через Python)
FROM ubuntu:22.04

RUN echo 'Acquire::AllowInsecureRepositories "true";' > /etc/apt/apt.conf.d/99insecure && \
    echo 'Acquire::AllowDowngradeToInsecureRepositories "true";' >> /etc/apt/apt.conf.d/99insecure && \
    echo 'APT::Get::AllowUnauthenticated "true";' >> /etc/apt/apt.conf.d/99insecure

# Установка системных зависимостей и Python
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    libonnxruntime-dev \
    build-essential \
    cmake \
    ffmpeg \
    libespeak-ng1 \
    libespeak-ng-dev \
    libsndfile1 \
    git \
    curl \
    wget \
    ca-certificates \
    && apt-get clean

# Устанавливаем Python-библиотеки
RUN pip3 install --no-cache-dir \
    torch==2.1.0+cpu -f https://download.pytorch.org/whl/torch_stable.html \
    soundfile \
    git+https://github.com/snakers4/silero-models

# Установка piper-phonemize и piper-tts из исходников
RUN git clone --branch v1.1.0 https://github.com/rhasspy/piper-phonemize.git && \
    cd piper-phonemize && \
    pip3 install .

RUN git clone --branch v1.2.0 https://github.com/rhasspy/piper-tts.git && \
    cd piper-tts && \
    pip3 install .

# Создаём рабочую директорию
WORKDIR /app

# Копируем файлы проекта
COPY . .

# Сборка Go-приложения
RUN apt-get install -y golang && \
    go build -o server main.go

# Устанавливаем точку входа
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
