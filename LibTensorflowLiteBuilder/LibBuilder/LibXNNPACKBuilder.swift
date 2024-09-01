//
//  LibXNNPACKBuilder.swift
//  LibTensorflowLiteBuilder
//
//  Created by tinuv on 2024/8/31.
//

class LibXNNPACKBuilder: Builder {
    
    override func platforms() -> [PlatformType] {
        super.platforms().filter {
            ![.maccatalyst].contains($0)
        }
    }

    override func arguments(platform _: PlatformType, arch: ArchType) -> [String] {
        [
            "-DCMAKE_CXX_FLAGS=-Wno-error=unused-but-set-variable",
            "-DXNNPACK_BUILD_TESTS=OFF",
            "-DXNNPACK_BUILD_BENCHMARKS=OFF",
            "-DCMAKE_OSX_ARCHITECTURES=\(arch.rawValue)",
            "-DXNNPACK_USE_SYSTEM_LIBS=OFF",
        ]
    }
}
