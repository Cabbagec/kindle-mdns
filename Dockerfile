# syntax=docker/dockerfile:1.4
FROM rust:slim-bullseye as builder

ARG TARGET=armv7-unknown-linux-musleabihf
ENV TARGET=${TARGET}

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    libssl-dev \
    musl-tools \
    gcc-arm-linux-gnueabihf \
    libc6-dev-armhf-cross \
    && rm -rf /var/lib/apt/lists/*

# Install Rust target
RUN rustup target add ${TARGET}

# Create a new empty project
WORKDIR /app
RUN cargo init --bin

# Copy over manifests
COPY Cargo.toml Cargo.lock* ./

# Cache dependencies
RUN mkdir -p src && \
    echo "fn main() {println!(\"if you see this, the build broke\")}" > src/main.rs && \
    cargo build --release --target ${TARGET} && \
    rm -f target/${TARGET}/release/deps/arm_mdns*

# Copy source code
COPY src ./src

# Build the application
RUN cargo build --release --target ${TARGET}

# Create the output directory structure
RUN mkdir -p /output/extensions/arm-mdns/bin

# Copy the binary and scripts
RUN cp target/${TARGET}/release/arm-mdns /output/extensions/arm-mdns/bin/

# Copy extension scripts
COPY extensions/arm-mdns/bin/arm-mdns-control.sh \
     extensions/arm-mdns/bin/init.d-script \
     extensions/arm-mdns/bin/arm-mdns-watchdog.sh \
     extensions/arm-mdns/bin/arm-mdns.service \
     /output/extensions/arm-mdns/bin/

# Set executable permissions
RUN chmod +x /output/extensions/arm-mdns/bin/arm-mdns-control.sh \
    /output/extensions/arm-mdns/bin/init.d-script \
    /output/extensions/arm-mdns/bin/arm-mdns-watchdog.sh

# Final stage - this is just for the output
FROM scratch
COPY --from=builder /output /