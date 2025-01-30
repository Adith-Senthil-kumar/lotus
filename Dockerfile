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

    # Create non-root user
    RUN useradd -ms /bin/bash flutter

# Install Flutter SDK
RUN wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.19.0-stable.tar.xz
RUN tar xf flutter_linux_3.19.0-stable.tar.xz
RUN mv flutter /opt/flutter
RUN chown -R flutter:flutter /opt/flutter

# Set Flutter environment variables
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Configure git safe directory for Flutter
RUN git config --global --add safe.directory /opt/flutter

# Switch to non-root user
USER flutter

# Run Flutter doctor to verify installation
RUN flutter doctor

# Set the working directory
WORKDIR /app
USER root
RUN chown flutter:flutter /app
USER flutter

# Copy the Flutter project into the container
COPY . /app

# Install Flutter dependencies
RUN flutter pub get

# Build the Windows EXE using Wine
CMD flutter build windows --release
