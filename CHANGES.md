# switch-libpython branch 3.12 — updates for Ren'Py 8.5.3 Switch port

## Files changed

### cpython.patch
Added 3 new hunks (total 9, was 6):
- `Python/pystate.c` — `_Py_switch_current_tstate` global for `__SWITCH__`
- `Include/internal/pycore_pstate.h` — `_PyThreadState_GET()` uses global for `__SWITCH__`
- `Objects/unicodeobject.c` — `config_get_codec_name()` bypass for `__SWITCH__`

### build-switch.bash
Added `Include/cpython/*.h` copy (50 headers like `pymem.h`).
Python.h does `#include "cpython/pymem.h"` — without these, compilation fails.

### setup-docker.bash
Fixed Debian Bullseye EOL — redirect ALL apt sources to `archive.debian.org`.
Also handles `/etc/apt/sources.list.d/*.list` files and disables valid-until checks.

### cpython_config_files/Setup.local
`_sha2` is enabled — provides sha256/sha512 for `hashlib` (needed by `random` → `tempfile`).

## How to build (CI)
Push to branch 3.12 → CI workflow runs:
1. `setup.bash` — install Docker on the runner
2. `setup-docker.bash` — start devkitpro container + build python3.12 host
3. `extract.bash` — download Python-3.12.16 + apply cpython.patch
4. `build-switch-docker.bash` — run build-switch.bash inside container
5. `package-stdlib.bash` — package python312.zip (stdlib with .pyc)
6. Upload artifacts: `python312-switch.tar.gz` + `python312.zip`

## How to build (locally)
```bash
sudo bash setup.bash          # install Docker
sudo bash setup-docker.bash   # start container
bash extract.bash             # download + patch Python source
bash build-switch-docker.bash # build inside container
bash package-stdlib.bash      # package stdlib
```
