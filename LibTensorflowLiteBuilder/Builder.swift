//
//  Builder.swift
//  LibTensorflowLiteBuilder
//
//  Created by tinuv on 2024/8/31.
//

import Foundation

// 1. 获取源代码
// 2. 编辑源代码
// 3. 构造交叉编译环境
// 4. 编译

class Builder {
    let lib: Library
    var isFramework: Bool = true

    init(lib: Library) {
        self.lib = lib
    }

    func build() {
        obtainSource()
        preCompile()
        compile()
        postCompile()
        createXCFramework()
    }

    func platforms() -> [PlatformType] {
        TensorflowLiteBuilder.platforms
    }

    func obtainSource() {
        // 判断源代码文件夹是否存在
        // 没有源码则从仓库克隆对应的源代码
        if !FileManager.default.fileExists(atPath: lib.libSourceDirectory.path()) {
            var arguments = ["clone", "--recurse-submodules"]
            arguments.append(contentsOf: ["--branch", lib.libVersion, lib.libRepoURL, lib.libSourceDirectory.path()])
            try! Utility.launch(path: "/usr/bin/git", arguments: arguments)
            if lib == .libXNNPACK {
                try! Utility.launch(path: "/usr/bin/git", arguments: ["checkout", "e716e05befe59f2512f82432fb161ba1fea9969a"],currentDirectoryURL: lib.libSourceDirectory)
            }
        }
    }

    func preCompile() {
        /*
         let patch = TensorflowLiteBuilder.patchDirector + "\(lib.rawValue)"
         if FileManager.default.fileExists(atPath: patch.path) {
             _ = try? Utility.launch(path: "/usr/bin/git", arguments: ["stash"], currentDirectoryURL: lib.libSourceDirectory)
             let fileNames = try! FileManager.default.contentsOfDirectory(atPath: patch.path).sorted()
             for fileName in fileNames {
                 print(fileName)
                 _ = try? Utility.launch(path: "/usr/bin/git", arguments: ["apply", "\((patch + fileName).path)"], currentDirectoryURL: lib.libSourceDirectory)
             }
         }*/
    }

    func postCompile() {}

    func postBuild(platform _: PlatformType, arch _: ArchType) {
        /*
         if lib == .libtensorflow {
             let prefix = lib.thin(platform: platform, arch: arch)
             let buildURL = lib.scratch(platform: platform, arch: arch)
             let src = lib.libSourceDirectory + "tensorflow/lite/c/"
             _ = try? Utility.launch(path: "/bin/mkdir", arguments: ["-p","\((prefix).path())"], currentDirectoryURL: lib.libSourceDirectory)
             _ = try? Utility.launch(path: "/bin/mkdir", arguments: ["-p","\((prefix+"include").path())"], currentDirectoryURL: lib.libSourceDirectory)
             _ = try? Utility.launch(path: "/bin/mkdir", arguments: ["-p","\((prefix+"lib").path())"], currentDirectoryURL: lib.libSourceDirectory)
             _ = try? Utility.launch(path: "/bin/cp", arguments: ["\((buildURL+"tensorflow-lite/libtensorflow-lite.a").path())","\((prefix+"lib/libtensorflow.a").path())"], currentDirectoryURL: lib.libSourceDirectory)
             _ = try? Utility.launch(path: "/bin/cp", arguments: ["-r","\((src).path()+"/.")","\((prefix+"include").path())"], currentDirectoryURL: lib.libSourceDirectory)
         }*/
    }

