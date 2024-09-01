//
//  Library.swift
//  LibTensorflowLiteBuilder
//
//  Created by tinuv on 2024/8/31.
//

import Foundation

enum Library: String, CaseIterable {
    case libeigen
    case libNEON_2_SSE
    case libAbseil
    case libflatbuffers
    case libcpuinfo
    case libruy
    case libpthreadpool
    case libXNNPACK
    case libgemmlowp
    case libtensorflow
}

extension Library {
    var libRepoURL: String {
        switch self {
            case .libeigen:
                "https://gitlab.com/libeigen/eigen"
            case .libNEON_2_SSE:
                "https://github.com/intel/ARM_NEON_2_x86_SSE"
            case .libAbseil:
                "https://github.com/abseil/abseil-cpp"
            case .libflatbuffers:
                "https://github.com/google/flatbuffers"
            case .libcpuinfo:
                "https://github.com/pytorch/cpuinfo"
            case .libruy:
                "https://github.com/google/ruy"
            case .libpthreadpool:
                "https://github.com/Maratyszcza/pthreadpool"
            case .libXNNPACK:
                "https://github.com/google/XNNPACK"
            case .libgemmlowp:
                "https://github.com/google/gemmlowp"
            case .libtensorflow:
                "https://github.com/tensorflow/tensorflow"
        }
    }

    var libVersion: String {
        switch self {
            case .libtensorflow:
                "v2.15.0"
            case .libeigen:
                "3.4.0"
            case .libNEON_2_SSE:
                "master"
            case .libAbseil:
                "20240722.0"
            case .libflatbuffers:
                "v23.5.26"
            case .libcpuinfo:
                "main"
            case .libruy:
                "master"
            case .libpthreadpool:
                "master"
            case .libXNNPACK:
                "master"
            case .libgemmlowp:
                "master"
        }
    }

    var libBuilder: Builder {
        switch self {
            case .libeigen:
                LibEigenBuilder(lib: self)
            case .libtensorflow:
                LibTensorflowBuilder(lib: self)
            case .libNEON_2_SSE:
                LibNEON_2_SSEBuilder(lib: self)
            case .libAbseil:
                LibAbseilBuilder(lib: self)
            case .libflatbuffers:
                LibFlatbuffersBuilder(lib: self)
            case .libcpuinfo:
                LibcpuinfoBuilder(lib: self)
            case .libruy:
                LibruyBuilder(lib: self)
            case .libpthreadpool:
                LibpthreadpoolBuilder(lib: self)
            case .libXNNPACK:
                LibXNNPACKBuilder(lib: self)
            case .libgemmlowp:
                LibGemmlowpBuilder(lib: self)
        }
    }

    var libSourceDirectory: URL {
        URL(string: TensorflowLiteBuilder.buildDirectory+"/\(self.rawValue)"+"-"+"source"+"-"+"\(self.libVersion)")!
    }

    func thin(platform: PlatformType, arch: ArchType) -> URL {
        URL(string: TensorflowLiteBuilder.buildDirectory+"/\(self.rawValue)-build"+"/\(platform.rawValue)"+"/thin"+"/\(arch.rawValue)")!
    }

    func scratch(platform: PlatformType, arch: ArchType) -> URL {
        URL(string: TensorflowLiteBuilder.buildDirectory+"/\(self.rawValue)-build"+"/\(platform.rawValue)"+"/scratch"+"/\(arch.rawValue)")!
    }

    func framework(platform: PlatformType, framework: String) -> URL {
        URL(string: TensorflowLiteBuilder.buildDirectory+"/\(self.rawValue)-frameworks"+"/\(platform.rawValue)"+"/\(framework).framework")!
    }

    func xcFramework(framework: String) -> URL {
        URL(string: TensorflowLiteBuilder.distDirectory+"/\(framework).xcframework")!
    }
}
