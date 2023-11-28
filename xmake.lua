-- This xmake.lua build file is designed as a replacement of
-- Makefile or CMakeLists.txt of standard hashlink releases.


-- ===================================================================
-- Common dependendies
--
-- These dependencies are downloaded and built with hashlink. We don't
-- use any OS provided packages.
--
-- We apply different strategies on different Operating systems:
--
-- On Linux, we maintain all dependencies ourselves, as static
-- libraries. This is to make sure we eliminate any possible version
-- mismatching issue in libstdc++.so and libgcc_s.so. The only
-- exceptions are listed below:
--
-- 1. libsndio: No option to build as static library.
-- 2. libopenal: Though libopenal supports a static link option,
--    hashlink uses in a dynamic way: See definition of
--    openal.c!al_load_extensions(): all functions are loaded via
--    alGetProcAddress(). Thus a static build library causes link error.
-- 2. OpenGL - The "true" OpenGL. We depend on libglvnd to dispatch real
--    calls, and libglvnd depends on true libraries on OS.
--
-- [TBD] On macOS, we use minimal set of system Frameworks.
--
-- [TBD] On Windows, we maintain all dependencies ourselves, as static
-- libraries. This is because many dependencies are not installed by
-- default on Windows.
--
--
-- Details of OpenAL-soft issue
--
-- OpenAL-soft is also a C++ library. It suffers from the libstdc++.so
-- and libgcc_s.so version mismatching problem. Although we can maintain
-- our own openal-soft dynamically loaded library, it rely on the
-- libstdc++.so library on build machine. It can break our built binaries
-- when moving to another Linux distro.
--
-- As there's no reliable way to build a static library without
-- modifying hashlink code design. I have to leave this dependency to
-- Operating System.
--
-- As hashlink is indeed an MIT software, the legal risk should be fine.
-- Thus, I just build it as statically linked library.
--
-- ===================================================================
add_requires("mikktspace 2020.03.26", { system = false })
add_requires("libvorbis 1.3.7",       { system = false })
add_requires("libpng v1.6.40",        { system = false })
add_requires("minimp3 2021.05.29",    { system = false })
add_requires("sqlite3 3.43.0+200",    { system = false })
add_requires("mbedtls 2.28.3",        { system = false })
add_requires("libjpeg-turbo 2.1.4",   { system = false })
add_requires("libuv v1.46.0",         { system = false })
add_requires("libogg v1.3.4",         { system = false, configs = { shared = false }})
add_requires("zlib v1.3",             { system = false, configs = { shared = false }})
add_requires("libsdl 2.28.5",         { system = false })
add_requires("openal-soft 1.23.1",    { alias = "openal", system = false, configs = { shared = true } })

-- ===================================================================
-- OS-specific dependencies
--
-- The following dependencies are expected to be provided by Opearting
-- systems, as they directly rely on infrastructure provided by
-- Operating System. 
-- ===================================================================
if is_plat("linux") then
    add_requires("libglvnd 1.3.4",     { system = false })
    add_requires("alsa-lib 1.2.10",    { system = false })
    add_requires("libsndio 1.9.0",     { system = false })
    -- Notes for OpenAL on Linux
    -- We cannot ensure openal is installed in CI machine
    -- Thus we have to build it with our own package.
    -- When packaging the builds, we separate libopenal.so.* to
    -- different folders. This .so file is only used when system
    -- default libopenal.so does not work.
elseif is_plat("macosx") then
    add_frameworks("CoreFoundation", "Security", "OpenGL")
elseif is_plat("windows") then
end

--
-- NOTE for Arch/Manjaro
--
-- To build the project in Arch/Manjaro system, please add a
-- self-pointing symbolic link fir path /usr/include/X11:
--
-- ln -s /usr/include/X11 /usr/include/X11/X11.
--
-- This is to fix a bug in SDL2's cmake/sdlcheck.cmake. It hardcodes a
-- set of search path to find Xext.h. However it does not hardcodes
-- /usr/include, which is where Arch/Manjaro saves Xext.h.
--
-- NOTE for macos
-- Appears we need to make sure system installs glibtoolize binary via
-- ``brew install libtool``, in order to build libuv under macOS.
--

