@echo off
setlocal
set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot"
set "ORG_GRADLE_JAVA_HOME="
cd /d "%~dp0..\android"
call gradlew.bat --no-daemon -Dorg.gradle.java.home="C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot" assembleRelease > ..\gradle_override_output.txt 2>&1
echo ExitCode=%ERRORLEVEL% > ..\gradle_override_exit.txt
endlocal
