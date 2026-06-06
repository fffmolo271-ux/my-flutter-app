Push-Location -Path "$PSScriptRoot\..\android"
Write-Output "Forcing JAVA_HOME for this gradle run"
& cmd /c "set \"JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot\" && gradlew.bat --no-daemon --full-stacktrace assembleRelease" 2>&1 | Out-File ..\gradle_manual_build_log.txt -Encoding utf8
Pop-Location
Write-Output 'GRADLE_RUN_DONE'