# Libvpx CMake Conversion Summary & Plan

## Findings

1.  **Build Structure**:
    - The project relies on a complex system of recursive `.mk` files (Makefiles), starting from `libs.mk`.
    - Key component lists are found in `vpx_dsp/vpx_dsp.mk`, `vp8/vp8_common.mk`, `vp9/vp9_common.mk`, etc.
    - `configure` script generates `vpx_config.h` and `*.mk` files customized for the target.

2.  **Configuration (`vpx_config.h`)**:
    - This header is the central point of configuration. It contains `#define`s for architecture (X86, ARM, etc.), instruction sets (SSE, NEON), and features (VP8, VP9, POSTPROC).
    - We need to replicate this using CMake `option()` and `configure_file()`.

3.  **Runtime CPU Detection (RTCD)**:
    - `libvpx/build/make/rtcd.pl` is a Perl script used to generate headers (e.g., `vpx_dsp_rtcd.h`) that map function calls to optimized assembly/intrinsic versions at runtime.
    - CMake needs to invoke this script via `add_custom_command`.

4.  **Versioning**:
    - `libvpx/build/make/version.sh` extracts version info from Git or CHANGELOG to create `vpx_version.h`.
    - We can use a CMake custom command to run this script.

5.  **Sources**:
    - Sources are conditionally added in `.mk` files (e.g., `VP8_COMMON_SRCS-yes`, `VP8_COMMON_SRCS-$(HAVE_SSE2)`).
    - We need to translate these conditional lists into CMake conditional list appends.

## Plan

1.  **CMakeLists.txt Setup**:
    - Initialize project.
    - Define options (ENABLE_VP8, ENABLE_VP9, etc.) mimicking `vpx_config.h` defines.

2.  **Configuration Header**:
    - Create `vpx_config.h.in` template.
    - Use `configure_file` to generate `vpx_config.h` based on CMake options.

3.  **Source Parsing ("AI Slop" approach)**:
    - Instead of parsing `.mk` files at build time, I will read them now and manually (via "AI slop") transcribe the source lists into a new `sources.cmake` file.
    - This file will have logic like:
        ```cmake
        set(VPX_DSP_SRCS
            vpx_dsp/bitwriter.c
            ...
        )
        if(HAVE_SSE2)
            list(APPEND VPX_DSP_SRCS vpx_dsp/x86/bitdepth_conversion_sse2.h ...)
        endif()
        ```

4.  **RTCD Generation**:
    - Implement `vpx_rtcd` CMake function to wrap `rtcd.pl` calls.
    - Generate `vpx_dsp_rtcd.h`, `vpx_scale_rtcd.h`, etc.

5.  **Assembly Handling**:
    - Use CMake's `enable_language(ASM)` (usually with NASM/YASM for x86) to handle `.asm` files.
    - Ensure correct flags are passed to the assembler.

6.  **Target Definition**:
    - `add_library(vpx ${ALL_SOURCES})`.
    - Set include directories to `.` (build dir) and `libvpx` (source root).

7.  **Versioning**:
    - Add custom command to run `version.sh` and generate `vpx_version.h`.
