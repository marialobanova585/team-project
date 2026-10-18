param(
    [Parameter(Mandatory = $true)]
    [string]$LogPath,

    [double]$LimitPercent = 50,
    [int]$M = 3,
    [string]$BackupPath = ".\backup",
    [string]$Filter = "*"
)

if (!(Test-Path -LiteralPath $LogPath -PathType Container)) {
    Write-Host "Log folder not found!"
    exit 1
}

if ($M -lt 1) {
    Write-Host "M must be at least 1."
    exit 1
}

$LogPath = (Resolve-Path -LiteralPath $LogPath).Path
$driveId = [System.IO.Path]::GetPathRoot($LogPath).TrimEnd('\')
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$driveId'"

if ($null -eq $disk -or $disk.Size -le 0) {
    Write-Host "Could not determine disk usage."
    exit 1
}

$usage = (($disk.Size - $disk.FreeSpace) / $disk.Size) * 100
Write-Host ("Disk usage: {0:N2}%" -f $usage)

if ($usage -le $LimitPercent) {
    Write-Host "Threshold not exceeded. No backup needed."
    exit 0
}

$files = @(
    Get-ChildItem -LiteralPath $LogPath -File |
    Where-Object { $_.Name -like $Filter } |
    Sort-Object LastWriteTime, Name |
    Select-Object -First $M
)

if ($files.Count -eq 0) {
    Write-Host "No files to archive."
    exit 0
}

New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
$BackupPath = (Resolve-Path -LiteralPath $BackupPath).Path

$date = Get-Date -Format "yyyyMMdd_HHmmss"
$archive = Join-Path $BackupPath "archive_$date.tar.gz"
$fileNames = @($files | ForEach-Object { $_.Name })

$tarArgs = @("-czf", $archive, "-C", $LogPath, "--") + $fileNames
& tar.exe @tarArgs
$tarResult = $LASTEXITCODE

if ($tarResult -ne 0 -or !(Test-Path -LiteralPath $archive -PathType Leaf)) {
    Write-Host "Archive creation failed. Original files were kept."
    exit 1
}

foreach ($file in $files) {
    Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop
}

Write-Host "Archive created successfully!"
Write-Host "Archived files removed."
Write-Host $archive