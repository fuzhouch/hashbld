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
add_requires("sqlite3 3.43.0+200", { system = false })
add_requires("mbedtls 2.28.3", { system = false })
add_requires("libjpeg-turbo 2.1.4", { system = false })
add_requires("libogg v1.3.4", { system = false })
add_requires("libuv v1.46.0", { system = false })

function is_steamrt()
    local value = os.getenv("steamrt")
    if value == nil then
        return false
    end
    return true
end

-- The following dependencies are required as platform must-have.
-- The criteria is based on Steam runtime but still keep a subset.
if is_plat("linux") then
    add_requires("openal", { system = true })
    add_requires("openssl", { system = true })
    if is_steamrt() then
        add_requires("apt::libsdl2-dev", { alias = "libsdl", system = true })
        add_requires("apt::libasound2-dev", { system = true })
        add_requires("apt::libgl1-mesa-dev", { system = true })
        add_requires("apt::libxcb1-dev", { system = true })
        add_requires("apt::libx11-dev", { system = true })
    else
        add_requires("libsdl 2.28.5", { system = false })
        add_requires("libglvnd", { system = true })
        add_requires("libxcb", { system = true })
        add_requires("libx11", { system = true })
    end
elseif is_plat("macos") then
    add_frameworks("CoreFoundation", "Security", "OpenGL", "OpenAL")
end

-- define toolchain for StreamRT
--
toolchain("steamrt-gcc9")
    set_kind("standalone")

    set_toolset("cc", "gcc-9")
    set_toolset("cxx", "gcc-9", "g++-9")
    set_toolset("ld", "g++-9", "gcc-9")
    set_toolset("sh", "g++-9", "gcc-9")
    set_toolset("ar", "ar")
    set_toolset("ex", "ar")
    set_toolset("strip", "strip")
    set_toolset("mm", "gcc-9")
    set_toolset("mxx", "gcc-9", "g++-9")
    set_toolset("as", "gcc-9")

    -- Due to uknown reason, SteamRT puts stdatomic.h in a different
    -- place instead of /usr/include. Let's add it manually.
    add_includedirs("steamrt/include", "/usr/lib/gcc-9/lib/gcc/x86_64-linux-gnu/9/include")
    add_cxflags("-std=gnu99")
    add_ldflags("-pthread")
    add_ldflags("-ldl")
    add_ldflags("-lrt")
    add_shflags("-pthread")
    add_shflags("-lrt")
toolchain_end()

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
--
-- TODO for macos
-- Appears we need to make sure system installs glibtoolize binary via
-- ``brew install libtool``, in order to build libuv under macOS.

-----------------------------------------------------------------
-- Utility functions
-----------------------------------------------------------------

function rename_hdll (target)
    target:set("filename", target:basename() .. ".hdll")
end

function binary_link_flags(target)
    if target:is_plat("linux") then
        target:add("rpathdirs", "$ORIGIN")
        target:add("ldflags", "-lm")
        target:add("ldflags", "-static-libgcc")
        target:add("ldflags", "-static-libstdc++")
        target:add("ldflags", "-Wl,--export-dynamic")
        target:add("ldflags", "-Wl,--no-undefined")
    elseif target:is_plat("macosx") then
        target:add("ldflags", "-isysroot $(xcrun --sdk macosx --show-sdk-path)")
    end
end

function dynlib_link_flags(target)
    if target:is_plat("linux") then
        target:add("rpathdirs", "$ORIGIN")
        target:add("shflags", "-lm")
        target:add("shflags", "-static-libgcc")
        target:add("shflags", "-static-libstdc++")
        target:add("shflags", "-Wl,--export-dynamic")
        target:add("shflags", "-Wl,--no-undefined")
    elseif target:is_plat("macosx") then
        target:add("ldflags", "-isysroot $(xcrun --sdk macosx --show-sdk-path)")
    end
end

function compile_flags(target)
    if target:is_plat("linux") then
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
    elseif target:is_plat("macosx") then
        target:add("cxflags", "-isysroot $(xcrun --sdk macosx --show-sdk-path)")
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
target("libhl")
    set_kind("shared")
    set_basename("hl")
    add_includedirs("hashlink/src", "hashlink/include/pcre")
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

target("ui")
    set_kind("shared")
    add_includedirs("hashlink/src")
    add_files("hashlink/libs/ui/ui_stub.c")
    add_deps("libhl")
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
    add_packages("openal")
    on_load(bind_flags(compile_flags, dynlib_link_flags))
    before_link(rename_hdll)

target("sdl")
    set_kind("shared")
    add_includedirs("hashlink/src")
    add_files("hashlink/libs/sdl/sdl.c",
              "hashlink/libs/sdl/gl.c")
    add_deps("libhl")
    add_packages("libsdl", "openssl")
    if is_plat("linux") then
        if is_steamrt() then
            add_packages("libgl1-mesa-dev", "libxcb1-dev", "libx11-dev")
        else
            add_packages("libglvnd", "libxcb", "libx11")
        end
    end
    on_load(bind_flags(compile_flags, dynlib_link_flags))
    before_link(rename_hdll)

    -- Missing DLL
    -- libGLESv2 libGLX libOpenGL libxcb-dbe libxcb-xinput