    func compile() {
        for platform in platforms() {
            for arch in platform.architectures {
                let prefix = lib.thin(platform: platform, arch: arch)
                let buildURL = lib.scratch(platform: platform, arch: arch)
                if FileManager.default.fileExists(atPath: (prefix + "lib").path) {
                    continue
                }
                try? FileManager.default.removeItem(at: prefix)
                try? FileManager.default.removeItem(at: buildURL)
                do {
                    try FileManager.default.createDirectory(at: buildURL, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print("构建文件夹创建异常: \(error)\n")
                }
                do {
                    try doCompile(platform: platform, arch: arch, buildURL: buildURL)
                    postBuild(platform: platform, arch: arch)
                } catch {
                    print("编译异常: \(error)\n")
                    fatalError()
                }
            }
        }
    }

    func createXCFramework() {
        do {
            try doCreateXCFramework()
        } catch {
            print("创建 XCFramework 异常: \(error)")
        }
    }

    func frameworkExcludeHeaders(_: String) -> [String] {
        []
    }

    func wafPath() -> String {
        "waf"
    }

    func wafBuildArg() -> [String] {
        ["build"]
    }

    func wafInstallArg() -> [String] {
        []
    }

    // 交叉编译环境
    func environment(platform: PlatformType, arch: ArchType) -> [String: String] {
        let cFlags = cFlags(platform: platform, arch: arch).joined(separator: " ")
        let ldFlags = ldFlags(platform: platform, arch: arch).joined(separator: " ")
        let pkgConfigPath = platform.pkgConfigPath(arch: arch)
        let pkgConfigPathDefault = Utility.shell("pkg-config --variable pc_path pkg-config", isOutput: true)!
        let path = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:"
        return [
            "LC_CTYPE": "C",
            "CC": platform.cc,
            "CXX": platform.cc + "++",
            "CURRENT_ARCH": arch.rawValue,
            "CFLAGS": cFlags,
            "CXXFLAGS": cFlags,
            "LDFLAGS": ldFlags,
            "PKG_CONFIG_LIBDIR": pkgConfigPath + pkgConfigPathDefault,
            "PATH": path,
        ]
    }

    func cFlags(platform: PlatformType, arch: ArchType) -> [String] {
        var cFlags = platform.cFlags(arch: arch)
        let librarys = flagsDependencelibrarys()
        for library in librarys {
            let path = library.thin(platform: platform, arch: arch)
            if FileManager.default.fileExists(atPath: path.path) {
                cFlags.append("-I\(path.path)/include")
            }
        }
        return cFlags
    }

    func ldFlags(platform: PlatformType, arch: ArchType) -> [String] {
        var ldFlags = platform.ldFlags(arch: arch)
        let librarys = flagsDependencelibrarys()
        for library in librarys {
            if library == .libNEON_2_SSE {
                continue
            }
            if library == .libeigen || library == .libAbseil || library == .libruy {
                continue
            }
            let path = library.thin(platform: platform, arch: arch)
            if FileManager.default.fileExists(atPath: path.path) {
                var libname = library.rawValue
                if libname.hasPrefix("lib") {
                    libname = String(libname.dropFirst(3))
                }
                ldFlags.append("-L\(path.path)/lib")
                ldFlags.append("-l\(libname)")
            }
        }
        return ldFlags
    }

    func flagsDependencelibrarys() -> [Library] { [] }

    func arguments(platform _: PlatformType, arch _: ArchType) -> [String] { [] }

    func printCommd(arguments: [String], environment: [String: String], buildURL _: String) {
        var cmd = ""
        for (key, value) in environment {
            cmd += "\(key)=\"\(value)\" "
        }
        cmd += "\n"
        cmd += "cmake  \\\n"
        for arg in arguments {
            cmd += "\(arg) \\\n"
        }
        print("-----------------")
        print(cmd)
        print("-----------------")
    }

    func configure(buildURL: URL, env: [String: String], platform: PlatformType, arch: ArchType) throws {
        if lib == .libtensorflow {
            if Utility.shell("which cmake") == nil {
                Utility.shell("brew install cmake")
            }
            let cmake = Utility.shell("which cmake", isOutput: true)!
            let thinDirPath = lib.thin(platform: platform, arch: arch).path
            let makeLists = lib.libSourceDirectory + "tensorflow/lite/CMakeLists.txt"
            var arguments = [
                makeLists.path,
                "-DCMAKE_VERBOSE_MAKEFILE=0",
                "-DCMAKE_BUILD_TYPE=Release",
                "-DCMAKE_OSX_SYSROOT=\(platform.sdk.lowercased())",
                "-DCMAKE_OSX_ARCHITECTURES=\(arch.rawValue)",
                "-DCMAKE_INSTALL_PREFIX=\(thinDirPath)",
                "-DBUILD_SHARED_LIBS=0",
                "-DBUILD_TESTING=OFF",

                "-DTFLITE_ENABLE_INSTALL=ON",
                "-DCMAKE_FIND_PACKAGE_PREFER_CONFIG=ON",

                "-Dabsl_DIR=/Users/tinuv/Downloads/build1/build/libAbseil-build/\(platform.rawValue)/thin/\(arch.rawValue)/lib/cmake/absl",
                "-DEigen3_DIR=/Users/tinuv/Downloads/build1/build/libeigen-build/\(platform.rawValue)/thin/\(arch.rawValue)/share/eigen3/cmake",
                "-DFlatbuffers_DIR=/Users/tinuv/Downloads/build1/build/libflatbuffers-build/\(platform.rawValue)/thin/arm64/lib/cmake/flatbuffers",
                "-DNEON_2_SSE_DIR=/Users/tinuv/Downloads/build1/build/libNEON_2_SSE-build/\(platform.rawValue)/thin/\(arch.rawValue)/lib/cmake/NEON_2_SSE",
                "-Dcpuinfo_DIR=/Users/tinuv/Downloads/build1/build/libcpuinfo-build/\(platform.rawValue)/thin/\(arch.rawValue)/share/cpuinfo",
                "-Druy_DIR=/Users/tinuv/Downloads/build1/build/libruy-build/\(platform.rawValue)/thin/\(arch.rawValue)/lib/cmake/ruy",
                "-Dgemmlowp_DIR=/Users/tinuv/Downloads/build1/build/libgemmlowp-build/\(platform.rawValue)/thin/\(arch.rawValue)/lib/cmake/gemmlowp",
                "-Dpthreadpool_LIBRARY_DIR=/Users/tinuv/Downloads/build1/build/libpthreadpool-build/\(platform.rawValue)/thin/\(arch.rawValue)/lib",
                "-Dpthreadpool_INCLUDE_DIR=/Users/tinuv/Downloads/build1/build/libpthreadpool-build/\(platform.rawValue)/thin/\(arch.rawValue)/include",
                "-Dxnnpack_LIBRARY_DIR=/Users/tinuv/Downloads/build1/build/libXNNPACK-build/\(platform.rawValue)/thin/\(arch.rawValue)/lib",
                "-Dxnnpack_INCLUDE_DIR=/Users/tinuv/Downloads/build1/build/libXNNPACK-build/\(platform.rawValue)/thin/\(arch.rawValue)/include",
            ]
            printCommd(arguments: arguments, environment: env, buildURL: makeLists.path())
            arguments.append(contentsOf: self.arguments(platform: platform, arch: arch))
            try Utility.launch(path: cmake, arguments: arguments, currentDirectoryURL: buildURL, environment: env)
        }
        if lib == .libgemmlowp {
            if Utility.shell("which cmake") == nil {
                Utility.shell("brew install cmake")
            }
            let cmake = Utility.shell("which cmake", isOutput: true)!
            let thinDirPath = lib.thin(platform: platform, arch: arch).path
            let makeLists = lib.libSourceDirectory + "contrib/CMakeLists.txt"
            var arguments = [
                makeLists.path,
                "-DCMAKE_VERBOSE_MAKEFILE=0",
                "-DCMAKE_BUILD_TYPE=Release",
                "-DCMAKE_OSX_SYSROOT=\(platform.sdk.lowercased())",
                "-DCMAKE_OSX_ARCHITECTURES=\(arch.rawValue)",
                "-DCMAKE_INSTALL_PREFIX=\(thinDirPath)",
                "-DBUILD_SHARED_LIBS=0",
            ]
            printCommd(arguments: arguments, environment: env, buildURL: makeLists.path())
            arguments.append(contentsOf: self.arguments(platform: platform, arch: arch))
            try Utility.launch(path: cmake, arguments: arguments, currentDirectoryURL: buildURL, environment: env)
            return
        }
        let makeLists = lib.libSourceDirectory + "CMakeLists.txt"
        if FileManager.default.fileExists(atPath: makeLists.path) {
            if Utility.shell("which cmake") == nil {
                Utility.shell("brew install cmake")
            }
            let cmake = Utility.shell("which cmake", isOutput: true)!
            let thinDirPath = lib.thin(platform: platform, arch: arch).path
            var arguments = [
                makeLists.path,
                "-DCMAKE_VERBOSE_MAKEFILE=0",
                "-DCMAKE_BUILD_TYPE=Release",
                "-DCMAKE_OSX_SYSROOT=\(platform.sdk.lowercased())",
                "-DCMAKE_OSX_ARCHITECTURES=\(arch.rawValue)",
                "-DCMAKE_INSTALL_PREFIX=\(thinDirPath)",
                "-DBUILD_SHARED_LIBS=OFF",
            ]
            arguments.append(contentsOf: self.arguments(platform: platform, arch: arch))
            printCommd(arguments: arguments, environment: env, buildURL: makeLists.path())
            try Utility.launch(path: cmake, arguments: arguments, currentDirectoryURL: buildURL, environment: env)
        } else {
            let configure = lib.libSourceDirectory + "configure"
            if !FileManager.default.fileExists(atPath: configure.path) {
                var bootstrap = lib.libSourceDirectory + "bootstrap"
                if !FileManager.default.fileExists(atPath: bootstrap.path) {
                    bootstrap = lib.libSourceDirectory + ".bootstrap"
                }
                if FileManager.default.fileExists(atPath: bootstrap.path) {
                    try Utility.launch(executableURL: bootstrap, arguments: [], currentDirectoryURL: lib.libSourceDirectory, environment: env)
                } else {
                    let autogen = lib.libSourceDirectory + "autogen.sh"
                    if FileManager.default.fileExists(atPath: autogen.path) {
                        var env = env
                        env["NOCONFIGURE"] = "1"
                        try Utility.launch(executableURL: autogen, arguments: [], currentDirectoryURL: lib.libSourceDirectory, environment: env)
                    }
                }
            }
            try Utility.launch(executableURL: configure, arguments: arguments(platform: platform, arch: arch), currentDirectoryURL: buildURL, environment: env)
        }
    }

    func frameworks() -> [String] {
        [lib.rawValue]
    }
}

extension Builder {
    func doCompile(platform: PlatformType, arch: ArchType, buildURL: URL) throws {
        try? _ = Utility.launch(path: "/usr/bin/make", arguments: ["clean"], currentDirectoryURL: buildURL)
        try? _ = Utility.launch(path: "/usr/bin/make", arguments: ["distclean"], currentDirectoryURL: buildURL)
        let env = environment(platform: platform, arch: arch)

        if lib == .libtensorflow {
            try configure(buildURL: buildURL, env: env, platform: platform, arch: arch)
            // try Utility.launch(path: "/opt/homebrew/bin/cmake", arguments: ["--build", "."/*(lib.libSourceDirectory + "tensorflow/lite").path()*/ /* "--target", "install" */ ], currentDirectoryURL: buildURL, environment: env)
            try Utility.launch(path: "/usr/bin/make", arguments: ["-j8"], currentDirectoryURL: buildURL, environment: env)
            try Utility.launch(path: "/usr/bin/make", arguments: ["-j8", "install"], currentDirectoryURL: buildURL, environment: env)
        }

        if lib == .libgemmlowp {
            try configure(buildURL: buildURL, env: env, platform: platform, arch: arch)
            // try Utility.launch(path: "/opt/homebrew/bin/cmake", arguments: ["--build", "."/*(lib.libSourceDirectory + "tensorflow/lite").path()*/ /* "--target", "install" */ ], currentDirectoryURL: buildURL, environment: env)
            try Utility.launch(path: "/usr/bin/make", arguments: ["-j8"], currentDirectoryURL: buildURL, environment: env)
            try Utility.launch(path: "/usr/bin/make", arguments: ["-j8", "install"], currentDirectoryURL: buildURL, environment: env)
        }

        if FileManager.default.fileExists(atPath: (lib.libSourceDirectory + "meson.build").path) {
            if Utility.shell("which meson") == nil {
                Utility.shell("brew install meson")
            }
            let meson = Utility.shell("which meson", isOutput: true)!
            let crossFile = createMesonCrossFile(platform: platform, arch: arch)
            try Utility.launch(path: meson, arguments: ["setup", buildURL.path, "--cross-file=\(crossFile.path)"] + arguments(platform: platform, arch: arch), currentDirectoryURL: lib.libSourceDirectory, environment: env)
            try Utility.launch(path: meson, arguments: ["compile", "--clean"], currentDirectoryURL: buildURL, environment: env)
            try Utility.launch(path: meson, arguments: ["compile", "--verbose"], currentDirectoryURL: buildURL, environment: env)
            try Utility.launch(path: meson, arguments: ["install"], currentDirectoryURL: buildURL, environment: env)
        } else if FileManager.default.fileExists(atPath: (lib.libSourceDirectory + wafPath()).path) {
            let waf = (lib.libSourceDirectory + wafPath()).path
            try Utility.launch(path: waf, arguments: ["configure"] + arguments(platform: platform, arch: arch), currentDirectoryURL: lib.libSourceDirectory, environment: env)
            var arguments = [String]()
            arguments.append(contentsOf: wafBuildArg())
            try Utility.launch(path: waf, arguments: arguments, currentDirectoryURL: lib.libSourceDirectory, environment: env)
            arguments = ["install"]
            arguments.append(contentsOf: wafInstallArg())
            try Utility.launch(path: waf, arguments: arguments, currentDirectoryURL: lib.libSourceDirectory, environment: env)
            // } else if FileManager.default.fileExists(atPath: (lib.libSourceDirectory + "CMakeLists.txt").path()) {
            //    try configure(buildURL: buildURL, env: env, platform: platform, arch: arch)
            //    try Utility.launch(path: "/opt/homebrew/bin/cmake", arguments: ["--build", buildURL.path() /*"--target", "install"*/], currentDirectoryURL: buildURL, environment: env)
        } else {
            try configure(buildURL: buildURL, env: env, platform: platform, arch: arch)
            try Utility.launch(path: "/usr/bin/make", arguments: ["-j8"], currentDirectoryURL: buildURL, environment: env)
            try Utility.launch(path: "/usr/bin/make", arguments: ["-j8", "install"], currentDirectoryURL: buildURL, environment: env)
        }
    }

