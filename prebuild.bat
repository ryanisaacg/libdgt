@echo off
if NOT exist "SDL2.dll" (
    powershell -ExecutionPolicy ByPass -File prebuild.ps1 > out
    del out
)
