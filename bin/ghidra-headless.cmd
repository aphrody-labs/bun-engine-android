@echo off
set "JAVA_HOME=%~dp0..\tools\jdk"
call "%~dp0..\tools\ghidra\support\analyzeHeadless.bat" %*
