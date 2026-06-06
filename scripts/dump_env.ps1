Write-Output "User ORG_GRADLE_JAVA_HOME: $([Environment]::GetEnvironmentVariable('ORG_GRADLE_JAVA_HOME','User'))"
Write-Output "Machine ORG_GRADLE_JAVA_HOME: $([Environment]::GetEnvironmentVariable('ORG_GRADLE_JAVA_HOME','Machine'))"
Write-Output "Process org.gradle.java.home: $([Environment]::GetEnvironmentVariable('org.gradle.java.home','Process'))"
Write-Output "Process JAVA_HOME: $([Environment]::GetEnvironmentVariable('JAVA_HOME','Process'))"
Write-Output "All Env Vars matching gradle or JAVA:"
Get-ChildItem Env: | Where-Object { $_.Name -match 'gradle|JAVA_HOME|JAVA' } | ForEach-Object { Write-Output "ENV:${($_.Name)}=${($_.Value)}" }