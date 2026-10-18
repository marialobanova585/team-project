.\windows_backup.ps1 -LogPath ".\test-logs"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\windows_tests.ps1"
