-- This xmake.lua build file is designed as a replacement of
-- Makefile or CMakeLists.txt of standard hashlink releases.
--
-- The idea is to maximize the flexibility provided by xmake, that
-- 
-- a) In most desktop platforms, we use xmake, minimize per-compiler
--    settings
-- b) In Steam build Docker image, we use xmake generated Makefile.

-- Dependencies of core
-- add_requires("pcre 8.45", { system = false, configs = { bitwidth = 16 }})
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
add_requires("libjpeg-turbo 2.1.4", { system = false })
-- For now let's use system built-in version of libSDL. My static libSDL
-- always causes Address Boundary error crash on my Linux desktop. I
-- haven't got root cause spotted yet. This issue needs to be solved
-- because SDL is not installed by default on Windows desktop.
add_requires("libsdl", { system = true })

-----------------------------------------------------------------
-- Utility functions
-----------------------------------------------------------------

function rename_hdll (target)
    target:set("filename", target:basename() .. ".hdll")
end

function binary_link_flags(target)
    if target:is_plat("linux") then
        target:add("cxflags", "-pthread")
        target:add("ldflags", "-lm")
        -- Linux/gcc settings
        target:add("cxflags", "-fPIC")
        target:add("cxflags", "-fno-omit-frame-pointer")
        target:add("ldflags", "-Wl,-rpath,.:'$ORIGIN'")
        target:add("ldflags", "-Wl,--export-dynamic")
        target:add("ldflags", "-Wl,--no-undefined")
    end
end

function dynlib_link_flags(target)
    if target:is_plat("linux") then
        target:add("cxflags", "-pthread")
        target:add("ldflags", "-lm")
    end
end

function compile_flags(target)
    if target:is_plat("linux") then
        -- Build location specific
        target:add("cflags", "-Ihashlink/src")

        -- Build location independent settings
        target:add("cflags", "-Wall")
        target:add("cflags", "-O3")
        target:add("cflags", "-msse2")
        target:add("cflags", "-mfpmath=sse")
        target:add("cflags", "-std=c11")
        target:add("defines", "LIBHL_EXPORTS")
    end
end

function bind_flags(...)
    local args = { ... }
    return function(target)
        for i, fun in ipairs(args) do
            fun(target)
        end
    end
end

-----------------------------------------------------------------
-- Hashlink standard library
-----------------------------------------------------------------
target("hl")
    set_kind("shared")
    add_includedirs("hashlink/src")
    add_files("hashlink/src/std/array.c",
              "hashlink/src/std/buffer.c",
              "hashlink/src/std/bytes.c",
              "hashlink/src/std/cast.c",
              "hashlink/src/std/date.c",
              "hashlink/src/std/error.c",
              "hashlink/src/std/debug.c",
              "hashlink/src/std/file.c",
              "hashlink/src/std/fun.c",
              "hashlink/src/std/maps.c",
              "hashlink/src/std/math.c",
              "hashlink/src/std/obj.c",
              "hashlink/src/std/random.c",
              "hashlink/src/std/regexp.c",
              "hashlink/src/std/socket.c",
              "hashlink/src/std/string.c",
              "hashlink/src/std/sys.c",
              "hashlink/src/std/track.c",
              "hashlink/src/std/types.c",
              "hashlink/src/std/ucs2.c",
              "hashlink/src/std/thread.c",
              "hashlink/src/std/process.c")
    -- Hashlink saves a copy of an old pcre version 8.42, which is
    -- unavailable in xmake repository. The earlest available version,
    -- pcre 8.45, causes crashes in Linux.
    --
    -- Let's use built-in version. Supposed it should be updated in master version.
    add_files("hashlink/include/pcre/pcre_chartables.c",
              "hashlink/include/pcre/pcre_compile.c",
              "hashlink/include/pcre/pcre_dfa_exec.c",
              "hashlink/include/pcre/pcre_exec.o",
              "hashlink/include/pcre/pcre_fullinfo.o",
              "hashlink/include/pcre/pcre_globals.o",
              "hashlink/include/pcre/pcre_newline.c",
              "hashlink/include/pcre/pcre_string_utils.c",
              "hashlink/include/pcre/pcre_tables.c",
              "hashlink/include/pcre/pcre_xclass.c",
              "hashlink/include/pcre/pcre16_ord2utf16.c",
              "hashlink/include/pcre/pcre16_valid_utf16.c",
              "hashlink/include/pcre/pcre_ucd.c")
    add_files("hashlink/src/gc.c")
    -- add_packages("pcre")
    on_load(bind_flags(compile_flags, dynlib_link_flags))