-- ===================================================================
-- Utility functions to define compile options.
-- ===================================================================

function binary_link_flags(target)
    if target:is_plat("linux") or target:is_plat("macosx") then
        target:add("ldflags", "-lm")
        if target:is_plat("linux") then
            target:add(ldflags, "-ldl")
            target:add("rpathdirs", "$ORIGIN")
            target:add("ldflags", "-Wl,--no-undefined")
            target:add("ldflags", "-static-libgcc")
            target:add("ldflags", "-static-libstdc++")
        end
    end
end

function dynlib_link_flags(target)
    if target:is_plat("linux") or target:is_plat("macosx") then
        target:add("shflags", "-lm")
        if target:is_plat("linux") then
            target:add("rpathdirs", "$ORIGIN")
            target:add("shflags", "-Wl,--export-dynamic")
            target:add("shflags", "-Wl,--no-undefined")
            target:add("shflags", "-static-libgcc")
            target:add("shflags", "-static-libstdc++")
        end
        if target:is_plat("macosx") then
            target:add("shflags", "-Wl,-export_dynamic")
        end
    end
end

function compile_flags(target)
    target:add("defines", "LIBHL_EXPORTS")
    if target:is_plat("linux") or target:is_plat("macosx") then
        -- Build location specific
        target:add("cflags", "-Ihashlink/src")
        target:add("defines", "openal_soft")

        -- Build location independent settings
        target:add("cflags", "-Wall")
        target:add("cflags", "-O3")
        target:add("cflags", "-msse2")
        target:add("cflags", "-mfpmath=sse")
        target:add("cflags", "-std=c11")
        target:add("cxflags", "-fpic")
        if target:is_plat("linux") then
            target:add("cxflags", "-pthread")
            target:add("cxflags", "-fno-omit-frame-pointer")
            target:add("cxflags", "-ftls-model=global-dynamic")
        end
        if target:is_plat("macosx") then
        end
    end
    if target:is_plat("windows") then
        target:add("defines", "_WINDOWS")
        target:add("defines", "UNICODE")
        target:add("defines", "_UNICODE")
        target:add("defines", "_USRDLL")
        -- for glext.h
        target:add("cflags", "-Ihashlink/include/gl")
    end
end

function copy_ci_fix(target)
    if target:is_plat("windows") then
        target:add("defines", "-Ici_fix/")
    end
end

-- This function is used to combine multiple actions on same xmake hook.
function chain_actions(...)
    local args = { ... }
    return function(target)
        for i, fun in ipairs(args) do
            fun(target)
        end
    end
end

-- ===================================================================
-- Project build settings
-- ===================================================================
target("libhl")
    set_kind("shared")
    if is_plat("windows") then
        -- Avoid naming conflict when building hl.lib: Both hl.exe and
        -- hl.dll will have same export library name.
        set_basename("libhl") 
    else
        set_basename("hl")
    end
    add_rules("utils.symbols.export_all")
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
    if is_plat("macosx") then
        add_includedirs("hashlink/include")
        add_files("hashlink/include/mdbg/mdbg.c",
                  "hashlink/include/mdbg/mach_excServer.c",
                  "hashlink/include/mdbg/mach_excUser.c")
    end
    if is_plat("windows") then
        add_links("user32", "ws2_32")
    end
    on_load(chain_actions(compile_flags, dynlib_link_flags))

-----------------------------------------------------------------
-- Main executable
-----------------------------------------------------------------
function copy_to_lib(target)
    local install_to = path.join(target:installdir(), "lib", target:filename())
    print("[customized] copy " .. target:filename() .. " to " .. install_to)
    os.cp(target:targetfile(), install_to)
end

target("hl")
    set_kind("binary")
    add_includedirs("hashlink/src")
    add_files("hashlink/src/code.c",
              "hashlink/src/jit.c",
              "hashlink/src/main.c",
              "hashlink/src/module.c",
              "hashlink/src/debugger.c",
              "hashlink/src/profile.c")
    add_deps("libhl")
    if is_plat("windows") then
        add_links("user32")
    end
    on_load(chain_actions(compile_flags, binary_link_flags))
    on_install(copy_to_lib)

