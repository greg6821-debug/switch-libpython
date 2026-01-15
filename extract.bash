curl -LOC - https://www.python.org/ftp/python/3.9.22/Python-3.9.22.tar.xz
rm -rf Python-3.9.22
tar -xf Python-3.9.22.tar.xz

# --- КОПИРОВАНИЕ ФАЙЛОВ ---
cp python_config/pyatomic.h     Python-3.9.22/Include/
cp python_config/pystate.h      Python-3.9.22/Include/

cp python_config/pyconfig.h     Python-3.9.22/
cp python_config/intrcheck.c    Python-3.9.22/Parser/
cp python_config/pytime.c       Python-3.9.22/Python/
cp python_config/random.c       Python-3.9.22/Python/
cp python_config/fileutils.c    Python-3.9.22/Python/
cp python_config/thread.c       Python-3.9.22/Python/
cp python_config/thread_nx.h    Python-3.9.22/Python/
cp python_config/condvar.h      Python-3.9.22/Python/
cp python_config/pylifecycle.c  Python-3.9.22/Python/
cp python_config/ceval_gil.h    Python-3.9.22/Python/

# --- PATCH'И ---
pushd Python-3.9.22
patch -p1 < ../cpython.patch
patch -p1 < ../my_patch.patch
patch -p1 < ../my_patch2.patch
popd
