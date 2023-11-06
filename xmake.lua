-- This xmake.lua build file is designed as a replacement of
-- Makefile or CMakeLists.txt of standard hashlink releases.
--
-- The idea is to maximize the flexibility provided by xmake, that
-- 
-- a) In most desktop platforms, we use xmake, minimize per-compiler
--    settings
-- b) In Steam build Docker image, we use xmake generated Makefile.

add_requires("pcre2 >=10.40")

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

target("hl")
    set_kind("shared")
    add_includedirs("hashlink/src")
    add_files("hashlink/src/std/*.c")
    add_files("hashlink/src/gc.c")
    add_defines("HAVE_CONFIG_H")
    add_defines("PCRE2_CODE_UNIT_WIDTH=16")
    add_packages("pcre2")
