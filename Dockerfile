FROM python:3.10-slim

# Установка зависимостей
RUN apt-get update && apt-get install -y golang git && \
    pip install torch soundfile git+https://github.com/snakers4/silero-models \

RUN apt-get update && apt-get install -y ffmpeg

# Копируем файлы
WORKDIR /app
COPY . .

# Собираем Go-приложение
RUN go build -o server main.go

# Скрипт для запуска с git pull
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
