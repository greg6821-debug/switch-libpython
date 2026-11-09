# switch-libpython branch 3.12 — updates for Ren'Py 8.5.3 Switch port

## Files changed

### cpython.patch
Added 3 new hunks (total 9, was 6):
- `Python/pystate.c` — `_Py_switch_current_tstate` global for `__SWITCH__`
  (3.12 removed the global `gilstate.tstate_current` and went pure-TLS which
  is unreliable on libnx main thread with `-mtp=soft`)
- `Include/internal/pycore_pstate.h` — `_PyThreadState_GET()` uses global
  for `__SWITCH__`
- `Objects/unicodeobject.c` — `config_get_codec_name()` bypass for `__SWITCH__`
  (skips `_PyCodec_Lookup` which tries to import `encodings` from lib.zip
  via zipimport during bootstrap, before the import system is fully operational)

### build-switch.bash
Added `Include/cpython/*.h` copy (50 headers like `pymem.h`, `tupleobject.h`).
`Python.h` does `#include "cpython/pymem.h"` — without these, compilation
fails with `cpython/pymem.h: No such file or directory`.

### cpython_config_files/Setup.local
`_sha2` is enabled (was commented out). `libHacl_Hash_SHA2.a` is linked
via the `Modules/_hacl/libHacl_Hash_SHA2.a` path in the Setup.local line.
This provides sha256/sha512 for `hashlib` (needed by `random` → `tempfile`).

## How to build
```bash
# In the switch-libpython repo (branch 3.12):
extract.bash          # downloads Python-3.12.16 + applies cpython.patch
build-switch.bash     # configure + make libpython3.12.a + install headers + tar
# Result: python312-switch.tar.gz
```
