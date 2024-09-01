//
//  LibcpuinfoBuilder.swift
//  LibTensorflowLiteBuilder
//
//  Created by tinuv on 2024/8/31.
//


class LibcpuinfoBuilder: Builder {

    override func arguments(platform _: PlatformType, arch _: ArchType) -> [String] {
        [
            "-DCPUINFO_BUILD_BENCHMARKS=OFF",
        ]
    }

}
