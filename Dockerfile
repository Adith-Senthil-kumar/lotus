# Use an Ubuntu base image
FROM ubuntu:20.04

# Set non-interactive installation to avoid prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies for Flutter and Wine
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    unzip \
    xz-utils \
    git \
    libglu1-mesa \
    wine64 \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter SDK
RUN wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.19.0-stable.tar.xz
RUN tar xf flutter_linux_3.19.0-stable.tar.xz
RUN mv flutter /opt/flutter

# Set Flutter environment variables
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Run Flutter doctor to verify installation
RUN flutter doctor

# Set the working directory
WORKDIR /app

# Copy the Flutter project into the container
COPY . /app

# Install Flutter dependencies
RUN flutter pub get

# Build the Windows EXE using Wine
CMD wine flutter build windows --release
