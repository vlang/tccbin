# tccbin-windows-i386 (tcc32, tccwin32)

This is based on prebuilt [tcc compiler](https://repo.or.cz/tinycc.git), cut at commit [53d815b](https://repo.or.cz/tinycc.git/commit/53d815b8a0364a85b66c3b37884fca087b923267) (20200822) from mob branch. It is intended to be a ***minimalism*** version just enough to be V's backend, as lightweight is one of the beauties of tcc.

## Target OS
As V's backend it produces ***32-bit executables*** compatiable with both ***32-bit Windows*** and ***64-bit Windows***.  

## What if V reports lack of C header files in use?
In this case please create a PR to help us improve it. Please try finding lacked header files in [this](http://download.savannah.gnu.org/releases/tinycc/winapi-full-for-0.9.27.zip) official full version of tcc, or releases of [MinGW64](https://sourceforge.net/projects/mingw-w64/). For most cases the ported headers should just work nicely. However, small modification is sometimes needed to make them work with V.

## How is it made? / What are the differences from original tcc? 
Besides later modifications shown in this branch's commit history, the initial was made following these steps.

(1) Collect tcc source code ([tar.gz](https://repo.or.cz/tinycc.git/snapshot/53d815b8a0364a85b66c3b37884fca087b923267.tar.gz) or [zip](https://repo.or.cz/tinycc.git/snapshot/53d815b8a0364a85b66c3b37884fca087b923267.zip)) and compile it with [latest MinGW32](https://sourceforge.net/projects/mingw-w64/files/Toolchains%20targetting%20Win32/Personal%20Builds/mingw-builds/8.1.0/threads-posix/dwarf/i686-8.1.0-release-posix-dwarf-rt_v6-rev0.7z), just following steps in `doc\tcc-win32.txt`.

(2) Apply all fix commits [here](https://github.com/vlang/tccbin_win/commits/master) except for introduction of `openlibm.o` there, as it's for tcc64.

(3) Build `opeblibm.o` for tcc32 following instructions [here](https://github.com/spaceface777/openlibm-tcc) and copy it to `lib` folder.

(4) Add implementations of `InterlockedCompareExchange16` and `InterlockedCompareExchange64` below into `include\winapi\winnt.h`.

```C
__CRT_INLINE SHORT InterlockedCompareExchange16(SHORT volatile *Destination,SHORT ExChange,SHORT Comperand) {
	SHORT prev;
	__asm__ __volatile__("lock ; cmpxchgw %w1,%2"
	             	    : "=a"(prev)
	                    : "q"(ExChange), "m"(*Destination), "0"(Comperand)
	                    : "memory");
	return prev;
}

__CRT_INLINE LONG64 InterlockedCompareExchange64(LONG64 volatile *Destination,LONG64 ExChange,LONG64 Comperand) {
	LONG64 prev = Comperand;
	LONG ex_h = (LONG)(ExChange >> 32);
	LONG ex_l = (LONG)(ExChange & 0xffffffff);
	__asm__ __volatile__("lock ; cmpxchg8b (%%esi)"
			    : "=A" (prev)
			    : "A" (prev), "c" (ex_h), "b" (ex_l), "S" (Destination)
			    : "memory");
	return prev;
}
```

Search `#ifdef I_X86_` in this file to help you find the right position to add them.

(5) In `include\winapi\winbase.h` comment this line.

```C
LONGLONG WINAPI InterlockedCompareExchange64(LONGLONG volatile *Destination,LONGLONG Exchange,LONGLONG Comperand);
```
