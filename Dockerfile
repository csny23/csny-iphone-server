# Base for builder
FROM debian:stable-slim AS builder
# Deps for builder
RUN apt-get update && apt-get install --no-install-recommends -y ca-certificates ldc git clang dub libz-dev libssl-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Build for builder
WORKDIR /opt/
COPY . .
RUN DC=ldc2 dub build -c "static" --build-mode allAtOnce -b release --compiler=ldc2

# Base for run
FROM debian:stable-slim
# --- FIX STARTS HERE ---
# I added 'libplist-dev' and 'libssl-dev' to this list.
# This fixes the "LibraryLoadingException" crash.
RUN apt-get update && apt-get install --no-install-recommends -y \
    ca-certificates \
    curl \
    libplist-dev \
    libssl-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*
# --- FIX ENDS HERE ---

# Copy build artefacts to run
WORKDIR /opt/
COPY --from=builder /opt/anisette-v3-server /opt/anisette-v3-server

# Setup rootless user which works with the volume mount
RUN useradd -ms /bin/bash Alcoholic \
 && mkdir /home/Alcoholic/.config/anisette-v3/lib/ -p \
 && chown -R Alcoholic /home/Alcoholic/ \
 && chmod -R +wx /home/Alcoholic/ \
 && chown -R Alcoholic /opt/ \
 && chmod -R +wx /opt/

# Run the artefact
USER Alcoholic
EXPOSE 6969
ENTRYPOINT [ "/opt/anisette-v3-server" ]
