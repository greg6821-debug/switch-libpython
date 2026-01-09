#!/usr/bin/env bash
set -e

docker run -d \
  --name switchdev \
  --workdir /build/git \
  -v "${PWD}:/build/git" \
  devkitpro/devkita64:20240827 \
  tail -f /dev/null

# update 
docker exec switchdev apt-get update

# base deps
docker exec switchdev apt-get install -y \
  libc6-dev \
  curl \
  ca-certificates \
  xz-utils \
  build-essential

# Python for building CPython 3.9
docker exec switchdev apt-get install -y \
  python3.9 \
  python3.9-dev \
  python3.9-distutils

# sanity check
docker exec switchdev python3.9 --version
