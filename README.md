![Github CI](https://github.com/fuzhouch/hashbld/actions/workflows/build.yml/badge.svg)


## Introduction

[HashBLD](https://github.com/fuzhouch/hashbld) is a project to build
[Hashlink](https://hashlink.haxe.org) and setup a proper development
environment. This project provides the following artifacts:

* Verified build scripts to build HashBLD on all platforms. Verified by
  the official [Hello Hashlink](https://heaps.io/documentation/hello-hashlink.html)
  example.
* Dependencies with nown versions (avoid using checked-in source code
  in Hashlink codebase)
* Portable build. Ensure build can be copied and used to different
  machines, with minimal dynamic linked libraries requirements from
  players Operating System.

## Quick start

### Build Hashlink

HashBLD uses [xmake](https://xmake.io) as a build tool with dependency
management support (versioning, download, build, etc.) that meets my
requirements. See section "Q & A" for details.

Please refers to
[Xmake's Official Guide](https://xmake.io/#/guide/installation) to
install it to system. For Archlinux or Manjaro, it can be installed
via ``pacman -S xmake``.

After installing ``xmake``, follow the steps below:

1. Checkout build scripts: ``git checkout https://github.com/fuzhouch/hashbld``.
2. Go to local folder of repository ``./hashbld``.
3. Checkout Hashlink code base and set branches: ``bash ./clone-code.sh``.
4. Build project: ``xmake build --rebuild --all``.
5. Create runnable package: ``xmake install --installdir=./package --all``.

After building, go to ``./package/lib``. All built binaries, including
virtual machine ``hl``, core libraries ``libhl.so`` (or ``libhl.dynlib``
for macOS), and 7 modules (``fmt.hdll``, ``openal.hdll``, ``sdl.hdll``,
``sqlite.hdll``, ``ssl.hdll``, ``ui.hdll``, ``uv.hdll``), are saved
under same folder. It can be packaged and copied to other machines for
use.

Note that ``clone-code.sh`` builds Hashlink in version 1.3. The master
branch is introducing a breaking change by the time Nov 28, 2023, which
does not work with released haxelib libraries. See section "Q & A" for
details.

I'm working on a solution to allow we use master branch. Will update.

### Run hello-world

This project has a
[Hello Hashlink](https://heaps.io/documentation/hello-hashlink.html)
example copied from
[official Heaps documentation](https://heaps.io/documentation/hello-hashlink.html).
To use it, we should compile it to bytecode first, then run it with
``hl`` virtual machine.

Please use the steps below to run:

1. Download and install [Haxe compiler](https://haxe.org/).
2. Install Haxe libraries: ``haxelib install heaps format hashlink, hlopenal, hlsdl``.
3. Compile bytecode: ``cd hashbld/hello-world && haxe compile.hxml``
4. Run program: ``./packages/lib/hl ./hello-world/hello.hl``.

A black window with a string "Hello Hashlink!" message should show on
desktop.

Note that we may see a lot of warnings from command when compiling
bytecode, this is because the released haxelib library version is 
behind the development of Haxe compiler. It can be annoying because the
warnings can hide the true errors. The section "Q & A" for details.

I'm working on a solution. Will update.


## Q & A

### How many platforms does HashBLD support?

My plan is to support the platforms below. It's a list that still on
progress.

- [X] Linux desktop
- [X] ~~Steam runtime (Linux, via Docker image)~~
- [ ] Windows desktop
- [X] macOS desktop
  - [ ] Code sign
  - [ ] Notarization
- [ ] iOS (including codesign and notarization)
- [X] ~~Android ARM~~


Steam runtime is removed from support list because it comes
with very old compiler toolchains (GCC 4.8.4, Clang 3.6/3.8), which does
not compile some dependencies like ``libuv``. Good news is, we can build
the full project in a Linux box and copy the binaries to Steam for use,
as the dependencies are under control when building with Hashlink.

Android ARM is removed because Hashlink does not support running on ARM
platform due to a lack of JIT. The correct approach is to build Haxe
code to C, then compile it via cross-compliation toolset.

### Q: Why do I maintain new build scripts while Hashlink already maintains its Makefile?

[Hashlink codebase](https://github.com/HaxeFoundation/hashlink)
maintains its own ``Makefile`` and ``CMakeLists.txt``. However, it comes
with 3 issues when I try to build a game with Heaps.io.

The first issue is, the official ``Makefile`` and ``CMakeLists.txt``
does not guaranteed to be built on all Operating Systems. For example,
Hashlink 1.3 depends on Operating System to provide ``mbedtls`` to build
``ssl.hdll`` module. It uses an old, ``2.x`` version, while systems like
Archlinux/Manjaro has been upgraded system to use an incompatible
``mbedtls 3.x`` which causes build breaks. To build it, developers
have to manually modify ``Makefile`` to point to correct ``mbedtls 2.x``
path, based on Operating System settings. It's difficult to maintain,
and hard to automate the build process.

The second issue is a dynamic linkage management. The official
``Makefile`` and ``CMakeLists.txt`` searches dependencies with whatever
versions provided by Operating System, mostly dynamically linked
libraries. When copying the executable binaries from build machine to
client machines, it's not guaranteed to run because client machines may
use different version of libraries, or just haven't installed some of
them. It can impact from functionality libraries like ``libsdl``, to
fundamental libraries like ``libc`` and ``libstdc++``.
To fix the issue, I need to ensure most functionality
code is linked statically. If some libraries must be linked dynamically
(notably ``OpenAL`` and ``libsndio``), I want to exactly ensure their
dependencies as well.

The last issue, is the ability to upgrade dependencies.
Hashlink includes some dependencies in their code base, which are very
old version. To prevent software bugs, esp., security breaches, I need
an ability to understand which version of dependencies I build with, and
upgrade if necessary. This is especially true when a game needs to
download data remotely and execute.


### Known issues and solution

- Avoid cross-compile via HashBLD. Hashlink depends on some libraries,
  mostly ``libuv``, which requires functionalities from high version of
  GCCs. Some systems with old compilers may not support building it.

- Hashlink prefers build
  [targeting Github versions](https://haxe.org/manual/target-hl-getting-started.html),
  to install libraries. Though it does not sound like a good solution
  from engineering point of view, the official haxelibs have bigger issue.
  It still uses a lot of old syntax, causing many build warnings.
  Haven't dig out a repeatable solution yet.

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
