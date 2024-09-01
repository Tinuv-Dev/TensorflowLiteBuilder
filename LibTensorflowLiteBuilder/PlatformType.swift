//
//  PlatformType.swift
//  LibTensorflowLiteBuilder
//
//  Created by tinuv on 2024/8/31.
//

//
//  PlatformType.swift
//  FFMPEGBuilder
//
//  Created by tinuv on 2024/4/30.
//

import Foundation
enum PlatformType: String, CaseIterable {
    case macos, ios, isimulator, tvos, tvsimulator, xros, xrsimulator, maccatalyst, watchos, watchsimulator, android
    var minVersion: String {
        switch self {
        case .ios,
             .isimulator:
            return "13.0"
        case .tvos,
             .tvsimulator:
            return "13.0"
        case .macos:
            return "10.15"
        case .maccatalyst:
            return "14.0"
        case .watchos,
             .watchsimulator:
            return "6.0"
        case .xros,
             .xrsimulator:
            return "1.0"
        case .android:
            return "24"
        }
    }

    var name: String {
        switch self {
        case .android,
             .ios,
             .macos,
             .tvos:
            return rawValue
        case .tvsimulator:
            return "tvossim"
        case .isimulator:
            return "iossim"
        case .maccatalyst:
            return "maccat"
        case .watchos:
            return "watchos"
        case .watchsimulator:
            return "watchossim"
        case .xros:
            return "visionos"
        case .xrsimulator:
            return "visionossim"
        }
    }

    var frameworkName: String {
        switch self {
        case .ios:
            return "ios-arm64"
        case .maccatalyst:
            return "ios-arm64_x86_64-maccatalyst"
        case .isimulator:
            return "ios-arm64_x86_64-simulator"
        case .macos:
            return "macos-arm64_x86_64"
        case .tvos:
            return "tvos-arm64_arm64e"
        case .tvsimulator:
            return "tvos-arm64_x86_64-simulator"
        case .watchos:
            return "watchos-arm64"
        case .watchsimulator:
            return "watchossim"
        case .xros:
            return "xros-arm64"
        case .xrsimulator:
            return "xros-arm64_x86_64-simulator"
        case .android:
            return "android"
        }
    }

    var architectures: [ArchType] {
        switch self {
        case .android,
             .ios,
             .watchos,
             .xros:
            return [.arm64]
        case .tvos:
            return [.arm64, .arm64e]
        case .isimulator,
             .tvsimulator,
             .watchsimulator:
            return [.arm64, .x86_64]
        case .xrsimulator:
            return [.arm64]
        case .macos:
            #if arch(x86_64)
            return [.x86_64, .arm64]
            #else
            return [.arm64, .x86_64]
            #endif
        case .maccatalyst:
            return [.arm64, .x86_64]
        }
    }

    var mesonSubSystem: String {
        switch self {
        case .isimulator:
            return "ios-simulator"
        case .tvsimulator:
            return "tvos-simulator"
        case .xrsimulator:
            return "xros-simulator"
        case .watchsimulator:
            return "watchos-simulator"
        default:
            return rawValue
        }
    }

    var cc: String {
        if self == .android {
            return androidToolchainPath + "/bin/aarch64-linux-android\(minVersion)-clang"
        } else {
            return "/usr/bin/clang"
        }
    }

    var androidToolchainPath: String {
        let root = ProcessInfo.processInfo.environment["ANDROID_NDK_HOME"] ?? ""
        // let toolchain = "darwin-arm64"
        let toolchain = "darwin-x86_64"
        let toolchainPath = "\(root)/toolchains/llvm/prebuilt/\(toolchain)"
        return toolchainPath
    }

    func host(arch: ArchType) -> String {
        switch self {
        case .macos:
            return "\(arch.targetCpu)-apple-darwin"
        case .ios,
             .tvos,
             .watchos,
             .xros:
            return "\(arch.targetCpu)-\(rawValue)-darwin"
        case .isimulator,
             .maccatalyst:
            return PlatformType.ios.host(arch: arch)
        case .tvsimulator:
            return PlatformType.tvos.host(arch: arch)
        case .watchsimulator:
            return PlatformType.watchos.host(arch: arch)
        case .xrsimulator:
            return PlatformType.xros.host(arch: arch)
        case .android:
            return "aarch64-linux-android"
        }
    }

