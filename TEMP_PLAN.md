# Libvpx CMake Conversion Implementation Plan

## 1. Overview
Convert libvpx's Makefile-based build system to CMake while preserving:
- All functionality (VP8/VP9 encoding/decoding)
- CPU feature detection and optimized assembly paths
- Cross-platform support for Linux x86_64, Windows x64, macOS ARM64
- RTCD (Runtime CPU Detection) system

**Target Platforms**: Linux x86_64 (primary), Windows x64, macOS ARM64
**Total Source Files**: ~747 files across 12 core components

## 2. Architecture Decisions

### 2.1 Source List Generation Strategy
**Approach**: Python syntax converter (text-based translation)
- Convert Makefile patterns to CMake conditionals
- Flatten nested includes for simplicity
- Output literals instead of tracking variable expansions
- Fail on unknown syntax (strict parsing)

**Component Organization**: Separate `sources_*.cmake` files per component:
- `sources_vpx.cmake` (API)
- `sources_vpx_mem.cmake`
- `sources_vpx_scale.cmake`
- `sources_vpx_ports.cmake`
- `sources_vpx_dsp.cmake`
- `sources_vpx_util.cmake`
- `sources_vp8_common.cmake`
- `sources_vp8cx.cmake` (encoder)
- `sources_vp8dx.cmake` (decoder)
- `sources_vp9_common.cmake`
- `sources_vp9cx.cmake` (encoder)
- `sources_vp9dx.cmake` (decoder)

### 2.2 Assembly File Handling
**Dual Assembly System**:
- **x86**: `.asm` files require NASM/YASM
- **ARM**: `.S` files use GNU assembler

**CMake Configuration**:
```cmake
# For x86 NASM/YASM
enable_language(ASM_NASM)
set(CMAKE_ASM_NASM_FLAGS "-f ${CMAKE_ASM_NASM_OBJECT_FORMAT}")

# For ARM .S files
enable_language(ASM)

# Replicate ASM variable logic from libs.mk:15
if(VPX_ARCH_ARM AND (CONFIG_GCC OR CONFIG_MSVS))
    set(ASM_SUFFIX ".asm.S")
else()
    set(ASM_SUFFIX ".asm")
endif()
```

### 2.3 RTCD (Runtime CPU Detection) System
**Strategy**: Generate `config.mk` from CMake, reuse existing `rtcd.pl`
- Create `config.mk.in` template with CMake variables
- Use `configure_file()` to generate `config.mk` at build time
- Call `rtcd.pl` with generated `config.mk` as input
- Generate RTCD headers (`vpx_dsp_rtcd.h`, `vpx_scale_rtcd.h`, etc.)

## 3. Parser Design (`parse_mk_to_cmake.py`)

### 3.1 Input/Output
**Input**: `.mk` files from `libvpx/`
**Output**: `sources_*.cmake` files in project root

### 3.2 Translation Rules
```
# Makefile pattern                 → CMake pattern
ifeq ($(VAR),yes)                 → if(VAR)
ifneq ($(VAR),yes)                → if(NOT VAR)
else                             → else()
endif                            → endif()

VAR-yes += file.c                → list(APPEND VAR file.c)
VAR-$(HAVE_SSE2) += x86/file.asm → if(HAVE_SSE2)\n    list(APPEND VAR x86/file.asm)\nendif()

$(call enabled, VAR)             → ${VAR} (post-processing filter-out)
filter-out pattern list          → Implement CMake function _filter_out()
```

### 3.3 Special Cases to Handle
- `addprefix vpx/, $(call enabled, API_SRCS)` → Flatten to literal paths
- `ASM` variable substitution → Replace `$(ASM)` with `${ASM_SUFFIX}`
- `ASM_INCLUDES` filtering → Skip certain assembly includes
- `filter-out $(VPX_CX_SRCS_REMOVE-yes), $(VPX_CX_SRCS-yes)` → Post-processing step

### 3.4 Parser Limitations
- Does not evaluate complex Make expressions
- Requires manual fixup for edge cases (~20-30% of cases)
- Outputs warnings for unhandled syntax

## 4. CMake Component Design

### 4.1 Main CMakeLists.txt Structure
```cmake
cmake_minimum_required(VERSION 3.21)
project(vpx C CXX ASM ASM_NASM)

# Configuration options
option(ENABLE_VP8 "Enable VP8 codec" ON)
option(ENABLE_VP9 "Enable VP9 codec" ON)
option(ENABLE_VP9_HIGHBITDEPTH "Enable VP9 high bit depth" ON)
option(CONFIG_MULTITHREAD "Enable multithreading" ON)
# ... 50+ CONFIG_* options matching vpx_config.h

# CPU feature detection
include(cmake/DetectCPU.cmake)

# Generate vpx_config.h from template
configure_file(vpx_config.h.in vpx_config.h @ONLY)

# Generate config.mk for rtcd.pl
configure_file(config.mk.in config.mk @ONLY)

# Include source lists
include(sources.cmake)

# Library target
add_library(vpx ${ALL_SOURCES})
target_include_directories(vpx PUBLIC 
    ${CMAKE_CURRENT_BINARY_DIR}  # for vpx_config.h
    libvpx                       # source headers
)

# RTCD generation custom commands
add_custom_command(...)  # for rtcd.pl
add_custom_command(...)  # for version.sh
```

