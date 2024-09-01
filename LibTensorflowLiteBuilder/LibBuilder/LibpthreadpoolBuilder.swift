//
//  LibpthreadpoolBuilder.swift
//  LibTensorflowLiteBuilder
//
//  Created by tinuv on 2024/8/31.
//

import Foundation

class LibpthreadpoolBuilder: Builder {
    override func platforms() -> [PlatformType] {
        super.platforms().filter {
            ![.maccatalyst].contains($0)
        }
    }
    


    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        var arguments = super.arguments(platform: platform, arch: arch)
        applyPatch()
        arguments.append(contentsOf:
            [
                
                "-DCMAKE_CXX_FLAGS=-Wno-error=unused-but-set-variable"
            ])
        return arguments
    }

    func applyPatch() {
        let patch = TensorflowLiteBuilder.patchDirector + "/\(lib.rawValue)"
        if let patchURL = URL(string: patch) {
            if FileManager.default.fileExists(atPath: patchURL.path()) {
                _ = try? Utility.launch(path: "/usr/bin/git", arguments: ["stash"], currentDirectoryURL: lib.libSourceDirectory)
                let fileNames = try! FileManager.default.contentsOfDirectory(atPath: patchURL.path()).sorted()
                for fileName in fileNames {
                    _ = try? Utility.launch(path: "/usr/bin/git", arguments: ["apply", "\(patchURL.path())/\(fileName)"], currentDirectoryURL: lib.libSourceDirectory)
                }
            }
        }
    }
    
    
}
