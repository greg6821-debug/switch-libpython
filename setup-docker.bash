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
  build-essential \
  software-properties-common

# Python 3.12 is required to build CPython 3.12: the stdlib now uses
# 3.12-only syntax (PEP 701 f-strings etc.), so the build interpreter
# used by `make libinstall` (which byte-compiles the stdlib) must be
# 3.12 itself.
#
# devkitpro/devkita64:20240827 is Ubuntu-based. python3.12 is the
# default interpreter on Ubuntu 24.04+; on older Ubuntu releases it is
# provided by the deadsnakes PPA.
if ! docker exec switchdev bash -c 'command -v python3.12 >/dev/null 2>&1'; then
  docker exec switchdev add-apt-repository -y ppa:deadsnakes/ppa
  docker exec switchdev apt-get update
  docker exec switchdev apt-get install -y python3.12 python3.12-dev python3.12-venv
else
  docker exec switchdev apt-get install -y python3.12-dev || true
fi

# sanity check
docker exec switchdev python3.12 --version