### 4.2 CPU Feature Detection (`cmake/DetectCPU.cmake`)
**For x86_64**:
- SSE2: Always enabled (mandatory for x86_64)
- SSE3/SSSE3/SSE4.1/AVX/AVX2/AVX512: Detect via `CheckCXXSourceCompiles`
- Set corresponding `HAVE_*` variables

**For ARM64**:
- NEON: Always enabled on Apple Silicon
- NEON_DOTPROD/NEON_I8MM: Detect via compiler flags
- SVE/SVE2: Detect for future ARMv9

**Cross-compilation**: Allow manual override of all `HAVE_*` flags.

### 4.3 CMake Helper Functions (`cmake/helpers.cmake`)
```cmake
# Replicate Makefile functions
function(_enabled var_name out_var)
    # Implements filter-out($(${var_name}-no), $(${var_name}-yes))
    set(result ${${var_name}_YES})
    foreach(item ${${var_name}_NO})
        list(REMOVE_ITEM result ${item})
    endforeach()
    set(${out_var} ${result} PARENT_SCOPE)
endfunction()

function(_addprefix prefix in_list out_var)
    set(result)
    foreach(item ${in_list})
        list(APPEND result "${prefix}${item}")
    endforeach()
    set(${out_var} ${result} PARENT_SCOPE)
endfunction()
```

## 5. Build Process Steps

### 5.1 Initial Setup
1. Generate `sources_*.cmake` files via Python parser
2. Create main `CMakeLists.txt` with project definition
3. Implement CPU detection module
4. Create `vpx_config.h.in` template
5. Create `config.mk.in` template

### 5.2 Build Sequence
```
CMake configure
    ↓
Generate vpx_config.h
    ↓
Generate config.mk
    ↓
Run rtcd.pl → Generate RTCD headers
    ↓
Run version.sh → Generate vpx_version.h
    ↓
Compile library with conditional sources
```

### 5.3 Source Inclusion Flow
```
sources.cmake (master file)
    ├── sources_vpx.cmake
    ├── sources_vpx_dsp.cmake
    ├── ...
    └── sources_vp9dx.cmake

Each sources_*.cmake:
    set(COMPONENT_SRCS ...)
    if(CONDITION)
        list(APPEND COMPONENT_SRCS ...)
    endif()
```

## 6. Testing Strategy

### 6.1 Immediate (Ubuntu Linux x86_64)
1. **Parser test**: Generate CMake files, verify syntax
2. **CMake configure**: Test option parsing and CPU detection
3. **Build test**: Compile library with default settings
4. **Function test**: Simple link test with minimal program

### 6.2 Subsequent (Manual Transfer)
**Windows x64**:
- Test MinGW and MSVC toolchains
- Verify NASM/YASM integration
- Check runtime CPU detection

**macOS ARM64**:
- Test NEON detection
- Verify ARM assembly compilation
- Check universal binary support

### 6.3 Validation Criteria
- Library compiles without errors
- All CONFIG_* options work as expected
- CPU feature detection sets correct HAVE_* flags
- RTCD headers generated correctly
- Version information embedded properly

## 7. Implementation Phases

### Phase 1: Foundation (Current Session)
- Write Python parser (`parse_mk_to_cmake.py`)
- Generate initial `sources_*.cmake` files
- Create main `CMakeLists.txt` skeleton
- Implement basic CPU detection for x86_64

### Phase 2: Configuration System
- Create `vpx_config.h.in` template
- Create `config.mk.in` template
- Implement RTCD custom command
- Implement version generation

### Phase 3: Assembly Integration
- Configure NASM/YASM for x86
- Configure GNU AS for ARM
- Handle ASM variable substitution
- Test assembly compilation

### Phase 4: Polish & Cross-platform
- Test on Linux x86_64
- Document build process
- Prepare for Windows/macOS transfer
- Create troubleshooting guide

## 8. Risk Mitigation

### High Risk Areas
1. **Assembly file handling**: Different syntax/tools per platform
2. **RTCD system**: Complex Perl script dependencies
3. **Makefile edge cases**: Unusual syntax patterns

### Mitigation Strategies
1. **Incremental implementation**: Test each component independently
2. **Fallback options**: Provide "generic only" build mode
3. **Manual overrides**: Allow disabling problematic features
4. **Extensive logging**: Capture parser decisions for debugging

## 9. Success Metrics

### Primary (Must have)
- Library builds on Linux x86_64 with all optimizations
- CONFIG_VP8, CONFIG_VP9, CONFIG_VP9_HIGHBITDEPTH work
- CPU feature detection functional
- RTCD system operational

### Secondary (Should have)
- Cross-compilation support
- Install target working
- pkg-config file generation
- Static and shared library variants

### Tertiary (Nice to have)
- Windows/MSVC support
- macOS universal binaries
- Test suite integration
- Packaging support (DEB, RPM)

## 10. Next Actions

### Immediate (User to perform after reviewing plan)
1. Review and approve this plan
2. Provide feedback on any missing components
3. Decide on parser implementation details

### Upon Approval
1. Implement Phase 1 components
2. Test parser on Ubuntu Linux
3. Iterate based on results

---
*Last updated: $(date)*
*Based on analysis of libvpx v1.15.1 from ShiftMediaProject*
*Target CMake version: 3.21+*