//
//  LibTensorflowBuilder.swift
//  LibTensorflowLiteBuilder
//
//  Created by tinuv on 2024/8/31.
//

import Foundation

class LibTensorflowBuilder: Builder {
    override func platforms() -> [PlatformType] {
        super.platforms().filter {
            ![.maccatalyst].contains($0)
        }
    }

    override func flagsDependencelibrarys() -> [Library] {
        [.libNEON_2_SSE, .libeigen, .libAbseil, .libflatbuffers, .libcpuinfo, .libruy, .libXNNPACK, .libpthreadpool]
    }

    override func preCompile() {
        super.preCompile()
        var arguments = ["/opt/homebrew/bin/pip3"]
        try! Utility.launch(path: "/bin/rm", arguments: arguments)
        arguments = ["/opt/homebrew/bin/python3"]
        try! Utility.launch(path: "/bin/rm", arguments: arguments)
        arguments = ["/opt/homebrew/bin/python3-config"]
        try! Utility.launch(path: "/bin/rm", arguments: arguments)

        arguments = ["-s", "/opt/homebrew/Cellar/python@3.8/3.8.19/bin/python3.8", "/opt/homebrew/bin/python3"]
        try! Utility.launch(path: "/bin/ln", arguments: arguments)
        arguments = ["-s", "/opt/homebrew/Cellar/python@3.8/3.8.19/bin/pip3.8", "/opt/homebrew/bin/pip3"]
        try! Utility.launch(path: "/bin/ln", arguments: arguments)
        arguments = ["-s", "/opt/homebrew/Cellar/python@3.8/3.8.19/bin/python3.8-config", "/opt/homebrew/bin/python3-config"]
        try! Utility.launch(path: "/bin/ln", arguments: arguments)
        
        //https://github.com/tensorflow/tensorflow/issues/57658
        /*
         sed -i 's|NOT DEFINED PTHREADPOOL_SOURCE_DIR|FALSE|' CMakeLists.txt
         sed -i '/find_package(ruy REQUIRED)/a include(./pthreadpool.cmake)' CMakeLists.txt
                                                                                                                                                                  
         cat > pthreadpool.cmake <<EOF
         add_library(pthreadpool STATIC IMPORTED)
         set_target_properties(pthreadpool PROPERTIES
         IMPORTED_LOCATION             "${pthreadpool_LIBRARY_DIR}/libpthreadpool.a"
         INTERFACE_INCLUDE_DIRECTORIES "${pthreadpool_INCLUDE_DIR}"
         )
         EOF
                                                                                                                                                                  
         cat > tools/cmake/modules/FindXNNPACK.cmake <<EOF
         add_library(xnnpack STATIC IMPORTED)
         set_target_properties(xnnpack PROPERTIES
         IMPORTED_LOCATION             "${xnnpack_LIBRARY_DIR}/libxnnpack.a"
         INTERFACE_INCLUDE_DIRECTORIES "${xnnpack_INCLUDE_DIR}"
         )
         EOF
         */
        //try! Utility.launch(path: "/usr/bin/sed", arguments: ["-i","","s|NOT DEFINED PTHREADPOOL_SOURCE_DIR|FALSE|",lib.libSourceDirectory.path()+"/tensorflow/lite/CMakeLists.txt"])
        //try! Utility.launch(path: "/usr/bin/sed", arguments: ["-i","","/find_package(ruy REQUIRED)/a\\\n include(./pthreadpool.cmake)",lib.libSourceDirectory.path()+"/tensorflow/lite/CMakeLists.txt"])
        let pthreadpooltext = """
        add_library(pthreadpool STATIC IMPORTED)
        set_target_properties(pthreadpool PROPERTIES
        IMPORTED_LOCATION             "${pthreadpool_LIBRARY_DIR}/libpthreadpool.a"
        INTERFACE_INCLUDE_DIRECTORIES "${pthreadpool_INCLUDE_DIR}"
        )
        """
        let xnnpacktext = """
        add_library(xnnpack STATIC IMPORTED)
        set_target_properties(xnnpack PROPERTIES
        IMPORTED_LOCATION             "${xnnpack_LIBRARY_DIR}/libxnnpack.a"
        INTERFACE_INCLUDE_DIRECTORIES "${xnnpack_INCLUDE_DIR}"         
        )
        """
        _ = writeToFile(filePath: (lib.libSourceDirectory+"/tensorflow/lite/pthreadpool.cmake").path(), content: pthreadpooltext)
        _ = writeToFile(filePath: (lib.libSourceDirectory+"/tensorflow/lite/tools/cmake/modules/FindXNNPACK.cmake").path(), content: xnnpacktext)
        //try! Utility.launch(path: "/bin/cat", arguments: [">","pthreadpool.cmake","<<EOF\n",pthreadpooltext],currentDirectoryURL: lib.libSourceDirectory+"/tensorflow/lite")
        //try! Utility.launch(path: "/bin/cat", arguments: [">",lib.libSourceDirectory.path()+"/tensorflow/lite/tools/cmake/modules/FindXNNPACK.cmake","<<EOF",xnnpacktext,"EOF"])
    }

    override func environment(platform: PlatformType, arch: ArchType) -> [String: String] {
        var env = super.environment(platform: platform, arch: arch)
        env["PYTHON_BIN_PATH"] = "/opt/homebrew/opt/python@3.8/bin/python3.8"
        env["PYTHON_LIB_PATH"] = "/opt/homebrew/Cellar/python@3.8/3.8.19/Frameworks/Python.framework/Versions/3.8/lib/python3.8/site-packages"
        env["TF_NEED_ROCM"] = "0"
        env["TF_NEED_CUDA"] = "0"
        env["CC_OPT_FLAGS"] = "-march=native -Wno-sign-compare"
        env["TF_SET_ANDROID_WORKSPACE"] = "0"
        env["TF_PYTHON_VERSION"] = "3.8"
        if platform == .ios {
            env["TF_CONFIGURE_IOS"] = "1"
        } else {
            env["TF_CONFIGURE_IOS"] = "0"
        }
        return env
    }
    
    func writeToFile(filePath: String, content: String) -> Bool {
        let fileManager = FileManager.default
        
        // 将字符串转换为 Data 对象
        guard let data = content.data(using: .utf8) else {
            print("无法将内容转换为 Data")
            return false
        }
        
        // 检查目录是否存在
        let directoryPath = (filePath as NSString).deletingLastPathComponent
        if !fileManager.fileExists(atPath: directoryPath) {
            do {
                try fileManager.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("无法创建目录: \(error.localizedDescription)")
                return false
            }
        }
        
        // 写入文件
        do {
            try data.write(to: URL(fileURLWithPath: filePath))
            return true
        } catch {
            print("写入文件失败: \(error.localizedDescription)")
            return false
        }
    }
}

