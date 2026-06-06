$ErrorActionPreference = 'Stop'
$env:JAVA_HOME = 'C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
Set-Location -Path "$PSScriptRoot\.."
Write-Output "Using JAVA_HOME: $env:JAVA_HOME"
if (Test-Path -Path .\android\gradlew.bat) { .\android\gradlew.bat --stop }
flutter pub outdated > pub_outdated.txt 2>&1
flutter pub upgrade > pub_upgrade.txt 2>&1
flutter pub get > pub_get.txt 2>&1
flutter analyze > analyze_out.txt 2>&1
flutter test --no-pub > test_out.txt 2>&1
if ($LASTEXITCODE -ne 0) { Write-Output "TESTS_EXITED:$LASTEXITCODE" }
flutter build apk --release -v 2>&1 | Out-File build_log.txt -Encoding utf8
Write-Output 'BUILD_SCRIPT_DONE'