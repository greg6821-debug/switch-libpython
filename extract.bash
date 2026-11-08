
curl -LOC - https://www.python.org/ftp/python/3.12.16/Python-3.12.16.tar.xz
rm -rf Python-3.12.16
tar -xf Python-3.12.16.tar.xz
pushd Python-3.12.16
patch -p1 < ../cpython.patch
popd
