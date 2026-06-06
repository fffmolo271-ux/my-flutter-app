Select-String -Path 'build_ps_output.txt' -Pattern 'org.gradle.java.home' -CaseSensitive | Out-File -FilePath 'grep_results.txt' -Encoding utf8
Select-String -Path 'build_ps_output.txt' -Pattern "Value 'C:Program" -SimpleMatch | Out-File -FilePath 'grep_results2.txt' -Encoding utf8
