//
//  LibFlatbuffersBuilder.swift
//  LibTensorflowLiteBuilder
//
//  Created by tinuv on 2024/8/31.
//

class LibFlatbuffersBuilder: Builder {

    override func arguments(platform _: PlatformType, arch _: ArchType) -> [String] {
        [
            "-DFLATBUFFERS_BUILD_TESTS=OFF",
        ]
    }
}
