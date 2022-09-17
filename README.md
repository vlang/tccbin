# thirdparty-linux-amd64

This is a prebuild tcc (git://repo.or.cz/tinycc.git), cut at commit:
806b3f9 from 2021-03-17
which is the last good commit found by bisecting, that does not cause vlib/sync/channel_close_test.v to wait indefinitely .

Copy `build.sh` into V's main repo folder, and run it *from there* to re-compile it.
