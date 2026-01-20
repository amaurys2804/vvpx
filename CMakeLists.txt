cmake_minimum_required(VERSION 3.21)
project(vpx VERSION 1.15.1 LANGUAGES C CXX)

# Options
option(BUILD_SHARED_LIBS "Build shared library" OFF)

# Platform detection
include(cmake/VpxConfig.cmake)

# Source lists
if(VPX_ARCH_ARM64)
    include(cmake/VpxSourcesArm.cmake)
else()
    include(cmake/VpxSources.cmake)
    include(cmake/VpxAssembly.cmake)
endif()

# Apply SIMD flags for specific files (GCC/Clang)
if(CMAKE_COMPILER_IS_GNUCC OR CMAKE_C_COMPILER_ID MATCHES "Clang")
    foreach(source_file ${VPX_C_SOURCES})
        if(source_file MATCHES "avx512")
             set_source_files_properties(${source_file} PROPERTIES COMPILE_OPTIONS "-mavx512f;-mavx512bw;-mavx512dq")
        elseif(source_file MATCHES "avx2")
             set_source_files_properties(${source_file} PROPERTIES COMPILE_OPTIONS "-mavx2")
        elseif(source_file MATCHES "avx")
             set_source_files_properties(${source_file} PROPERTIES COMPILE_OPTIONS "-mavx")
        elseif(source_file MATCHES "sse4")
             set_source_files_properties(${source_file} PROPERTIES COMPILE_OPTIONS "-msse4.1")
        elseif(source_file MATCHES "ssse3")
             set_source_files_properties(${source_file} PROPERTIES COMPILE_OPTIONS "-mssse3")
        endif()
    endforeach()
endif()

# Library target
add_library(vpx)

if(VPX_ARCH_ARM64)
    target_sources(vpx PRIVATE ${VPX_C_SOURCES_ARM})
else()
    target_sources(vpx PRIVATE ${VPX_C_SOURCES})
    if(NOT VPX_NO_ASM)
        target_sources(vpx PRIVATE ${VPX_X86_ASM_SOURCES})
    else()
        target_compile_definitions(vpx PRIVATE VPX_DISABLE_ASM)
    endif()
endif()

target_include_directories(vpx
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/config/${VPX_PLATFORM_DIR}>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/libvpx>
)

# Platform-specific settings
if(WIN32)
    target_compile_definitions(vpx PRIVATE _CRT_SECURE_NO_WARNINGS)
endif()

if(UNIX AND NOT APPLE)
    find_package(Threads REQUIRED)
    target_link_libraries(vpx PRIVATE Threads::Threads)
endif()

# Install rules
include(GNUInstallDirs)
install(TARGETS vpx
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/libvpx/vpx/
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/vpx
    FILES_MATCHING PATTERN "*.h"
)

# Test executable (only if this is the top-level project)
if(PROJECT_IS_TOP_LEVEL)
    add_executable(version_test test/version_test.c)
    target_link_libraries(version_test PRIVATE vpx)
endif()