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
  --disable-ipv6 \
  --disable-shared \
  --without-pymalloc \
  CPPFLAGS="-D__SWITCH__ -I$DEVKITPRO/libnx/include -I$DEVKITPRO/portlibs/switch/include" \
  LDFLAGS="-specs=$DEVKITPRO/libnx/switch.specs -L$DEVKITPRO/portlibs/switch/lib $LDFLAGS" \
  CONFIG_SITE="config.site"

popd
cp ../cpython_config_files/Setup.local build-switch/Modules
pushd build-switch
make -j $(getconf _NPROCESSORS_ONLN) libpython3.12.a
mkdir -p $LOCAL_PREFIX/lib
cp libpython3.12.a $LOCAL_PREFIX/lib/libpython3.12.a
make libinstall
make inclinstall
popd
popd

tar -czvf $PREFIXARCHIVE -C $LOCAL_PREFIX .
