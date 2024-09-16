# thirdparty-openbsd-amd64

This is a prebuild tcc (git://repo.or.cz/tinycc.git), cut at commit b8b6a5fd (2024-09-14) .

It is compiled by copying the file `build.sh` into the V main repo folder, and doing:

```bash
TCC_FOLDER=thirdparty/tcc TCC_COMMIT=b8b6a5fd ./build.sh
```

on an AMD64/Intel based OpenBSD system.
