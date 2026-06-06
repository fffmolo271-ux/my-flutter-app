@echo off
REM Force Java home and Flutter path for this session then build release APK
set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot"
set "PATH=%JAVA_HOME%\bin;C:\flutter\bin;%PATH%"
set "org.gradle.java.home="
cd /d "%~dp0.."
echo Using JAVA_HOME=%JAVA_HOME%
flutter pub get
flutter build apk --release -v > build_log.txt 2>&1
echo BUILD_EXIT=%ERRORLEVEL% > build_exit_code.txt
