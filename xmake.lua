-- This xmake.lua build file is designed as a replacement of
-- Makefile or CMakeLists.txt of standard hashlink releases.

add_rules("mode.debug", "mode.release")

-- Windows: Override default /MT following official project settings.
if is_plat("windows") then
    set_runtimes("MD")
end

-- ===================================================================
-- Common dependendies
--
-- These dependencies are downloaded and built with hashlink. Our goal
-- is to make sure our built binaries can be copied and dropped to any
-- machines. Thus, our build don't use any OS provided dependencies.
--
-- We apply different strategies on different Operating systems:
--
-- Linux - 
-- We maintain all dependencies ourselves, as static libraries.
-- This is to make sure we eliminate any possible version
-- mismatching issue in libstdc++.so and libgcc_s.so. We also fixed some
-- issues as below:
--
-- 1. libsndio: Official build has only static library. We provide our
--    own xmake package.
-- 2. openal-soft: Hashlink has a trick https://github.com/HaxeFoundation/hashlink/issues/636
--    that requires shared link. I have applied a private fix.
--    EDITED 2023-12-19: By defining our own openal-soft-allinone
--    package, the dependency to libsndio is removed.
-- 3. OpenGL - We depend on libglvnd to dispatch real calls to system.
--    The graphics system can't be included.
--
-- [TBD] On macOS, we use minimal set of system Frameworks.
--
-- [TBD] On Windows, we maintain all dependencies ourselves, as static
-- libraries. This is because many dependencies are not installed by
-- default on Windows.
--
-- ===================================================================
add_repositories("local-repo deps")
add_requires("mikktspace 2020.03.26", { system = false })
add_requires("libvorbis 1.3.7",       { system = false })
add_requires("libpng v1.6.40",        { system = false })
add_requires("minimp3 2021.05.29",    { system = false })
add_requires("libjpeg-turbo 2.1.4",   { system = false })

add_requires("libuv v1.46.0",         { system = false })
add_requires("mbedtls 2.28.3",        { system = false })
add_requires("sqlite3 3.43.0+200",    { system = false })
add_requires("openal-soft-alsa 1.23.1", { alias = "openal", system = false, configs = { shared = true } })
add_requires("libsdl 2.28.5",         { system = false, configs = { shared = false, sdlmain = false } })

add_requireconfs("openal-soft-alsa.**", { system = false, configs = { shared = false } })
add_requireconfs("libvorbis.**",        { system = false, configs = { shared = false } })
add_requireconfs("libpng.**",           { system = false, configs = { shared = false } })

-- ===================================================================
-- OS-specific dependencies
--
-- The following dependencies are expected to be provided by Opearting
-- systems, as they directly rely on infrastructure provided by
-- Operating System. 
-- ===================================================================
if is_plat("linux") then
    add_requires("libglvnd 1.3.4",  { system = false })
elseif is_plat("macosx") then
    add_frameworks("CoreFoundation", "Security", "OpenGL")
elseif is_plat("windows") then
    -- No special requirements for now.
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

function libhl_link_flags(target)
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

    if target:is_plat("windows") then
        target:add("shflags", "/MANIFEST")
        target:add("shflags", "/manifest:embed")
        target:add("shflags", "/SUBSYSTEM:WINDOWS")
        target:add("shflags", "/TLBID:1")
        target:add("shflags", "/DYNAMICBASE:NO")
        target:add("shflags", "/NXCOMPAT:NO")
    end
end

function module_link_flags(target)
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

    if target:is_plat("windows") then
        target:add("shflags", "/MANIFEST")
        target:add("shflags", "/manifest:embed")
        target:add("shflags", "/SUBSYSTEM:WINDOWS")
        target:add("shflags", "/TLBID:1")
        target:add("shflags", "/DYNAMICBASE")
        target:add("shflags", "/NXCOMPAT")
    end
end

function compile_flags(target)
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
        target:add("defines", "_WINDLL")
        target:add("defines", "_USRDLL")
        target:add("defines", "UNICODE")
        target:add("defines", "_UNICODE")
        -- for glext.h
        target:add("includedirs", "hashlink/include/gl")

        target:add("cxflags", "/W3")
        target:add("cxflags", "/diagnostics:column")
        target:add("cxflags", "/Gm-")
        target:add("cxflags", "/EHsc")
        target:add("cxflags", "/fp:precise")
        target:add("cxflags", "/Zc:wchar_t")
        target:add("cxflags", "/Zc:forScope")
        target:add("cxflags", "/Zc:inline")
        target:add("cxflags", "/external:W3")
        target:add("cxflags", "/GS")
        target:add("cxflags", "/Gd")
    end
end

