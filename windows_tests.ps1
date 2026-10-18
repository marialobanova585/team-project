$ErrorActionPreference = "Stop"

$scriptPath = Join-Path $PSScriptRoot "windows_backup.ps1"
$tempRoot = Join-Path $env:TEMP ("backup_test_" + [guid]::NewGuid().ToString("N"))
$logPath = Join-Path $tempRoot "logs"
$backupPath = Join-Path $tempRoot "backup"

New-Item -ItemType Directory -Path $logPath -Force | Out-Null

try {
    Set-Content -Path (Join-Path $logPath "old.log") -Value ("A" * 3000)
    Set-Content -Path (Join-Path $logPath "new.log") -Value ("B" * 3000)

    (Get-Item (Join-Path $logPath "old.log")).LastWriteTime = (Get-Date).AddDays(-5)
    (Get-Item (Join-Path $logPath "new.log")).LastWriteTime = (Get-Date).AddDays(-1)

    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $scriptPath -LogPath $logPath -BackupPath $backupPath -LimitPercent 0 -M 1 -Filter "*.log"
    if ($LASTEXITCODE -ne 0) {
        throw "FAIL: backup script returned an error"
    }

    $archives = @(Get-ChildItem -LiteralPath $backupPath -Filter "*.tar.gz" -File)
    if ($archives.Count -ne 1) {
        throw "FAIL: expected one archive"
    }

    $contents = @(tar.exe -tzf $archives[0].FullName)
    if ($LASTEXITCODE -ne 0) {
        throw "FAIL: archive could not be read"
    }

    if ($contents.Count -ne 1 -or $contents[0] -ne "old.log") {
        throw "FAIL: archive does not contain only the oldest file"
    }

    Write-Host "PASS: threshold triggers backup"
    Write-Host "PASS: archive contains only the oldest matching file"

    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $scriptPath -LogPath (Join-Path $tempRoot "missing") -BackupPath $backupPath
    if ($LASTEXITCODE -eq 0) {
        throw "FAIL: missing log folder should return an error"
    }

    Write-Host "PASS: missing log folder is rejected"
    Write-Host "ALL TESTS PASSED"
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}