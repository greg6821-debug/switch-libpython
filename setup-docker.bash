#!/usr/bin/env bash
set -e

docker run -d \
  --name switchdev \
  --workdir /build/git \
  -v "${PWD}:/build/git" \
  devkitpro/devkita64:20240409 \
  tail -f /dev/null

# devkitPro helpers
curl -LOC - \
  https://github.com/uyjulian/pacman-packages/releases/download/v2.2.3-1-pkgbuild-helpers/devkitpro-pkgbuild-helpers-2.2.3-1-any.pkg.tar.xz

docker exec switchdev dkp-pacman -U --noconfirm \
  devkitpro-pkgbuild-helpers-2.2.3-1-any.pkg.tar.xz

# ---- FIX DEBIAN BUSTER EOL ----
docker exec switchdev bash -c '
  sed -i "s|deb.debian.org|archive.debian.org|g" /etc/apt/sources.list &&
  sed -i "s|security.debian.org|archive.debian.org|g" /etc/apt/sources.list &&
  echo "Acquire::Check-Valid-Until false;" > /etc/apt/apt.conf.d/99no-check-valid-until
'

# update after fixing repos
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
