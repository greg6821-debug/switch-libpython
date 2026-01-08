
set -e

export PREFIXARCHIVE=$(realpath python39-switch.tar.gz)

source $DEVKITPRO/switchvars.sh
pushd Python-3.9.22
mkdir build-switch
cp ../cpython_config_files/config.site build-switch
pushd build-switch
mkdir local_prefix
export LOCAL_PREFIX=$(realpath local_prefix)
PYTHON_FOR_BUILD=python3 ./configure \
  --host=aarch64-none-elf \
  --build=x86_64-pc-linux-gnu \
  ${CONFIGURE_FLAGS}
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
