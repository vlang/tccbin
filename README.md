# thirdparty-openbsd-amd64

This is a prebuild tcc (git://repo.or.cz/tinycc.git), cut at commit cb39bc4c (2025-05-27) .

It is compiled by copying the file `build.sh` into the V main repo folder, and doing:

```bash
TCC_FOLDER=thirdparty/tcc TCC_COMMIT=cb39bc4c thirdparty/build_scripts/thirdparty-openbsd-amd64_tcc.sh
```

on an AMD64/Intel based OpenBSD system.
