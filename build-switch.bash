set -e

export PREFIXARCHIVE=$(realpath python39-switch.tar.gz)

source $DEVKITPRO/switchvars.sh
pushd Python-3.9.22
mkdir build-switch
cp ../cpython_config_files/config.site build-switch
pushd build-switch
mkdir local_prefix
export LOCAL_PREFIX=$(realpath local_prefix)

../configure \
  --host=aarch64-none-elf \
  --build=$(../config.guess) \
  --prefix="$LOCAL_PREFIX" \
  --disable-ipv6 \
  --disable-shared \
  --without-pymalloc \
  LDFLAGS="-specs=$DEVKITPRO/libnx/switch.specs $LDFLAGS" \
  CONFIG_SITE="config.site"
  
popd
cp ../cpython_config_files/Setup.local build-switch/Modules
pushd build-switch
make -j $(getconf _NPROCESSORS_ONLN) libpython3.9.a
mkdir -p $LOCAL_PREFIX/lib
cp libpython3.9.a $LOCAL_PREFIX/lib/libpython3.9.a
make libinstall
make inclinstall
popd
popd

tar -czvf $PREFIXARCHIVE -C $LOCAL_PREFIX .
