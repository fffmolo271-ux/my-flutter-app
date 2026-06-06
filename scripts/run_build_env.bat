@echo off
set "ORG_GRADLE_JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot"
set "PATH=C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot\bin;C:\flutter\bin;%PATH%"
set "org.gradle.java.home="
cd /d "%~dp0.."
echo ORG_GRADLE_JAVA_HOME=%ORG_GRADLE_JAVA_HOME%
flutter pub get
flutter build apk --release -v > build_log_env.txt 2>&1
echo BUILD_EXIT=%ERRORLEVEL% > build_exit_env.txt
