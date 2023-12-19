-- This is a customized openal-soft package with the following build
-- options under Linux:
--
-- 1. Support only ASLA backend (no Sndio, PulseAudio, Pipewire, OSS, etc.)
-- 2. Statically link with -static-libgcc and -static-libstdc++.
-- 3. (comparing with official xrepo::openal-soft) Remove libsndio dependency.
-- 4. (comparing with official xrepo::openal-soft) Remove add_extsources().
-- 
-- When building under Windows or macOS, the behaviors are the same with
-- official xrepo::openal-soft.
--
package("openal-soft-alsa")
    set_homepage("https://openal-soft.org")
    set_description("OpenAL Soft is a software implementation of the OpenAL 3D audio API.")
    set_license("LGPL-2.0")

    add_urls("https://github.com/kcat/openal-soft/archive/refs/tags/$(version).tar.gz", {version = function (version)
        return version:ge("1.21.0") and version or "openal-soft-" .. version
    end})
    add_urls("https://github.com/kcat/openal-soft.git")

    add_versions("1.23.1", "dfddf3a1f61059853c625b7bb03de8433b455f2f79f89548cbcbd5edca3d4a4a")
    add_versions("1.22.2", "3e58f3d4458f5ee850039b1a6b4dac2343b3a5985a6a2e7ae2d143369c5b8135")
    add_versions("1.22.0", "814831a8013d7365dfd1917b27f1fb6e723f3be3fe1c6a7ff4516425d8392f68")
    add_versions("1.21.1", "8ac17e4e3b32c1af3d5508acfffb838640669b4274606b7892aa796ca9d7467f")

    add_deps("cmake")

    if is_plat("windows", "mingw") then
        add_syslinks("ole32", "shell32", "user32", "winmm", "kernel32")
    elseif is_plat("linux", "cross") then
        add_syslinks("dl", "pthread")
    elseif is_plat("android") then
        add_syslinks("dl", "OpenSLES")
    elseif is_plat("macosx", "iphoneos") then
        add_frameworks("CoreAudio", "CoreFoundation", "AudioToolbox")
    end

    on_load(function (package)
        if not package:config("shared") then
            package:add("defines", "AL_LIBTYPE_STATIC")
        end
    end)

    on_install("windows", "linux", "mingw", "macosx", "android", "iphoneos", "cross", function (package)
        if is_plat("linux") and linuxos.name() == "fedora" then
            -- https://github.com/kcat/openal-soft/issues/864
            io.replace("CMakeLists.txt", "if(HAVE_GCC_PROTECTED_VISIBILITY)", "if(0)", {plain = true})
        end
        local configs = {"-DALSOFT_EXAMPLES=OFF", "-DALSOFT_UTILS=OFF"}
        if package:config("shared") then
            table.insert(configs, "-DBUILD_SHARED_LIBS=ON")
            if is_plat("linux") then
                table.insert(configs, "-DALSOFT_BACKEND_PIPEWIRE=OFF")
                table.insert(configs, "-DALSOFT_BACKEND_PULSEAUDIO=OFF")
                table.insert(configs, "-DALSOFT_BACKEND_OSS=OFF")
                table.insert(configs, "-DALSOFT_BACKEND_SNDIO=OFF")
                table.insert(configs, "-DALSOFT_BACKEND_JACK=OFF")
                table.insert(configs, "-DALSOFT_BACKEND_PORTAUDIO=OFF")

                -- Enable only NULL, Wavefile and ALSA

                table.insert(configs, "-DALSOFT_STATIC_LIBGCC=ON")
                table.insert(configs, "-DALSOFT_STATIC_STDCXX=ON")
                io.replace("CMakeLists.txt", "set(LINKDER_FLAGS )", "set(LINKDER_FLAGS \"-static-libstdc++\")", {plain = true})
            end
            table.insert(configs, "-DLIBTYPE=SHARED")
        else
            table.insert(configs, "-DBUILD_SHARED_LIBS=OFF")
            table.insert(configs, "-DLIBTYPE=STATIC")
        end
        table.insert(configs, "-DCMAKE_BUILD_TYPE=" .. (package:debug() and "Debug" or "Release"))
        import("package.tools.cmake").install(package, configs)
    end)

    on_test(function (package)
        assert(package:has_cfuncs("alGetProcAddress", {includes = "AL/al.h"}))
    end)
