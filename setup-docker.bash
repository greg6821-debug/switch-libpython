#!/usr/bin/env bash
set -e

docker run -d \
  --name switchdev \
  --workdir /build/git \
  -v "${PWD}:/build/git" \
  devkitpro/devkita64:20240827 \
  tail -f /dev/null

# Bullseye is EOL — redirect ALL apt sources to archive.debian.org so the
# security/updates packages are still fetchable (otherwise 404).
# Also remove bullseye-updates (not in archive) and disable ReleaseInfoChange checks.
docker exec switchdev bash -c '
  # Fix main sources.list
  if [ -f /etc/apt/sources.list ]; then
    sed -i "s|deb.debian.org|archive.debian.org|g" /etc/apt/sources.list
    sed -i "s|security.debian.org|archive.debian.org|g" /etc/apt/sources.list
    sed -i "/bullseye-updates/d" /etc/apt/sources.list
    # Remove [signed-by=...] that may break with archive
    sed -i "s|\[signed-by=[^]]*\] ||g" /etc/apt/sources.list
  fi
  # Fix any .list files in sources.list.d
  for f in /etc/apt/sources.list.d/*.list; do
    [ -f "$f" ] || continue
    sed -i "s|deb.debian.org|archive.debian.org|g" "$f"
    sed -i "s|security.debian.org|archive.debian.org|g" "$f"
    sed -i "/bullseye-updates/d" "$f"
  done
'

docker exec switchdev apt-get update -o Acquire::Check-Valid-Until=false
docker exec switchdev apt-get install -y --no-install-recommends \
  libc6-dev curl ca-certificates xz-utils build-essential \
  zlib1g-dev libffi-dev libssl-dev libsqlite3-dev libreadline-dev \
  libbz2-dev libncursesw5-dev tk-dev libgdbm-dev liblzma-dev

# CPython 3.12 cross-compile requires the build python to be 3.12 itself
# ("expected: 3.12"). Bullseye only ships python3.9, so build python3.12
# from source (minimal — just enough to drive the cross-build).
echo "=== building python3.12 from source (this takes ~5 min) ==="
docker exec switchdev bash -c '
  set -e
  cd /tmp
  curl -sL -o py.tar.xz https://www.python.org/ftp/python/3.12.16/Python-3.12.16.tar.xz
  tar -xf py.tar.xz
  cd Python-3.12.16
  ./configure --prefix=/usr/local --without-ensurepip --disable-test-modules > /tmp/pycfg.log 2>&1
  make -j"$(nproc)" > /tmp/pymake.log 2>&1
  make altinstall > /tmp/pyinstall.log 2>&1
  ln -sf /usr/local/bin/python3.12 /usr/local/bin/python3
'
docker exec switchdev python3.12 --version
