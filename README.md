# Vvpx - CMake Build Wrapper for libvpx

[![build](https://github.com/hypernewbie/vvpx/actions/workflows/build.yml/badge.svg)](https://github.com/hypernewbie/vvpx/actions/workflows/build.yml)

AI slop CMake build wrapper for libvpx, the WebM VP8/VP9 SDK.

Uses [ShiftMediaProject's libvpx fork](https://github.com/ShiftMediaProject/libvpx) as a submodule, providing pre-configured source lists and RTCD headers.

> WARNING: AI slop head. Don't use this. It's a mess. May be really buggy.

## Why This Exists

libvpx's official build system uses a custom `configure` script and Makefiles. This project wraps it in CMake for easy integration into CMake-based projects.

## Supported Platforms

| Platform | Architecture | Compiler | SIMD Optimisations |
|----------|-------------|----------|-------------------|
| Windows | x64 | MSVC | SSE2/SSE3/SSSE3/SSE4.1/AVX/AVX2 via NASM |
| Linux | x64 | GCC/Clang | SSE2/SSE3/SSSE3/SSE4.1/AVX/AVX2 via NASM |
| macOS | ARM64 (Apple Silicon) | Clang | ARM NEON intrinsics |

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

### Windows

NASM is bundled - just build:

```bash
git clone --recursive https://github.com/hypernewbie/vvpx
cd vvpx
cmake -B build
cmake --build build --config Release
```

### Linux / macOS

Ninja is recommended for faster builds:

```bash
# Install NASM (Linux only, not needed on macOS ARM)
sudo apt install nasm  # Debian/Ubuntu
# or: sudo dnf install nasm  # Fedora

git clone --recursive https://github.com/hypernewbie/vvpx
cd vvpx
cmake -B build -G Ninja
ninja -C build
```

Make also works: `cmake -B build && make -C build -j$(nproc)`

### CMake Options

| Option | Default | Description |
|--------|---------|-------------|
| `BUILD_SHARED_LIBS` | `OFF` | Build shared library instead of static |

### Prerequisites

- CMake 3.21+
- **Windows**: NASM included in `tools/` (no install needed)
- **Linux**: `apt install nasm` or `dnf install nasm`
- **macOS ARM64**: No NASM needed (uses generic C)

### Build Modes

| NASM Available | Sources | SIMD | Performance |
|----------------|---------|------|-------------|
| ✅ Yes (x86_64) | 234 C + 49 ASM | Full SSE2/AVX/AVX2 | Fast |
| ❌ No (x86_64) | 166 C (generic) | None | Slower |
| N/A (ARM64) | 166 C + 95 SIMD | ARM NEON | Fast |

### Caveats (No NASM)

When building without NASM on x86_64:
- The library uses generic C fallbacks (same as ARM)
- `version_test` works (confirms library builds correctly)
- `decode_test` is not built (libvpx RTCD has internal SIMD dependencies)
- For full decode functionality, install NASM

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

## Testing

Tests use the IVF container format:
- Simple header + raw VP8/VP9 frames
- ffmpeg can output IVF: `ffmpeg -i input.mp4 -c:v libvpx-vp9 output.ivf`
- No WebM IO dependency required for tests

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
├── tools/
│   └── nasm-3.01/           # Bundled NASM for Windows
├── scripts/
│   ├── extract_sources.py   # Extract sources from SMP
│   └── gen_rtcd_arm.py      # Generate ARM RTCD headers
├── test/
│   └── version_test.c       # Basic link test
└── libvpx/                  # Submodule (ShiftMediaProject)
```

## Future Work

### 32-bit Support
## Credits

- [libvpx](https://chromium.googlesource.com/webm/libvpx/) - The WebM Project
- [ShiftMediaProject](https://github.com/ShiftMediaProject/libvpx) - Pre-configured build files

## Licence

libvpx is BSD-licensed. See `libvpx/LICENSE` for details.
