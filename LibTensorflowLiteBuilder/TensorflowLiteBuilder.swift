//
//  TensorflowLiteBuilder.swift
//  LibTensorflowLiteBuilder
//
//  Created by tinuv on 2024/8/31.

//

import Foundation

class TensorflowLiteBuilder {
    static let workDirectory = "file:///Users/tinuv/Downloads/build1"
    static let buildDirectory = workDirectory + "/build"
    static let distDirectory = workDirectory + "/dist"
    static let patchDirector = workDirectory + "/patch"
    static let platforms = PlatformType.allCases.filter { ![.watchos, .watchsimulator, .android].contains($0) }

    func build() {
        let librayList = initLibrayList()
        for lib in librayList {
            lib.libBuilder.build()
        }
    }
}

extension TensorflowLiteBuilder {
    func initLibrayList() -> [Library] {
        var libraryList: [Library] = []
        // libraryList.append(.libAbseil)
        // libraryList.append(.libeigen)
        // libraryList.append(.libflatbuffers)
        // libraryList.append(.libNEON_2_SSE)
        // libraryList.append(.libcpuinfo)
        // libraryList.append(.libruy)
        // libraryList.append(.libpthreadpool)
        // libraryList.append(.libXNNPACK)
        libraryList.append(.libtensorflow)
        return libraryList
    }
}
