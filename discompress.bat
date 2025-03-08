@echo off
setlocal EnableDelayedExpansion

if "%~1"=="" (
    echo Drag and drop a video file onto this script to compress it.
    pause
    exit /b
)

set "input_file=%~1"
for /f "tokens=1-4 delims=:.," %%a in ("%time%") do set /a "start_seconds=(((%%a*60)+%%b)*60+%%c)*100+%%d"

:menu
echo.
echo Select the desired compression size:
echo 1 - 8MB
echo 2 - 25MB
echo 3 - 100MB
echo 4 - 500MB
echo 5 - Exit
set /p "option=Enter the corresponding number: "

if "%option%"=="1" set "target_size_MB=8" & set "resolution=640x360" & set "preset=fast"
if "%option%"=="2" set "target_size_MB=25" & set "resolution=854x480" & set "preset=medium"
if "%option%"=="3" set "target_size_MB=100" & set "resolution=1280x720" & set "preset=faster"
if "%option%"=="4" set "target_size_MB=500" & set "resolution=1920x1080" & set "preset=fast"
if "%option%"=="5" exit /b

if not defined target_size_MB (
    echo Invalid option.
    pause
    goto menu
)

REM Get video duration
for /f "delims=" %%i in ('ffprobe -v error -show_entries format^=duration -of default^=noprint_wrappers^=1:nokey^=1 "%input_file%"') do set "duration=%%i"

if not defined duration (
    echo Failed to retrieve video duration.
    pause
    exit /b
)

set /a "max_file_size=target_size_MB * 1024 - 100"
set /a "bitrate=max_file_size * 8 / duration"

REM Set minimum limits
if %bitrate% LSS 150 (
    echo Target bitrate too low for acceptable quality.
    pause
    exit /b
)

set /a "video_bitrate=bitrate * 85 / 100"
set /a "audio_bitrate=bitrate * 15 / 100"

if %video_bitrate% LSS 125 (
    set "video_bitrate=125"
)
if %audio_bitrate% LSS 32 (
    set "audio_bitrate=32"
)

set "output_file=%target_size_MB%MB_%~n1.mp4"

echo Compression started for %target_size_MB%MB...
ffmpeg -hide_banner -loglevel warning -stats -i "%input_file%" -preset %preset% -vf scale=%resolution% -r 24 -c:v libx264 -b:v %video_bitrate%k -c:a aac -b:a %audio_bitrate%k -bufsize %bitrate%k -maxrate %bitrate%k "%output_file%"

for /f "tokens=1-4 delims=:.," %%a in ("%time%") do set /a "end_seconds=(((%%a*60)+%%b)*60+%%c)*100+%%d"
set /a "elapsed_time=end_seconds - start_seconds"
set /a "elapsed_sec=elapsed_time / 100"
set /a "elapsed_ms=elapsed_time %% 100"

REM Get final file size
for %%A in ("%output_file%") do set "final_size=%%~zA"
set /a "final_size_MB=final_size / 1048576"

echo Compression completed: %output_file%
echo Final size: %final_size_MB% MB
echo Elapsed time: %elapsed_sec%.%elapsed_ms% seconds

pause
