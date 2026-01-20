@echo off
REM Generate test IVF files for libvpx decode testing
REM All videos are small and short for fast testing

setlocal

set FFMPEG=ffmpeg.exe
set OUTDIR=test\videos

if not exist "%OUTDIR%" mkdir "%OUTDIR%"

echo Generating test videos...

REM ============================================================
REM VP9 Tests
REM ============================================================

echo [1/10] VP9 basic - 320x240, 30fps, 1 second
%FFMPEG% -y -f lavfi -i testsrc=duration=1:size=320x240:rate=30 ^
    -c:v libvpx-vp9 -b:v 500k ^
    "%OUTDIR%\vp9_320x240_30fps.ivf" 2>nul

echo [2/10] VP9 tiny - 64x64, 10fps, 0.5 seconds (edge case: small)
%FFMPEG% -y -f lavfi -i testsrc=duration=0.5:size=64x64:rate=10 ^
    -c:v libvpx-vp9 -b:v 100k ^
    "%OUTDIR%\vp9_64x64_tiny.ivf" 2>nul

echo [3/10] VP9 720p - 1280x720, 30fps, 0.5 seconds
%FFMPEG% -y -f lavfi -i testsrc=duration=0.5:size=1280x720:rate=30 ^
    -c:v libvpx-vp9 -b:v 2M ^
    "%OUTDIR%\vp9_720p.ivf" 2>nul

echo [4/10] VP9 odd dimensions - 317x243 (non-divisible by 16)
%FFMPEG% -y -f lavfi -i testsrc=duration=0.5:size=317x243:rate=30 ^
    -c:v libvpx-vp9 -b:v 500k ^
    "%OUTDIR%\vp9_odd_dimensions.ivf" 2>nul

echo [5/10] VP9 high quality - CRF mode
%FFMPEG% -y -f lavfi -i testsrc=duration=0.5:size=320x240:rate=30 ^
    -c:v libvpx-vp9 -crf 10 -b:v 0 ^
    "%OUTDIR%\vp9_high_quality.ivf" 2>nul

echo [6/10] VP9 low quality - high compression
%FFMPEG% -y -f lavfi -i testsrc=duration=0.5:size=320x240:rate=30 ^
    -c:v libvpx-vp9 -crf 50 -b:v 0 ^
    "%OUTDIR%\vp9_low_quality.ivf" 2>nul

echo [7/10] VP9 single frame (poster/thumbnail)
%FFMPEG% -y -f lavfi -i testsrc=duration=0.033:size=320x240:rate=30 ^
    -c:v libvpx-vp9 -b:v 500k ^
    "%OUTDIR%\vp9_single_frame.ivf" 2>nul

echo [8/10] VP9 high framerate - 60fps
%FFMPEG% -y -f lavfi -i testsrc=duration=0.5:size=320x240:rate=60 ^
    -c:v libvpx-vp9 -b:v 500k ^
    "%OUTDIR%\vp9_60fps.ivf" 2>nul

REM ============================================================
REM VP8 Tests
REM ============================================================

echo [9/10] VP8 basic - 320x240, 30fps, 1 second
%FFMPEG% -y -f lavfi -i testsrc=duration=1:size=320x240:rate=30 ^
    -c:v libvpx -b:v 500k ^
    "%OUTDIR%\vp8_320x240_30fps.ivf" 2>nul

echo [10/10] VP8 larger - 640x480
%FFMPEG% -y -f lavfi -i testsrc=duration=0.5:size=640x480:rate=30 ^
    -c:v libvpx -b:v 1M ^
    "%OUTDIR%\vp8_640x480.ivf" 2>nul

REM ============================================================
REM Colour/Pattern Tests (for visual verification if needed)
REM ============================================================

echo [Bonus] Colour bars pattern
%FFMPEG% -y -f lavfi -i smptebars=duration=0.5:size=320x240:rate=30 ^
    -c:v libvpx-vp9 -b:v 500k ^
    "%OUTDIR%\vp9_colorbars.ivf" 2>nul

echo [Bonus] Solid colour (simple content)
%FFMPEG% -y -f lavfi -i color=c=blue:duration=0.5:size=320x240:rate=30 ^
    -c:v libvpx-vp9 -b:v 100k ^
    "%OUTDIR%\vp9_solid_blue.ivf" 2>nul

echo [Bonus] Noise pattern (complex content)
%FFMPEG% -y -f lavfi -i nullsrc=size=320x240:rate=30,geq=random(1)*255:128:128 -t 0.5 ^
    -c:v libvpx-vp9 -b:v 1M ^
    "%OUTDIR%\vp9_noise.ivf" 2>nul

echo.
echo Done! Generated test videos in %OUTDIR%:
echo.
dir /b "%OUTDIR%\*.ivf"
echo.
echo Total files:
dir /b "%OUTDIR%\*.ivf" | find /c /v ""

endlocal
