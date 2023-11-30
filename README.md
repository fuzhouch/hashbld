![Github CI](https://github.com/fuzhouch/hashbld/actions/workflows/build.yml/badge.svg)


## Introduction

[HashBLD](https://github.com/fuzhouch/hashbld) is a project to build
[Hashlink](https://hashlink.haxe.org) and setup a proper development
environment. This project provides the following artifacts:

* Verified build scripts to build HashBLD on all platforms. Verified by
  the official [Hello Hashlink](https://heaps.io/documentation/hello-hashlink.html)
  example.
* Dependencies with known versions (avoid using checked-in source code
  in Hashlink codebase)
* Portable build. Ensure build can be copied and used to different
  machines, with minimal dynamic linked libraries requirements from
  players Operating System.

## Quick start

### Xmake as build tool

HashBLD uses [xmake](https://xmake.io) as a build tool with dependency
management support (versioning, download, build, etc.) that meets my
requirements. See section "Q & A" for details. Please refers to
[Xmake's Official Guide](https://xmake.io/#/guide/installation) to
install it to system. For Archlinux or Manjaro, it can be installed
via ``pacman -S xmake``.

### Build Hashlink

After installing ``xmake``, follow the steps below:

1. Checkout build scripts: ``git checkout https://github.com/fuzhouch/hashbld``.
2. Go to local folder of repository ``./hashbld``.
3. Checkout Hashlink code base to master: ``bash ./clone-code.sh``.
4. Build project: ``xmake build --rebuild``.
5. Create runnable package: ``xmake install -o ./package64``.

After building, go to ``./package64/lib`` (macOS or Linux), or
``./package64/bin`` (Windows). All built binaries, including
virtual machine ``hl``, core libraries ``libhl.so`` (or ``libhl.dynlib``
for macOS), and 7 modules (``fmt.hdll``, ``openal.hdll``, ``sdl.hdll``,
``sqlite.hdll``, ``ssl.hdll``, ``ui.hdll``, ``uv.hdll``), are saved
under same folder. It can be packaged and copied to other machines for
use.

Note that ``clone-code.sh`` builds Hashlink in version master branch.
Per suggestion from community, the Haxelib version of Hashlink and Heaps
library are usually out-dated. We should use master branch. See the
unofficial Q & A in Reference section for more details.

### Run hello-world

This project has a
[Hello Hashlink](https://heaps.io/documentation/hello-hashlink.html)
example copied from
[official Heaps documentation](https://heaps.io/documentation/hello-hashlink.html).
To use it, we should compile it to bytecode first, then run it with
``hl`` virtual machine.

Please use the steps below to run:

1. Download and install [Haxe compiler](https://haxe.org/).
2. Install libraries with development/latest version: ``bash ./install-haxe-libs.sh``.
3. Compile bytecode: ``cd hashbld/hello-world && haxe compile.hxml``
4. Run program to execute test window:
   - Windows: ``./packages64/bin/hl.exe ./hello-world/hello.hl``.
   - macOS and Linux: ``./packages64/lib/hl ./hello-world/hello.hl``.

A black window with a string "Hello Hashlink!" message should show on
desktop.

Note that we may see a lot of warnings from command when compiling
bytecode, this is because the released haxelib library version is 
behind the development of Haxe compiler. It can be annoying because the
warnings can hide the true errors. The section Q & A for details.

I'm working on a solution. Will update.


## Q & A

### How many platforms does HashBLD support?

My plan is to support the platforms below. The list is still on
progress, and keep updating:

- [X] Linux desktop
- [ ] ~~Steam runtime (Linux, via Docker image)~~
- [X] Windows desktop
- [X] macOS desktop
  - [ ] Code sign
  - [ ] Notarization
- [ ] iOS (including codesign and notarization)
- [ ] ~~Android ARM~~


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

**Issue 1: It does not always build.** The official ``Makefile``
and ``CMakeLists.txt`` rely on headers or packages provided by system,
while system may provide incompatible versions. For example,
Hashlink 1.13 depends on Operating Systems to provide ``mbedtls`` for
``ssl.hdll`` module. It uses an old, ``2.x`` version, while systems like
Archlinux/Manjaro has been upgraded to use ``mbedtls 3.x``. The ``3.x``
version introduces many incompatible changes comparing with ``2.x``.
It causes build breaks.

**Issue 2: It is not always portable**. By relying on Operating Systems
providing dependencies, the official ``Makefile`` or ``CMakeLists.txt`` usually
link to shared libraries. Thus, when copying the executable binaries from
developers' build machines to client machines, it can break when client
machines do not have same version of dependencies installed. This is
a common scenario in Linux world, from high-level functionality
libraries like ``MbedTLS`` to infrastructures like ``libc`` and
``libstdc++``.

**Issue 3: It is not always safe**. To solve issue 1 and 2, Hashlink
includes dependencies source code as part of its own repo.
However they are not upgraded often, results in old versions used for
many years (e.g., Hashlink uses old pcre version back to 2018, which was
upgraded in master branch at March 25, 2023, see
[this merge request](https://github.com/HaxeFoundation/hashlink/pull/515)).
If a dependency has a security breach, it's hard to fix, leaving potential
risks to players. This is especially true if a game attempts to download
executable logic from Internet, or take inputs from other local applications.

HashBLD tries to address the issues above by applying 3 rules:

1. ``Avoid system dependencies if possible``. HashBLD tries to build
   and distribute dependencies ourselves, eliminating any explicit or
   implicit dependencies. Only a few really fundamental dependencies, like
   ``openal-soft`` or ``OpenGL``, are required to be provided by Operating
   Systems. It maximizes possibility to build the project in different machines.

2. ``Dependencies are versioned``. HashBLD does not use the
   checked-in dependency code. Instead, it downloads released source code
   of each dependency by version from Interent. With this approach, we
   exactly know which version we are using, so we can make upgrading choice
   on a security breach. Note that some exceptions may apply due to
   technical challenges, notably ``pcre``. They should be fixed in
   future versions.

3. ``Prefer static over shared if possile``. HashBLD links against static
   libraries for most dependencies. It reduces the
   risk of version conflict between our own built dependencies and
   system provided dependencies. There are some exceptions due to its
   own project nature though, e.g., ``openal-soft``, ``libsndio`` and
   ``libglvnd``.

### Known issues and solution

- Avoid cross-compile via HashBLD. Hashlink depends on some libraries,
  mostly ``libuv``, which requires functionalities from high version of
  GCCs. Some systems with old compilers may not support building it.

- Hashlink prefers building
  [targeting Github versions](https://haxe.org/manual/target-hl-getting-started.html),
  to install libraries. Though it does not sound like a good solution
  from engineering point of view, the official haxelibs have bigger issue.
  It still uses a lot of old syntax, causing many build warnings.
  Haven't dig out a repeatable solution yet.

- The ``ssl.hdll`` module is not built on Windows. This is caused by
  restrictions of XMake when building ``EmbdTLS 2.x``. Unlike other
  dependencies, ``EmbdTLS 2.x`` requires developer customize project
  settings via a ``config.h`` header instead of CMake file command line
  options. Hashlink requires a customized ``config.h`` to insert
  its own implementation of ``mbedtls_threading_mutex_t`` structure to
  multi-threading support on Windows (defined in
  ``hashlink/include/mbedtls/include/mbedtls/threading_alt.h``.
  Unfortunately [XRepo's pacakge](https://github.com/xmake-io/xmake-repo/blob/master/packages/m/mbedtls/xmake.lua)
  does not offer a way to insert our own ``config.h``. As security is a
  consideration, I have to disable it for now.

## Reference

- [Unofficial Heaps.io FAQ](https://gist.github.com/Yanrishatum/ae3725a9e2b45e0766c065e573ed1f24)
- [Using Haxelib](https://lib.haxe.org/documentation/using-haxelib/)
