@echo off
powershell -ExecutionPolicy ByPass -File prebuild.ps1 > out
del out