-----------------------------------------------------------------
-- Main executable. We use a long name "hashlink" instead of a short
-- name "hl" like official. This is due to a restriction of xmake, that
-- it does not support targets have identical names, even if the two
-- targets are indeed different kinds. 
-----------------------------------------------------------------
target("hashlink")
    set_kind("binary")
    add_includedirs("hashlink/src")
    add_ldflags("-ldl")
    add_files("hashlink/src/code.c",
              "hashlink/src/jit.c",
              "hashlink/src/main.c",
              "hashlink/src/module.c",
              "hashlink/src/debugger.c",
              "hashlink/src/profile.c")
    add_deps("hl")
    on_load(bind_flags(compile_flags, binary_link_flags))

-----------------------------------------------------------------
-- Below are libraries built with hashlink. Note that they also needs
-- haxelib install commands to get Haxe interface, in order to access
-- them.
-----------------------------------------------------------------
target("fmt")
    set_kind("shared")
    add_includedirs("hashlink/src")
    add_files("hashlink/libs/fmt/*.c")
    add_deps("hl")
    add_packages("mikktspace", "libvorbis", "minimp3", "zlib", "libpng", "libjpeg-turbo")
    on_load(bind_flags(compile_flags, dynlib_link_flags))
    before_link(rename_hdll)

target("ui")
    set_kind("shared")
    add_includedirs("hashlink/src")
    add_files("hashlink/libs/ui/ui_stub.c")
    add_packages("libui")
    add_deps("hl")
    on_load(bind_flags(compile_flags, dynlib_link_flags))
    before_link(rename_hdll)

target("uv")
    set_kind("shared")
    add_includedirs("hashlink/src")
    add_files("hashlink/libs/uv/*.c")
    add_packages("libuv")
    add_deps("hl")
    on_load(bind_flags(compile_flags, dynlib_link_flags))
    before_link(rename_hdll)

target("sqlite")
    set_kind("shared")
    add_includedirs("hashlink/src")
    add_files("hashlink/libs/sqlite/*.c")
    add_packages("sqlite3")
    add_deps("hl")
    on_load(bind_flags(compile_flags, dynlib_link_flags))
    before_link(rename_hdll)

target("ssl")
    set_kind("shared")
    add_includedirs("hashlink/src")
    add_files("hashlink/libs/ssl/*.c")
    add_packages("mbedtls")
    add_deps("hl")
    on_load(bind_flags(compile_flags, dynlib_link_flags))
    before_link(rename_hdll)

target("openal")
    set_kind("shared")
    add_includedirs("hashlink/src")
    add_files("hashlink/libs/openal/openal.c")
    add_packages("openal")
    add_deps("hl")
    on_load(bind_flags(compile_flags, dynlib_link_flags))
    before_link(rename_hdll)

target("sdl")
    set_kind("shared")
    add_includedirs("hashlink/src")
    add_files("hashlink/libs/sdl/sdl.c",
              "hashlink/libs/sdl/gl.c")
    add_packages("libsdl")
    add_deps("hl")
    add_shflags("-lGL")
    on_load(bind_flags(compile_flags, dynlib_link_flags))
    before_link(rename_hdll)
