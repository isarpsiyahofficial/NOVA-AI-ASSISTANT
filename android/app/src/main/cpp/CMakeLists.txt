cmake_minimum_required(VERSION 3.22.1)

project("nova")

# Build-stable Nova native bridge.
# Real FAISS sources are kept in the tree for future/native experiments, but they are
# intentionally not compiled in the Android APK build. The Dart/Kotlin layer already
# treats the semantic native bridge as optional and falls back when native FAISS is not
# available. This avoids Android CI failures from desktop-oriented FAISS translation
# units while preserving the JNI symbols expected by Kotlin.

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(NOVA_CPP_DIR ${CMAKE_CURRENT_SOURCE_DIR})
set(NOVA_ENGINE_SOURCES
    ${NOVA_CPP_DIR}/nova_native_stub.cpp
    ${NOVA_CPP_DIR}/nova_faiss_bridge.cpp
    ${NOVA_CPP_DIR}/nova_openmp_android_stub.cpp
)

add_library(nova-lib SHARED ${NOVA_ENGINE_SOURCES})

target_compile_definitions(nova-lib PRIVATE
    NOVA_HAS_REAL_FAISS=0
)

target_include_directories(nova-lib PRIVATE
    ${NOVA_CPP_DIR}
)

find_library(log-lib log)

target_link_libraries(nova-lib PRIVATE ${log-lib} -latomic -lm)
