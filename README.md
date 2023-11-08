## What is HashBLD?

HashBLD provides a set of build scripts to build Hashlink targeting
gaming platforms. The goal is to provide a out-of-box usable
[Hashlink](https://hashlink.haxe.org/) with minimal dependencies. It
should be executable on a clean target platform without development
tools or SDK installed, eliminating unexpected link error or unsatisfied
DLL issue.

This project verified a successful build, by using self-built hashlink
VM to launch the official
[Hello Hashlink](https://heaps.io/documentation/hello-hashlink.html)
example successfully.

The first set of target platforms include:

- [X] Linux desktop
- [ ] Steam runtime (Linux, via Docker image)
- [ ] Windows desktop
- [ ] macOS desktop (including codesign and notarization)
- [ ] iOS (including codesign and notarization)
- [ ] Android ARM

More platforms may be added when I expand my gaming plan to more
platforms.

### Build on Linux desktop

To build on Linux desktop, please follow the two steps:

1. Run script ``clone-code.sh``. It checkout hashlink source code from
   https://github.com/HaxeFoundation/hashlink to local. Then, it
   switches to tag 1.13.
2. Run command ``xmake build -y --all``. It automatically download all
   dependencies from Internet, and build executable (``hl``), standard
   library (``libhl.so``), and all extension libraries (``*.hdll``). All
   binaries can be found under ``build/linux/x86_64/release`` folder.

## Build a Hashlink executable with minimal dependencies

The biggest difference between the binaries built from ``xmake.lua``
with official build files, is that our Xmake build makes all
dependencies statically linked to Hashlink, as much as possible.
This step allows we build a hashlink with minimal system dependencies.
The list of dependencies that are statically linked are listed below.
In ``xmake.lua`` we can see all of them have configuration set to
``system = false``.

- mikktspace 2020.03.26
- libvorbis 1.3.7
- libpng v1.6.40
- libjpeg-turbo 2.1.4
- minimp3 2021.05.29
- zlib v1.3
- libui 2022.12.3
- libuv v1.46.0
- openal-soft 1.23.1
- mbedtls 2.28.3
- sqlite3 3.43.0+200

There are four exceptions, though:

- ``pcre``. Hashlink uses an very old ``pcre 8.42``, which is
  unavailable in Xmake package repository. The latest available version,
  ``pcre 8.45``, can compile but causes Hashlink VM crash with a strange
  "OpenGL error" message printed. I don't want to fix it because I see
  master version appears to be migrating to ``pcre2``. Let's wait a bit
  for next version.
- GNU C library, including ``libm``, ``libdl``, ``libstdc++``,
  ``libgcc_s.so``, ``libc.so``, ``/lib64/ld-linux-x86-64.so``,
  and ``linux-vdso.so``. These libraries must be provided by OS. Our
  Xmake build does not even provide linking options for most of them,
  except ``-lm``, ``-ldl``, ``-lstdc++``.
- ``OpenGL`` libraries are explicitly marked as ``-lGL`` option when
  building ``sdl.hdll``. This is for a similar reason just like GNU C
  library, that I suppose ``OpenGL`` should be provided by OS.
- X11 libraries, which is implicitly referenced when building SDL2, is
  also considered provided by OS. We don't have ability to handle
  building.

The cost of this design decision is, our customized builds are
around 10x larger in size, comparing with binaries built by official
Makefile or CMakeLists.txt. For example, the ``sdl.hdll`` library built
by xmake is around 2.8MiB, while the binary built by Makefile is
around 113KiB because it references libSDL2.so in system.

## Known issues and solution

- Don't use toolchain to define build options (cflags and ldflags).
  Toolchain can contain predefined cflags and ldflags. However, they
  will be applied to dependency building process as well. Some Hashlink
  dependencies, for example, ``libuv``, requires non-standard GNU
  extension such as ``pthread_rwlock_t``. They must follow different
  ``-std=`` build options. A best practice is always use default
  environment toolchain, except we are doing cross-compiling.

- Hashlink splits its code to Haxe code (to provide Haxe interfaces) and
  C code (build VM, standard libraries and extensions). Though Hashlink
  official documentation recommends we install Haxe code
  [targeting Github](https://haxe.org/manual/target-hl-getting-started.html),
  I don't think it a reliable approach because it's very easy to
  download C and Haxe code from different commits.

- By 2023-11, Hashlink master branch is preparing a breaking change from
  current 1.13 to master branch (1.14). If we build Hashlink from master
  branch, it can't execute bytecode compiled by official Haxe 4.3.1.
  If we do so, Hashlink exits with an error message like below.
  Seems similar issue happened before in
  [Github](https://github.com/HaxeFoundation/hashlink/issues/39).
  There's no solution yet. Let's wait for 1.14 release.

```
/home/fuzhouch/projects/thirdparty/hashlink/src/module.c(574) :
FATAL ERROR : Invalid signature for function fmt@mp3_open :
PBi_Xfmt_mp3_ required but P_Xfmt_mp3_ found in hdll
```
