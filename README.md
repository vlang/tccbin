# thirdparty-linux-riscv64

This is a prebuild tcc (git://repo.or.cz/tinycc.git). 
See build_source_hash.txt for its version.
See build_on_date.txt for its build date.
See build_version.txt for the original output of `tcc.exe --version` on the build machine.

# How to rebuilt:
You *have* to be in V's main repo folder.
(in the next instruction, change b8b6a5fd with the commit hash from thirdparty/tcc/build_source_hash.txt).
Then do:
```sh
TCC_FOLDER=thirdparty/tcc TCC_COMMIT=b8b6a5fd thirdparty/build_scripts/thirdparty-linux-riscv64_tcc.sh
```