-- It's a utility function to combine multiple actions on same xmake hook.
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
    add_defines("LIBHL_EXPORTS")
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
    -- pcre2 can't be easily configured via xmake package because it
    -- requires a config.h file with a lot of configurations.
    add_defines("HAVE_CONFIG_H", "PCRE2_CODE_UNIT_WIDTH=16")
    add_files("hashlink/include/pcre/pcre2_auto_possess.c",
              "hashlink/include/pcre/pcre2_chartables.c",
              "hashlink/include/pcre/pcre2_compile.c",
	      "hashlink/include/pcre/pcre2_config.c",
              "hashlink/include/pcre/pcre2_context.c",
              "hashlink/include/pcre/pcre2_convert.c",
              "hashlink/include/pcre/pcre2_dfa_match.c",
              "hashlink/include/pcre/pcre2_error.c",
              "hashlink/include/pcre/pcre2_extuni.c",
              "hashlink/include/pcre/pcre2_find_bracket.c",
              "hashlink/include/pcre/pcre2_jit_compile.c",
              "hashlink/include/pcre/pcre2_maketables.c",
	      "hashlink/include/pcre/pcre2_match_data.c",
              "hashlink/include/pcre/pcre2_match.c",
              "hashlink/include/pcre/pcre2_newline.c",
	      "hashlink/include/pcre/pcre2_ord2utf.c",
              "hashlink/include/pcre/pcre2_pattern_info.c",
              "hashlink/include/pcre/pcre2_script_run.c",
              "hashlink/include/pcre/pcre2_serialize.c",
              "hashlink/include/pcre/pcre2_string_utils.c",
              "hashlink/include/pcre/pcre2_study.c",
              "hashlink/include/pcre/pcre2_substitute.c",
              "hashlink/include/pcre/pcre2_substring.c",
              "hashlink/include/pcre/pcre2_tables.c",
              "hashlink/include/pcre/pcre2_ucd.c",
              "hashlink/include/pcre/pcre2_valid_utf.c",
              "hashlink/include/pcre/pcre2_xclass.c")
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
    on_load(chain_actions(compile_flags, libhl_link_flags))

-----------------------------------------------------------------
-- Main executable
-----------------------------------------------------------------
function copy_to_lib(target)
    local install_to = path.join(target:installdir(), "lib", target:filename())
    print("[after install] copy " .. target:filename() .. " to " .. install_to)
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
    after_install(copy_to_lib)

-----------------------------------------------------------------
-- Below are Hashlink's built-in modules. Note that they also needs
-- haxelib install commands to get Haxe interface, in order to access
-- them.
-----------------------------------------------------------------
target("fmt")
    set_kind("shared")
    set_prefixname("")
    set_extension(".hdll")
    add_includedirs("hashlink/src")
    add_files("hashlink/libs/fmt/*.c")
    add_deps("libhl")
    add_packages("mikktspace", "minimp3", "libvorbis", "libpng", "libjpeg-turbo")
    on_load(chain_actions(compile_flags, module_link_flags))

target("ui")
    set_kind("shared")
    set_prefixname("")
    set_extension(".hdll")
    add_includedirs("hashlink/src")
    add_files("hashlink/libs/ui/ui_stub.c")
    add_deps("libhl")
    on_load(chain_actions(compile_flags, module_link_flags))

target("uv")
    set_kind("shared")
    set_prefixname("")
    set_extension(".hdll")
    add_includedirs("hashlink/src")
    add_files("hashlink/libs/uv/*.c")
    add_packages("libuv")
    add_deps("libhl")
    on_load(chain_actions(compile_flags, module_link_flags))

target("sqlite")
    set_kind("shared")
    set_prefixname("")
    set_extension(".hdll")
    add_includedirs("hashlink/src")
    add_files("hashlink/libs/sqlite/*.c")
    add_packages("sqlite3")
    add_deps("libhl")
    on_load(chain_actions(compile_flags, module_link_flags))

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
        add_links("crypt32")
    end
    set_kind("shared")
    set_prefixname("")
    set_extension(".hdll")
    add_includedirs("hashlink/src")
    add_files("hashlink/libs/ssl/ssl.c")
    add_packages("mbedtls")
    add_deps("libhl")
    on_load(chain_actions(compile_flags, module_link_flags))

target("openal")
    set_kind("shared")
    set_prefixname("")
    set_extension(".hdll")
    add_includedirs("hashlink/src")
    add_files("hashlink/libs/openal/openal.c")
    add_deps("libhl")
    add_packages("openal")
    on_load(chain_actions(compile_flags, module_link_flags))

target("sdl")
    set_kind("shared")
    set_prefixname("")
    set_extension(".hdll")
    add_includedirs("hashlink/src")
    if os.isdir("hashlink/ci_fix") then
        -- Ci_fix folder contains only replaceable headers for CI use.
        -- Please do not include $ProjectRoot/ci_fix directly. In Linux
        -- it may cause xmake stuck. The copy of ci_fix here is done by
        -- CI.
        add_includedirs("hashlink/ci_fix")
    end
    add_files("hashlink/libs/sdl/sdl.c",
              "hashlink/libs/sdl/gl.c")
    add_deps("libhl")
    add_packages("libsdl")
    if is_plat("linux") then
        add_packages("libglvnd")
    elseif is_plat("windows") then
        add_defines("SDL_EXPORTS")
        add_links("opengl32", "winmm", "user32")
    end
    on_load(chain_actions(compile_flags, module_link_flags))
