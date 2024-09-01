//
//  main.swift
//  LibTensorflowLiteBuilder
//
//  Created by tinuv on 2024/8/31.
//

import Foundation

// https://github.com/tensorflow/tensorflow/issues/57658

// todo : 1. 用代码实现文件内容替换：sed -i 's|NOT DEFINED PTHREADPOOL_SOURCE_DIR|FALSE|' CMakeLists.txt sed -i '/find_package(ruy REQUIRED)/a include(./pthreadpool.cmake)' CMakeLists.txt
// todo : 2. tools/cmake/modules/ml_dtypes/CMakeLists.txt 修改
//target_ include _directories(ml_dtypes INTERFACE
//＃ 修改以下内容
//"$<BUILD_INTERFACE: ${CMAKE_CURRENT_SOURCE_DIR}/ml_dtypes>"
//"$< INSTALL_INTERFACE: include/ml_dtypes>"
//)

TensorflowLiteBuilder().build()
