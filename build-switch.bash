set -e

export PREFIXARCHIVE=$(realpath python312-switch.tar.gz)

source $DEVKITPRO/switchvars.sh
pushd Python-3.12.16
mkdir build-switch
cp ../cpython_config_files/config.site build-switch
pushd build-switch
mkdir local_prefix
export LOCAL_PREFIX=$(realpath local_prefix)

../configure \
  --host=aarch64-none-elf \
  --build=$(../config.guess) \
  --prefix="$LOCAL_PREFIX" \
  --with-build-python="$(command -v python3.12 || command -v python3)" \
  --disable-ipv6 --disable-shared --without-pymalloc \
  CPPFLAGS="-D__SWITCH__ -I$DEVKITPRO/libnx/include -I$DEVKITPRO/portlibs/switch/include" \
  LDFLAGS="-specs=$DEVKITPRO/libnx/switch.specs -L$DEVKITPRO/portlibs/switch/lib $LDFLAGS" \
  CONFIG_SITE="config.site"

popd
cp ../cpython_config_files/Setup.local build-switch/Modules
pushd build-switch

# Build ONLY the static library. Do NOT run "make all" / "make inclinstall" /
# "make libinstall" — those trigger shared-module builds (.so) which link
# with the host ld (x86_64) and fail on ARM flags like -mtp=soft. We don't
# need shared modules: renpy compiles its own C extensions against
# libpython3.12.a + headers.
make -j $(getconf _NPROCESSORS_ONLN) libpython3.12.a

mkdir -p $LOCAL_PREFIX/lib
cp libpython3.12.a $LOCAL_PREFIX/lib/libpython3.12.a

# Install headers manually (replaces "make inclinstall" which would pull in
# the full "all" target and try to build shared modules).
mkdir -p $LOCAL_PREFIX/include/python3.12/internal
cp -a ../Include/*.h $LOCAL_PREFIX/include/python3.12/
# FIX: Include/cpython/ subdirectory (50 headers like pymem.h, tupleobject.h).
# Python.h does #include "cpython/pymem.h" — without these, compilation fails
# with "cpython/pymem.h: No such file or directory".
mkdir -p $LOCAL_PREFIX/include/python3.12/cpython
cp -a ../Include/cpython/*.h $LOCAL_PREFIX/include/python3.12/cpython/
cp pyconfig.h $LOCAL_PREFIX/include/python3.12/
cp -a ../Include/internal/*.h $LOCAL_PREFIX/include/python3.12/internal/ 2>/dev/null || true

# Copy the stdlib .py files (patched by cpython.patch: posixpath Horizon
# handling etc.). Do NOT run "make libinstall" — it tries to byte-compile
# with the cross-built python (can't run on host) and pulls in shared modules.
mkdir -p $LOCAL_PREFIX/lib/python3.12
cp -a ../Lib/. $LOCAL_PREFIX/lib/python3.12/
rm -rf $LOCAL_PREFIX/lib/python3.12/test $LOCAL_PREFIX/lib/python3.12/lib2to3/tests

popd
popd

tar -czvf $PREFIXARCHIVE -C $LOCAL_PREFIX .
