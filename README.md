# tccbin

This is based on prebuilt [tcc compiler](https://repo.or.cz/tinycc.git), cut at commit [53d815b](https://repo.or.cz/tinycc.git/commit/53d815b8a0364a85b66c3b37884fca087b923267) (20200822) from mob branch. 

Please note that it is intended to be a *minimalism* version just enough to support V on *32-bit Windows*. One of the beauties of tcc is its portability. 

However, you may find this [official full version of tcc](http://download.savannah.gnu.org/releases/tinycc/winapi-full-for-0.9.27.zip) helpful as it includes many extra header files.

## How is it made? / What are the differences from original tcc? 

1、Collect tcc source code and compile it with [mingw32](https://sourceforge.net/projects/mingw-w64/files), just following steps in `tcc-win32.txt`.

2、Apply all fix commits [here](https://github.com/vlang/tccbin_win/commits/master) except for introduction of `openlibm.o` there as it's for tcc64.

3、Build `opeblibm.o` for tcc32 following instructions [here](https://github.com/spaceface777/openlibm-tcc) and copy it to `lib` folder.

4、Add implementations of `InterlockedCompareExchange16` and `InterlockedCompareExchange64` below into `include\winapi\winnt.h`

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

5、In `include\winapi\winbase.h` comment this line `LONGLONG WINAPI InterlockedCompareExchange64(LONGLONG volatile *Destination,LONGLONG Exchange,LONGLONG Comperand);`.
