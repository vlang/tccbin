# tccbin

This is a prebuilt tcc (git://repo.or.cz/tinycc.git) for Windows, cut at commit 9eef339 .

It is compiled with:
```shell 
./configure --prefix=/var/tmp/tcc --crtprefix=/var/tmp/tcc/lib:/usr/lib64:/usr/lib/x86_64-linux-gnu --libpaths=/var/tmp/tcc/lib:/usr/lib/x86_64-linux-gnu:/usr/lib64:/usr/lib:/lib/x86_64-linux-gnu:/lib:/usr/local/lib/x86_64-linux-gnu:/usr/local/lib  --debug
```
