# tccbin

This is a prebuilt tcc (git://repo.or.cz/tinycc.git) for arm64, cut at commit `3cfaaaf`.

It is compiled with:
```shell
./configure --prefix=/var/tmp/tcc --crtprefix=/var/tmp/tcc/lib:/usr/lib64:/usr/lib/aarch64-linux-gnu --libpaths=/var/tmp/tcc/lib:/usr/lib/aarch64-linux-gnu:/usr/lib64:/usr/lib:/lib/aarch64-linux-gnu:/lib:/usr/local/lib/aarch64-linux-gnu:/usr/local/lib --debug
```
