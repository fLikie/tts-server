FROM python:3.10-slim

# Устанавливаем зависимости
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libespeak-ng1 \
    git \
    curl \
    wget \
    && apt-get clean

# Устанавливаем Python-зависимости
# Устанавливаем Python-библиотеки
RUN pip install --no-cache-dir \
    torch \
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
