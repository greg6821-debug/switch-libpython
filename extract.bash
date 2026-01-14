
curl -LOC - https://www.python.org/ftp/python/3.9.22/Python-3.9.22.tar.xz
rm -rf Python-3.9.22
tar -xf Python-3.9.22.tar.xz
pushd Python-3.9.22
patch -p1 < ../cpython.patch
patch -p1 < ../my_patch.patch
patch -p1 < ../my_patch2.patch
popd
