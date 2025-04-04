# Dockerfile для TTS-сервера с Silero и Piper (через Python)

FROM ubuntu:22.04

# Отключаем GPG-подписи (если надо)
RUN echo 'Acquire::AllowInsecureRepositories "true";' > /etc/apt/apt.conf.d/99insecure && \
    echo 'APT::Get::AllowUnauthenticated "true";' >> /etc/apt/apt.conf.d/99insecure

# Установка системных зависимостей
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    build-essential \
    cmake \
    ffmpeg \
    libsndfile1 \
    python3-dev \
    pybind11-dev \
    git \
    curl \
    wget \
    ca-certificates \
    libtool \
    autoconf \
    automake \
    pkg-config \
    && apt-get clean

# Сборка и установка свежего espeak-ng
RUN git clone https://github.com/espeak-ng/espeak-ng.git && \
    cd espeak-ng && \
    ./autogen.sh && \
    ./configure --prefix=/usr && \
    make -j$(nproc) && \
    make install

# Установка ONNX Runtime SDK вручную
RUN curl -L -o onnxruntime.tgz https://github.com/microsoft/onnxruntime/releases/download/v1.16.3/onnxruntime-linux-x64-1.16.3.tgz && \
    tar -xzf onnxruntime.tgz && \
    mv onnxruntime-linux-x64-1.16.3 /opt/onnxruntime && \
    rm onnxruntime.tgz

# Установка переменных окружения для сборки
ENV ONNXRUNTIME_DIR=/opt/onnxruntime
ENV CPLUS_INCLUDE_PATH=$ONNXRUNTIME_DIR/include
ENV LIBRARY_PATH=$ONNXRUNTIME_DIR/lib
ENV LD_LIBRARY_PATH=$ONNXRUNTIME_DIR/lib

# Установка Python-библиотек
RUN pip3 install --no-cache-dir \
    torch==2.1.0+cpu -f https://download.pytorch.org/whl/torch_stable.html \
    soundfile \
    git+https://github.com/snakers4/silero-models

# Установка piper (tts и phonemize из общего репозитория)
RUN git clone https://github.com/rhasspy/piper.git && \
    cd piper/src/python && \
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
