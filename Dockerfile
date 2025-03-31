FROM python:3.10-slim

# Установим ffmpeg + golang + git
RUN apt-get update && apt-get install -y \
    ffmpeg \
    golang \
    git && \
    pip install torch soundfile git+https://github.com/snakers4/silero-models

# Копируем проект
WORKDIR /app
COPY . .

# Собираем Go-приложение
RUN go build -o server main.go

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