    private func createMesonCrossFile(platform: PlatformType, arch: ArchType) -> URL {
        let url = lib.scratch(platform: platform, arch: arch)
        let crossFile = url + "crossFile.meson"
        let prefix = lib.thin(platform: platform, arch: arch)
        let cFlags = cFlags(platform: platform, arch: arch).map {
            "'" + $0 + "'"
        }.joined(separator: ", ")
        let ldFlags = ldFlags(platform: platform, arch: arch).map {
            "'" + $0 + "'"
        }.joined(separator: ", ")
        let content = """
        [binaries]
        c = '/usr/bin/clang'
        cpp = '/usr/bin/clang++'
        objc = '/usr/bin/clang'
        objcpp = '/usr/bin/clang++'
        ar = '\(platform.xcrunFind(tool: "ar"))'
        strip = '\(platform.xcrunFind(tool: "strip"))'
        pkgconfig = 'pkg-config'

        [properties]
        has_function_printf = true
        has_function_hfkerhisadf = false

        [host_machine]
        system = 'darwin'
        subsystem = '\(platform.mesonSubSystem)'
        kernel = 'xnu'
        cpu_family = '\(arch.cpuFamily)'
        cpu = '\(arch.targetCpu)'
        endian = 'little'

        [built-in options]
        default_library = 'static'
        buildtype = 'release'
        prefix = '\(prefix.path)'
        c_args = [\(cFlags)]
        cpp_args = [\(cFlags)]
        objc_args = [\(cFlags)]
        objcpp_args = [\(cFlags)]
        c_link_args = [\(ldFlags)]
        cpp_link_args = [\(ldFlags)]
        objc_link_args = [\(ldFlags)]
        objcpp_link_args = [\(ldFlags)]
        """
        FileManager.default.createFile(atPath: crossFile.path, contents: content.data(using: .utf8), attributes: nil)
        return crossFile
    }