-----------------------------------------------------------------
-- Below are Hashlink's built-in modules. Note that they also needs
-- haxelib install commands to get Haxe interface, in order to access
-- them.
-----------------------------------------------------------------
target("fmt")
    set_kind("shared")
    set_prefixname("")
    set_extension(".hdll")
    add_rules("utils.symbols.export_all")
    add_includedirs("hashlink/src")
    add_files("hashlink/libs/fmt/*.c")
    add_deps("libhl")
    add_packages("mikktspace",
                 "xmake::zlib",
                 "minimp3", "libvorbis", "xmake::libogg",
                 "libpng", "libjpeg-turbo")
    on_load(chain_actions(compile_flags, dynlib_link_flags))

target("ui")
    set_kind("shared")
    add_rules("utils.symbols.export_all")
    set_prefixname("")
    set_extension(".hdll")
    add_includedirs("hashlink/src")
    add_files("hashlink/libs/ui/ui_stub.c")
    add_deps("libhl")
    on_load(chain_actions(compile_flags, dynlib_link_flags))

target("uv")
    set_kind("shared")
    set_prefixname("")
    set_extension(".hdll")
    add_rules("utils.symbols.export_all")
    add_includedirs("hashlink/src")
    add_files("hashlink/libs/uv/*.c")
    add_packages("libuv")
    add_deps("hl")
    on_load(chain_actions(compile_flags, dynlib_link_flags))

target("sqlite")
    set_kind("shared")
    set_prefixname("")
    set_extension(".hdll")
    add_rules("utils.symbols.export_all")
    add_includedirs("hashlink/src")
    add_files("hashlink/libs/sqlite/*.c")
    add_packages("sqlite3")
    add_deps("libhl")
    on_load(chain_actions(compile_flags, dynlib_link_flags))

target("ssl")
    -- Building SSL on mbedtls on Windows is disabled due to a lack of
    -- correct approach to configure threading model.
    -- MbedTLS2.x supports only pthread threading, on Windows it
    -- requires we provide our own mbedtls_threading_mutex_t data
    -- structure and enabled MBEDTLS_THREADING_ALT macro. However, the
    -- macro must be defined in the config.h of mbedtls package. That
    -- means, the current xmake can't correctly configure Windows.
    --
    -- I need to think of a correct approach to solve it. Before I have
    -- a solution, let's disable "ssl" module for now.
    if is_plat("windows") then
        set_enabled(false)
    end
    set_kind("shared")
    set_prefixname("")
    set_extension(".hdll")
    add_rules("utils.symbols.export_all")
    add_includedirs("hashlink/src")
    add_files("hashlink/libs/ssl/ssl.c")
    add_packages("mbedtls")
    add_deps("libhl")
    if is_plat("windows") then
        add_links("crypt32")
    end
    on_load(chain_actions(compile_flags, dynlib_link_flags))

target("openal")
    set_kind("shared")
    set_prefixname("")
    set_extension(".hdll")
    add_rules("utils.symbols.export_all")
    add_includedirs("hashlink/src")
    add_files("hashlink/libs/openal/openal.c")
    add_deps("libhl")
    add_packages("openal", "alsa-lib", "libsndio")
    on_load(chain_actions(compile_flags, dynlib_link_flags))

target("sdl")
    set_kind("shared")
    set_prefixname("")
    set_extension(".hdll")
    add_rules("utils.symbols.export_all")
    -- Ci_fix folder contains only replaceable headers for CI use.
    add_includedirs("hashlink/src")
    if os.isdir("hashlink/ci_fix") then
        add_includedirs("hashlink/ci_fix")
    end
    add_files("hashlink/libs/sdl/sdl.c",
              "hashlink/libs/sdl/gl.c")
    add_deps("libhl")
    add_packages("libsdl")
    if is_plat("linux") then
        add_packages("libglvnd")
    end
    if is_plat("windows") then
        add_defines("SDL_EXPORTS")
        add_links("opengl32", "winmm")
    end
    on_load(chain_actions(copy_ci_fix, compile_flags, dynlib_link_flags))

