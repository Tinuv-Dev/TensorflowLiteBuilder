//
//  LibAbseilBuilder.swift
//  LibTensorflowLiteBuilder
//
//  Created by tinuv on 2024/8/31.
//

class LibAbseilBuilder: Builder {
    
    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        [
            "-DABSL_BUILD_TESTING=OFF",
            "-DABSL_USE_GOOGLETEST_HEAD=OFF",
            "-DCMAKE_CXX_STANDARD=14",
        ]
    }
    
}
