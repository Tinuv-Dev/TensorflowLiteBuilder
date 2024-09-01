//
//  LibGemmlowpBuilder.swift
//  LibTensorflowLiteBuilder
//
//  Created by tinuv on 2024/8/31.
//

class LibGemmlowpBuilder: Builder {

    override func arguments(platform _: PlatformType, arch _: ArchType) -> [String] {
        [
            "-DBUILD_TESTING=OFF"
        ]
    }
}
