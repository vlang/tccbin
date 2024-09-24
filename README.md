# tccbin

This repository contains prebuilt executables for TCC, for different operating systems.

PRs should be done to the corresponding branches. If a branch for your
target triplet is not already created, please make an issue about it.

Note: *Do not make PRs to the `master` branch. They will be closed.*

# TCC
TCC can be obtained from https://repo.or.cz/tinycc.git (follow the instructions there).

Note: you have to compile it with `--config-backtrace=yes` and `--config-bcheck=yes`,
for V to work without additional V flags. The reason for that, is the V's builtin module
has calls to tcc_backtrace() for panics, when tcc is used, and tcc's bounds checking is
useful as a debugging aid for prototyping and debug builds.

If those flags do not work for you, your users will have to pass: 
`-d no_backtrace` and `-d no_segfault_handler` while compiling
their programs with your prebuilt tcc, which is not very convenient.

You also need to ensure that the values you pass to --prefix and
--bindir, during tcc's configuration stage, point to thirdparty/tcc .

The rest of the options can vary depending on the platform.

# Add a Build script for easier future reproductions with newer version of TCC
You can look/copy [build.sh](https://github.com/vlang/tccbin/blob/thirdparty-linux-amd64/build.sh),
and customize it for your new build. Please include a copy of the customized build script with your PR.
