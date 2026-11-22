@echo off
rem 운빨삼국 단위 테스트 (Godot 4.7.2, 헤드리스)
setlocal
set "GODOT=%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe"
if not exist "%GODOT%" set "GODOT=%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT%" set "GODOT=godot"
cd /d "%~dp0"
"%GODOT%" --headless --path . --import
"%GODOT%" --headless --path . -s res://tests/run_tests.gd
pause
