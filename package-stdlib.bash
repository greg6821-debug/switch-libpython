
set -e

export LOCAL_PREFIX=$(realpath Python-3.12.16/build-switch/local_prefix)
export PYTHONLIBZIP=$(realpath python312.zip)
export LIB_BUILD_DIR=./tmp_lib
export PYSTUB_DIR=$(realpath pystub)

rm -rf $LIB_BUILD_DIR $PYTHONLIBZIP
cp -as $LOCAL_PREFIX/lib/python3.12 $LIB_BUILD_DIR
rm -r $LIB_BUILD_DIR/test
rm -r $LIB_BUILD_DIR/lib2to3/tests

# Replace Switch-specific stdlib modules with the patched stubs.
# These files are required so the interpreter behaves correctly on
# Switch (no real subprocess, no pwd, Horizon path quirks, builtin
# module import shim, etc.).
for override in subprocess.py getpass.py zipfile.py importlib/__init__.py; do
  if [ -f "$PYSTUB_DIR/$override" ]; then
    rm -f "$LIB_BUILD_DIR/$override"
    mkdir -p "$(dirname "$LIB_BUILD_DIR/$override")"
    cp "$PYSTUB_DIR/$override" "$LIB_BUILD_DIR/$override"
  fi
done

pushd $LIB_BUILD_DIR
find . -type l -not -name \*.py -delete
find . -type d -empty -delete
# Use python3.12 so the resulting .pyc carries the 3.12 magic number
# (a mismatched magic would force an in-memory recompile on the
# Switch target, slowing startup).
PY=$(command -v python3.12 || command -v python3)
find . -name \*.py -exec "$PY" -OO -m py_compile {} \;
7z a -l $PYTHONLIBZIP .
popd
