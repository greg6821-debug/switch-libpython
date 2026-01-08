#!/usr/bin/env bash
set -e

docker run -d \
  --name switchdev \
  --workdir /build/git \
  -v "${PWD}:/build/git" \
  devkitpro/devkita64:20210514 \
  tail -f /dev/null

# devkitPro helpers
curl -LOC - \
  https://github.com/uyjulian/pacman-packages/releases/download/v2.2.3-1-pkgbuild-helpers/devkitpro-pkgbuild-helpers-2.2.3-1-any.pkg.tar.xz

docker exec switchdev dkp-pacman -U --noconfirm \
  devkitpro-pkgbuild-helpers-2.2.3-1-any.pkg.tar.xz

# System deps
docker exec switchdev apt-get update

docker exec switchdev apt-get install -y \
  software-properties-common \
  libc6-dev \
  curl \
  ca-certificates

# Python 3.9 (REQUIRED for building CPython 3.9)
docker exec switchdev apt-get install -y \
  python3.9 \
  python3.9-dev \
  python3.9-distutils

# sanity check (очень рекомендую)
docker exec switchdev python3.9 --version
