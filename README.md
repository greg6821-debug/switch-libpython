# Python 3.12 port to Nintendo Switch

This repository contains a Python 3.12 port to Nintendo Switch, suitable
for running Ren'Py 8.2+ which requires Python 3.12.

It is derived from the earlier `3.9.22` branch of this project; the
CPython patch, build scripts and module list have been updated for the
3.12 source tree.

# Building

These steps are done on an Ubuntu 22.04 based image.
Clone the repository.
```bash
git clone -b 3.12 https://github.com/greg6821-debug/switch-libpython.git
```
Change directory to inside the repository.
```bash
cd switch-libpython
```
Install prerequisites (adds the deadsnakes PPA so `python3.12` is
available for byte-compiling the stdlib with the correct magic number).
```bash
sudo bash setup.bash
```
Set up the docker environment.
```bash
sudo bash setup-docker.bash
```
Download and extract CPython 3.12.16.
```bash
bash extract.bash
```
Configure, build, and archive prefix.
```bash
sudo bash build-switch-docker.bash
```
Package the stdlib into a zip file.
```bash
bash package-stdlib.bash
```
The resulting files are:
* `python312.zip` - The python stdlib (with the Switch-specific stubs
  for `subprocess`, `getpass`, `zipfile` and `importlib/__init__`
  already baked in)
* `python312-switch.tar.gz` - The built Python prefix (`libpython3.12.a`
  + headers)

# Switch-specific overrides

The `pystub/` directory contains patched stdlib modules that are
copied over the freshly built stdlib by `package-stdlib.bash`:

* `subprocess.py` - empty stub (no process spawning on Switch)
* `getpass.py` - falls back to `_otrhlibnx.getUserName()` then `"Player"`
* `importlib/__init__.py` - shim that resolves builtin modules through
  `_imp.is_builtin` / `BuiltinImporter`

These used to be applied manually by copying files over the built tree;
they are now wired into the packaging step so a single
`package-stdlib.bash` produces a ready-to-use `python312.zip`.

# License

This repository is licensed under PSF license v2. For more information,
see `LICENSE` file.
