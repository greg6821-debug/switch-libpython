#!/usr/bin/env bash
set -e

# ---------------------------
# Настройки
# ---------------------------
export PREFIXARCHIVE=$(realpath python39-switch.tar.gz)
export DEVKITPRO=/opt/devkitpro

# Определяем корень проекта (независимо от текущей директории)
export PROJECT_ROOT=$(realpath "$(dirname "$0")/..")

# Инициализация devkitPro и Switch портов
source $DEVKITPRO/switchvars.sh

# ---------------------------
# Переходим в исходники Python
# ---------------------------
pushd Python-3.9.22

mkdir -p build-switch
pushd build-switch

# Копируем необходимые конфиги
cp "$PROJECT_ROOT/cpython_config_files/config.site" .
mkdir -p Modules
cp "$PROJECT_ROOT/cpython_config_files/Setup.local" Modules/

mkdir -p local_prefix
export LOCAL_PREFIX=$(realpath local_prefix)

# ---------------------------
# Настройка toolchain
# ---------------------------
export CC=aarch64-none-elf-gcc
export CXX=aarch64-none-elf-g++
export LD=aarch64-none-elf-ld
export AR=aarch64-none-elf-ar
export RANLIB=aarch64-none-elf-ranlib
export SPEC="$DEVKITPRO/libnx/switch.specs"

export LDFLAGS="-specs=$SPEC -L$DEVKITPRO/portlibs/switch/lib $LDFLAGS"
export CPPFLAGS="-I$DEVKITPRO/portlibs/switch/include $CPPFLAGS"
export CFLAGS="-O2 -march=armv8-a+crc+crypto -mtune=cortex-a57 -fPIC -fPIE $CFLAGS"

# ---------------------------
# Конфигурация cross-build
# ---------------------------
PYTHON_FOR_BUILD=python3 \
CONFIG_SITE=config.site \
../configure \
  --host=aarch64-none-elf \
  --build="$(../config.guess)" \
  --prefix="$LOCAL_PREFIX" \
  --disable-ipv6 \
  --disable-shared \
  --without-pymalloc \
  --enable-optimizations \
  LDFLAGS="$LDFLAGS" \
  CPPFLAGS="$CPPFLAGS" \
  CFLAGS="$CFLAGS"

# ---------------------------
# Сборка статической библиотеки
# ---------------------------
make -j $(getconf _NPROCESSORS_ONLN) libpython3.9.a

# Установка вручную
mkdir -p $LOCAL_PREFIX/lib
cp libpython3.9.a $LOCAL_PREFIX/lib/libpython3.9.a

mkdir -p $LOCAL_PREFIX/include
cp -r ../Include/* $LOCAL_PREFIX/include/

popd
popd

# ---------------------------
# Пакуем артефакт
# ---------------------------
mkdir -p ./python39-switch
mv $LOCAL_PREFIX/* ./python39-switch/

# Минимизация Python-stdlib
pushd python39-switch/lib/python3.9
rm -rf test lib2to3/tests
rm subprocess.py
cp ../../../stub/subprocess.py ./
find . -type l -not -name "*.py" -delete
find . -type d -empty -delete
find . -name "*.py" -exec python3 -OO -m py_compile {} \;
popd
