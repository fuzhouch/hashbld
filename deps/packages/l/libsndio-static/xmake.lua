package("libsndio")
    set_homepage("https://sndio.org")
    set_description("Sndio static build - for Linux only")
    set_urls("https://sndio.org/sndio-$(version).tar.gz")

    add_versions("1.9.0", "f30826fc9c07e369d3924d5fcedf6a0a53c0df4ae1f5ab50fe9cf280540f699a")

    if is_plat("linux") then
        add_deps("alsa-lib")
    end

    on_install("linux", function (package)
        import("package.tools.autoconf")

        local f = io.open("libsndio/Makefile.in", "a")
        if f then
            f:write("libsndio-static.a: ${OBJS}\n")
            f:write("\t${AR} r libsndio-static.a ${OBJS}\n")

            f:write("installstatic: libsndio-static.a install\n")
            f:write("\tcp -R libsndio-static.a ${DESTDIR}${LIB_DIR}\n")
            f:close()
        else
            print("ERROR: Can't find libsndio/Makefile.in")
        end
        local r = io.open("Makefile.in", "a")
        if r then
            r:write("installstatic:\n")
            r:write("\tcd libsndio && ${MAKE} installstatic\n")
            r:close()
        end
        io.cat("libsndio/Makefile.in")

        local configs = {}
        local buildenvs = autoconf.buildenvs(package, {packagedeps = "alsa-lib"})
        autoconf.configure(package, configs, {envs = buildenvs})
        os.vrunv("make", {}, {envs = buildenvs})
        os.vrunv("make", {"install"}, {envs = buildenvs})
        os.vrunv("make", {"installstatic"}, {envs = buildenvs})
    end)

    on_test(function (package)
        assert(package:has_cfuncs("sio_open", {includes = "sndio.h"}))
    end)
package_end()


