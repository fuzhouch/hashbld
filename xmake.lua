-- This xmake.lua build file is designed as a replacement of
-- Makefile or CMakeLists.txt of standard hashlink releases.
--
-- The idea is to maximize the flexibility provided by xmake, that
-- 
-- a) In most desktop platforms, we use xmake, minimize per-compiler
--    settings
-- b) In Steam build Docker image, we use xmake generated Makefile.

-- Dependencies of core
add_requires("pcre2 10.40", { system = false })
add_requires("mikktspace 2020.03.26", { system = false })
add_requires("libvorbis 1.3.7", { system = false })
add_requires("libpng v1.6.40", { system = false })
add_requires("minimp3 2021.05.29", { system = false })
add_requires("zlib v1.3", { system = false })
add_requires("libui 2022.12.3", { system = false })
add_requires("libuv v1.46.0", { system = false })
add_requires("sqlite3 3.43.0+200", { system = false })
add_requires("mbedtls 2.28.3", { system = false })
add_requires("openal-soft 1.23.1", { system = false })

-- libsdl may have problems when building package from source. The
-- reason is SDL hard-codes search path to find X11/Xext.h, which assumes
-- a set of predefined paths but includes only /usr/include/X11.
-- In Manjaro Linux all Xorg headers are placed at /usr/include/X11.
-- Thus, SDL2 build file can only locate header file at
-- /usr/include/X11/X11/Xext.h.
--
-- To fix it we need to use 2.28.5 or above. It adds a Cmake parameter
-- X11_INCLUDE_DIR, which should be set to /usr/include.
--
-- See code: https://github.com/libsdl-org/SDL/blob/07cb7c10a15b95387431bcb3a1ae77cfd432707b/cmake/sdlchecks.cmake#L269 
add_requires("libsdl 2.28.5", { system = false })


-- Define our own toolchains. Every toolchain should be platform
-- specific, with compiler specific flag built-in.
toolchain("linux_x86_64-gcc")
    set_kind("standalone")
    set_toolset("ar", "ar")
    set_toolset("as", "gcc")
    set_toolset("cc", "gcc")
    set_toolset("cxx", "g++")
    set_toolset("ld", "gcc")
    set_toolset("sh", "gcc")

    on_load(function (toolchain)
        if not is_arch("x86_64", "x64") then
        end

        toolchain:add("cxflags", "-fPIC")
        toolchain:add("cxflags", "-pthread")
        toolchain:add("cxflags", "-fno-omit-frame-pointer")
        toolchain:add("ldflags", "-lm")
        toolchain:add("ldflags", "-Wl,-rpath,.:'$ORIGIN'")
        toolchain:add("ldflags", "-Wl,--export-dynamic")
        toolchain:add("ldflags", "-Wl,--no-undefined")
    end)

-- Core library
target("hl")
    set_kind("shared")
    add_includedirs("hashlink/src")
    add_files("hashlink/src/std/*.c")
    add_files("hashlink/src/gc.c")
    add_defines("HAVE_CONFIG_H")
    add_defines("PCRE2_CODE_UNIT_WIDTH=16")
    add_packages("pcre2")

-- Main executable. We use a long name "hashlink" instead of a short
-- name "hl" like official. This is due to a restriction of xmake, that
-- it does not support targets have identical names, even if the two
-- targets are indeed different kinds. 
target("hashlink")
    set_kind("binary")
    add_includedirs("hashlink/src")
    add_files("hashlink/src/code.c",
              "hashlink/src/jit.c",
              "hashlink/src/main.c",
              "hashlink/src/module.c",
              "hashlink/src/debugger.c",
              "hashlink/src/profile.c")
   add_ldflags("-ldl")
   add_deps("hl")

--
-- Below are libraries built with hashlink. Note that they also needs
-- haxelib install commands to get Haxe interface, in order to access
-- them.
--
target("fmt")
   set_kind("shared")
   add_includedirs("hashlink/src")
   add_files("hashlink/libs/fmt/*.c")
   add_packages("mikktspace", "libvorbis", "minimp3", "zlib")
   add_deps("hl")

target("ui")
   set_kind("shared")
   add_includedirs("hashlink/src")
   add_files("hashlink/libs/ui/ui_stub.c")
   add_packages("libui")
   add_deps("hl")

target("uv")
   set_kind("shared")
   add_includedirs("hashlink/src")
   add_files("hashlink/libs/uv/*.c")
   add_packages("libuv")
   add_deps("hl")

target("sqlite")
   set_kind("shared")
   add_includedirs("hashlink/src")
   add_files("hashlink/libs/sqlite/*.c")
   add_packages("sqlite3")
   add_deps("hl")

target("ssl")
   set_kind("shared")
   add_includedirs("hashlink/src")
   add_files("hashlink/libs/ssl/*.c")
   add_packages("mbedtls")
   add_deps("hl")

target("openal")
   set_kind("shared")
   add_includedirs("hashlink/src")
   add_files("hashlink/libs/openal/openal.c")
   add_packages("openal")
   add_deps("hl")

target("sdl")
    set_kind("shared")
    add_includedirs("hashlink/src")
    add_files("hashlink/libs/sdl/sdl.c",
              "hashlink/libs/sdl/gl.c")
    add_packages("libsdl") -- add { system = true } to build with system
    add_deps("hl")
