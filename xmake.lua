-- This xmake.lua build file is designed as a replacement of
-- Makefile or CMakeLists.txt of standard hashlink releases.
--
-- The idea is to maximize the flexibility provided by xmake, that
-- 
-- a) In most desktop platforms, we use xmake, minimize per-compiler
--    settings
-- b) In Steam build Docker image, we use xmake generated Makefile.

-- Let's define a platform, steamrt. We allow it to build binaries with
-- Steam runtime.

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
add_requires("libsndio 1.9.0", { system = false })
add_requires("libjpeg-turbo 2.1.4", { system = false })
add_requires("libsdl 2.28.5", { system = false })
add_requires("libogg v1.3.4", { system = false })
add_requires("alsa-lib 1.2.10", { system = false })
add_requires("python 3.11.3", { system = false })

-- The following dependencies are required as platform must-have.
-- The criteria is based on Steam runtime but still keep a subset.
if is_plat("linux") or is_plat("steamrt") then
    add_requires("libx11", { system = true })
    add_requires("openal", { system = true })
    add_requires("openssl", { system = true })
    if is_plat("steamrt") then
        add_requires("libgl1-mesa-dev", { system = true })
        add_requires("libxcb1-dev", { system = true })
    else
        add_requires("libglvnd", { system = true })
        add_requires("libxcb", { system = true })
    end
end

-- 
-- TODO
--
-- I have to apply an external fix to build libsdl in Manjaro system,
-- that I need to create an /usr/include/X11/X11 symbolic link
-- pointing to /usr/include/X11. That means, we must allow access to
-- X11 headers in a path like /usr/include/X11/X11/Xext.h.
--
-- This is caused by libsdl/cmake/sdlchecks.cmake, that it searches system
-- folders to find X11 header files. However it does not include
-- /usr/include. For an unknown reason, it works for manual cmake
-- configuration but does not work when xmake builds libsdl from source
-- code as a dependency. A possile theory is xmake applies a more strict
-- search path limitation, which does not allow searching /usr/include.
--
-- If my theory is true, then it may not make sense to ask xmake fix it,
-- because X11 code are intended to be considered as an OS-level infra,
-- which I should never touch it myself.
--
-- Will check with xmake team for further diagnose.

-----------------------------------------------------------------
-- Utility functions
-----------------------------------------------------------------

function rename_hdll (target)
    target:set("filename", target:basename() .. ".hdll")
end

function binary_link_flags(target)
    if target:is_plat("linux") or is_plat("steamrt") then
        target:add("rpathdirs", "$ORIGIN")
        target:add("ldflags", "-lm")
        target:add("ldflags", "-static-libgcc")
        target:add("ldflags", "-static-libstdc++")
        target:add("ldflags", "-Wl,--export-dynamic")
        target:add("ldflags", "-Wl,--no-undefined")
    end
end

function dynlib_link_flags(target)
    if target:is_plat("linux") or is_plat("steamrt") then
        target:add("rpathdirs", "$ORIGIN")
        target:add("shflags", "-lm")
        target:add("shflags", "-static-libgcc")
        target:add("shflags", "-static-libstdc++")
        target:add("shflags", "-Wl,--export-dynamic")
        target:add("shflags", "-Wl,--no-undefined")

    end
end

function compile_flags(target)
    if target:is_plat("linux") or is_plat("steamrt") then
        -- Build location specific
        target:add("cflags", "-Ihashlink/src")
        target:add("defines", "LIBHL_EXPORTS")

        -- Build location independent settings
        target:add("cflags", "-Wall")
        target:add("cflags", "-O3")
        target:add("cflags", "-msse2")
        target:add("cflags", "-mfpmath=sse")
        target:add("cflags", "-std=c11")
        target:add("cxflags", "-fpic")
        target:add("cxflags", "-fno-omit-frame-pointer")
        target:add("cxflags", "-ftls-model=global-dynamic")
        target:add("cxflags", "-pthread")
    end
    -- for macOS
    -- target:add("defines", "GL_SILENCE_DEPRECATION")
    -- target:add("defines", "openal_soft")
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
target("libhl")
    set_kind("shared")
    set_basename("hl")
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
              "hashlink/include/pcre/pcre_exec.c",
              "hashlink/include/pcre/pcre_fullinfo.c",
              "hashlink/include/pcre/pcre_globals.c",
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
-- Main executable
-----------------------------------------------------------------
target("hl")
    set_kind("binary")
    add_includedirs("hashlink/src")
    add_ldflags("-ldl")
    add_files("hashlink/src/code.c",
              "hashlink/src/jit.c",
              "hashlink/src/main.c",
              "hashlink/src/module.c",
              "hashlink/src/debugger.c",
              "hashlink/src/profile.c")
    add_deps("libhl")
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
    add_deps("libhl")
    add_packages("mikktspace",
                 "zlib",
                 "minimp3", "libvorbis", "libogg",
                 "libpng", "libjpeg-turbo")
    on_load(bind_flags(compile_flags, dynlib_link_flags))
    before_link(rename_hdll)

-- For game development, there's no need to build libui. It's more for
-- developing portable desktop application.
-- target("ui")
--    set_kind("shared")
--    add_includedirs("hashlink/src")
--    add_files("hashlink/libs/ui/ui_stub.c")
--    add_packages("libui")
--    add_deps("libhl")
--    on_load(bind_flags(compile_flags, dynlib_link_flags))
--  before_link(rename_hdll)

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
    add_deps("libhl")
    on_load(bind_flags(compile_flags, dynlib_link_flags))
    before_link(rename_hdll)

target("ssl")
    set_kind("shared")
    add_includedirs("hashlink/src")
    add_files("hashlink/libs/ssl/*.c")
    add_packages("mbedtls")
    add_deps("libhl")
    on_load(bind_flags(compile_flags, dynlib_link_flags))
    before_link(rename_hdll)

target("openal")
    set_kind("shared")
    add_includedirs("hashlink/src")
    add_files("hashlink/libs/openal/openal.c")
    add_deps("libhl")
    add_packages("xmake::alsa-lib", "xmake::libsndio", "openal")
    on_load(bind_flags(compile_flags, dynlib_link_flags))
    before_link(rename_hdll)

target("sdl")
    set_kind("shared")
    add_includedirs("hashlink/src")
    add_files("hashlink/libs/sdl/sdl.c",
              "hashlink/libs/sdl/gl.c")
    add_deps("libhl")
    add_packages("libsdl", "libx11", "python", "openssl")
    if is_plat("steamrt") then
        add_requires("libgl1-mesa-dev", "libxcb1-dev)
    elseif is_plat("linux") then
        add_packages("libglvnd", "libxcb")
    end
    on_load(bind_flags(compile_flags, dynlib_link_flags))
    before_link(rename_hdll)

    -- Missing DLL
    -- libGLESv2 libGLX libOpenGL libxcb-dbe libxcb-xinput
