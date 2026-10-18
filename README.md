.\windows_version\windows_backup.ps1 -LogPath ".\windows_version\test-logs"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\windows_version\windows_tests.ps1"