    func deploymentTarget(arch: ArchType) -> String {
        switch self {
        case .ios,
             .macos,
             .tvos,
             .watchos,
             .xros:
            return "\(arch.targetCpu)-apple-\(rawValue)\(minVersion)"
        case .maccatalyst:
            return "\(arch.targetCpu)-apple-ios\(minVersion)-macabi"
        case .isimulator:
            return PlatformType.ios.deploymentTarget(arch: arch) + "-simulator"
        case .tvsimulator:
            return PlatformType.tvos.deploymentTarget(arch: arch) + "-simulator"
        case .watchsimulator:
            return PlatformType.watchos.deploymentTarget(arch: arch) + "-simulator"
        case .xrsimulator:
            return PlatformType.xros.deploymentTarget(arch: arch) + "-simulator"
        case .android:
            return ""
        }
    }

    private var osVersionMin: String {
        switch self {
        case .ios,
             .tvos,
             .watchos:
            return "-m\(rawValue)-version-min=\(minVersion)"
        case .macos:
            return "-mmacosx-version-min=\(minVersion)"
        case .isimulator:
            return "-mios-simulator-version-min=\(minVersion)"
        case .tvsimulator:
            return "-mtvos-simulator-version-min=\(minVersion)"
        case .watchsimulator:
            return "-mwatchos-simulator-version-min=\(minVersion)"
        case .android,
             .maccatalyst,
             .xros,
             .xrsimulator:
            return ""
        }
    }

    var sdk: String {
        switch self {
        case .ios:
            return "iPhoneOS"
        case .isimulator:
            return "iPhoneSimulator"
        case .tvos:
            return "AppleTVOS"
        case .tvsimulator:
            return "AppleTVSimulator"
        case .watchos:
            return "WatchOS"
        case .watchsimulator:
            return "WatchSimulator"
        case .xros:
            return "XROS"
        case .xrsimulator:
            return "XRSimulator"
        case .maccatalyst,
             .macos:
            return "MacOSX"
        case .android:
            return ""
        }
    }

    func ldFlags(arch: ArchType) -> [String] {
        let isysroot = isysroot
        var ldFlags = ["-arch", arch.rawValue, "-isysroot", isysroot, "-target", deploymentTarget(arch: arch)]
        if self == .maccatalyst {
            ldFlags.append("-iframework")
            ldFlags.append("\(isysroot)/System/iOSSupport/System/Library/Frameworks")
        }
        return ldFlags
    }

    func cFlags(arch: ArchType) -> [String] {
        var cflags = ldFlags(arch: arch)
        cflags.append(osVersionMin)
        cflags.append("-fno-common")
        return cflags
    }

    var isysroot: String {
        xcrunFind(tool: "--show-sdk-path")
    }

    func xcrunFind(tool: String) -> String {
        try! Utility.launch(path: "/usr/bin/xcrun", arguments: ["--sdk", sdk.lowercased(), "--find", tool], isOutput: true)
    }

    func pkgConfigPath(arch: ArchType) -> String {
        var pkgConfigPath = ""
        for lib in Library.allCases {
            let path = lib.thin(platform: self, arch: arch)
            if FileManager.default.fileExists(atPath: path.path) {
                pkgConfigPath += "\(path.path)/lib/pkgconfig:"
            }
        }
        return pkgConfigPath
    }
}

enum ArchType: String, CaseIterable {
    case arm64, x86_64, arm64e
    var executable: Bool {
        guard let architecture = Bundle.main.executableArchitectures?.first?.intValue else {
            return false
        }
        if architecture == 0x0100_000C, self == .arm64 || self == .arm64e {
            return true
        } else if architecture == NSBundleExecutableArchitectureX86_64, self == .x86_64 {
            return true
        }
        return false
    }

    var cpuFamily: String {
        switch self {
        case .arm64,
             .arm64e:
            return "aarch64"
        case .x86_64:
            return "x86_64"
        }
    }

    var targetCpu: String {
        switch self {
        case .arm64,
             .arm64e:
            return "arm64"
        case .x86_64:
            return "x86_64"
        }
    }
}
