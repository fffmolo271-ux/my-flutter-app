$env:JAVA_HOME='C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot'
$env:ORG_GRADLE_JAVA_HOME=''
Write-Output "JAVA_HOME=$env:JAVA_HOME"
& 'C:\flutter\bin\flutter.bat' test --no-color | Tee-Object -FilePath ..\test_output.txt