    private func doCreateXCFramework() throws {
        let frameworks = frameworks()
        for framework in frameworks {
            var arguments = ["-create-xcframework"]
            for platform in PlatformType.allCases {
                if !platforms().contains(platform) {
                    continue
                }
                if let frameworkPath = try createFramework(framework: framework, platform: platform) {
                    if isFramework {
                        arguments.append("-framework")
                        arguments.append(frameworkPath)
                    } else {
                        arguments.append("-library")
                        arguments.append(frameworkPath + "/" + framework + ".a")
                        arguments.append("-headers")
                        arguments.append(frameworkPath + "/Headers")
                    }
                }
            }
            arguments.append("-output")
            let XCFrameworkFile = lib.xcFramework(framework: framework)
            arguments.append(XCFrameworkFile.path)
            if FileManager.default.fileExists(atPath: XCFrameworkFile.path) {
                try FileManager.default.removeItem(at: XCFrameworkFile)
            }
            try Utility.launch(path: "/usr/bin/xcodebuild", arguments: arguments)
        }
    }

    private func createFramework(framework: String, platform: PlatformType) throws -> String? {
        let frameworkDir = lib.framework(platform: platform, framework: framework)
        if !platforms().contains(platform) {
            if FileManager.default.fileExists(atPath: frameworkDir.path) {
                return frameworkDir.path
            } else {
                return nil
            }
        }
        try? FileManager.default.removeItem(at: frameworkDir)
        try FileManager.default.createDirectory(at: frameworkDir, withIntermediateDirectories: true, attributes: nil)
        var arguments = ["-create"]
        for arch in platform.architectures {
            let prefix = lib.thin(platform: platform, arch: arch)
            if !FileManager.default.fileExists(atPath: prefix.path) {
                return nil
            }
            let libname = framework.hasPrefix("lib") || framework.hasPrefix("Lib") ? framework : "lib" + framework
            var libPath = prefix + ["lib", "\(libname).a"]
            print("---------------")
            print(libPath.path())
            print("---------------")
            if !FileManager.default.fileExists(atPath: libPath.path) {
                libPath = prefix + ["lib", "\(libname).dylib"]
            }
            arguments.append(libPath.path)
            var headerURL: URL = prefix + "include" + framework
            if !FileManager.default.fileExists(atPath: headerURL.path) {
                headerURL = prefix + "include"
            }
            try? FileManager.default.copyItem(at: headerURL, to: frameworkDir + "Headers")
        }
        arguments.append("-output")
        var output = (frameworkDir + framework).path
        if !isFramework {
            output += ".a"
        }
        arguments.append(output)
        try Utility.launch(path: "/usr/bin/lipo", arguments: arguments)
        try FileManager.default.createDirectory(at: frameworkDir + "Modules", withIntermediateDirectories: true, attributes: nil)
        var modulemap = """
        framework module \(framework) [system] {
            umbrella "."

        """
        for header in frameworkExcludeHeaders(framework) {
            modulemap += """
                exclude header "\(header).h"

            """
        }
        modulemap += """
            export *
        }
        """
        FileManager.default.createFile(atPath: frameworkDir.path + "/Modules/module.modulemap", contents: modulemap.data(using: .utf8), attributes: nil)
        createPlist(path: frameworkDir.path + "/Info.plist", name: framework, minVersion: platform.minVersion, platform: platform.sdk)
        return frameworkDir.path
    }

    private func createPlist(path: String, name: String, minVersion: String, platform: String) {
        let identifier = "com.kintan.ksplayer." + name
        let content = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
        <key>CFBundleDevelopmentRegion</key>
        <string>en</string>
        <key>CFBundleExecutable</key>
        <string>\(name)</string>
        <key>CFBundleIdentifier</key>
        <string>\(identifier)</string>
        <key>CFBundleInfoDictionaryVersion</key>
        <string>6.0</string>
        <key>CFBundleName</key>
        <string>\(name)</string>
        <key>CFBundlePackageType</key>
        <string>FMWK</string>
        <key>CFBundleShortVersionString</key>
        <string>87.88.520</string>
        <key>CFBundleVersion</key>
        <string>87.88.520</string>
        <key>CFBundleSignature</key>
        <string>????</string>
        <key>MinimumOSVersion</key>
        <string>\(minVersion)</string>
        <key>CFBundleSupportedPlatforms</key>
        <array>
        <string>\(platform)</string>
        </array>
        <key>NSPrincipalClass</key>
        <string></string>
        </dict>
        </plist>
        """
        FileManager.default.createFile(atPath: path, contents: content.data(using: .utf8), attributes: nil)
    }
}
