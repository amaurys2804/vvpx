# Vvpx

Unofficial CMake build wrapper for libvpx, the WebM VP8/VP9 SDK.

Uses [ShiftMediaProject's libvpx fork](https://github.com/ShiftMediaProject/libvpx) as a submodule, providing pre-configured source lists and RTCD headers.

## Why This Exists

libvpx's official build system uses a custom `configure` script and Makefiles. This project wraps it in CMake for easy integration into CMake-based projects.

## Supported Platforms

| Platform | Architecture | Compiler | SIMD Optimisations |
|----------|-------------|----------|-------------------|
| Windows | x64 | MSVC | SSE2/SSE3/SSSE3/SSE4.1/AVX/AVX2 via NASM |
| Linux | x64 | GCC/Clang | SSE2/SSE3/SSSE3/SSE4.1/AVX/AVX2 via NASM |
| macOS | ARM64 (Apple Silicon) | Clang | Generic C only |

### Not Supported

- **32-bit x86** - 64-bit only
- **macOS Intel** - Apple Silicon only
- **ARM Linux/Windows** - Untested, may work with generic C path

## Features

All VP8/VP9 codec features enabled:
- VP8 & VP9 encoder/decoder
- VP9 high bit depth (10/12-bit)
- Multithreading
- Postprocessing

## Quick Start

```bash
git clone --recursive https://github.com/user/vvpx
cd vvpx
cmake -B build
cmake --build build
```

### CMake Options

| Option | Default | Description |
|--------|---------|-------------|
| `BUILD_SHARED_LIBS` | `OFF` | Build shared library instead of static |

### Prerequisites

- CMake 3.21+
- NASM (Windows/Linux x64 for SIMD optimisations)
  - Windows: `choco install nasm`
  - Linux: `apt install nasm`
  - macOS ARM64: Not needed

## Usage

### As a Subdirectory

```cmake
add_subdirectory(vvpx)
target_link_libraries(your_app PRIVATE vpx)
```

### Include Paths

```c
#include "vpx/vpx_decoder.h"
#include "vpx/vp8dx.h"  // VP8 decoder interface
#include "vpx/vpx_encoder.h"
#include "vpx/vp8cx.h"  // VP8/VP9 encoder interface
```

## IVF Container Format

This build is designed for IVF container format (not WebM):
- Simple header + raw VP8/VP9 frames
- ffmpeg can output IVF: `ffmpeg -i input.mp4 -c:v libvpx-vp9 output.ivf`
- No WebM IO dependency required

## Project Structure

```
vvpx/
├── CMakeLists.txt           # Main build file
├── cmake/
│   ├── VpxSources.cmake     # x86_64 source list
│   ├── VpxSourcesArm.cmake  # ARM64 source list (generic C)
│   ├── VpxConfig.cmake      # Platform detection
│   └── VpxAssembly.cmake    # NASM/YASM setup
├── config/
│   ├── win_x64/             # Windows x64 headers
│   ├── linux_x64/           # Linux x64 headers
│   └── macos_arm64/         # macOS ARM64 headers (generic C RTCD)
├── scripts/
│   ├── extract_sources.py   # Extract sources from SMP
│   └── gen_rtcd_arm.py      # Generate ARM RTCD headers
├── test/
│   └── version_test.c       # Basic link test
└── libvpx/                  # Submodule (ShiftMediaProject)
```

## Future Work

### ARM NEON Optimisations

macOS ARM64 currently uses generic C implementations. Future improvement:
- Extract ARM NEON source lists from `.mk` files
- Generate proper ARM RTCD headers
- NEON intrinsics are in `.c` files (not assembly)

## Credits

- [libvpx](https://chromium.googlesource.com/webm/libvpx/) - The WebM Project
- [ShiftMediaProject](https://github.com/ShiftMediaProject/libvpx) - Pre-configured build files

## Licence

libvpx is BSD-licensed. See `libvpx/LICENSE` for details.
