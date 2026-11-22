@echo off
rem 운빨삼국 실행 (Godot 4.7.2)
setlocal
set "GODOT=%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT%" set "GODOT=godot"
cd /d "%~dp0"
rem 새로 바뀐 그림(png)이 빠지지 않도록 실행 전에 항상 가져오기(import)를 갱신
"%GODOT%" --headless --path . --import
start "" "%GODOT%" --path .
