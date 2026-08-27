$ErrorActionPreference = "Stop"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$AppPath = Join-Path $ProjectRoot "holoscan\app"
$RuntimeConfig = Join-Path $ProjectRoot "holoscan\config\runtime.env"

$RuntimeLine = Get-Content $RuntimeConfig |
    Where-Object { $_ -match "^HOLOSCAN_IMAGE=" } |
    Select-Object -First 1

if (-not $RuntimeLine) {
    throw "HOLOSCAN_IMAGE is not defined in runtime.env"
}

$HoloscanImage = $RuntimeLine -replace "^HOLOSCAN_IMAGE=", ""

if ([string]::IsNullOrWhiteSpace($HoloscanImage)) {
    throw "HOLOSCAN_IMAGE is empty in runtime.env"
}

Write-Host "Starting Project 259 with:"
Write-Host "  Holoscan image: $HoloscanImage"
Write-Host "  Application:    $AppPath"

docker run --rm `
    --gpus all `
    --ipc=host `
    --ulimit memlock=-1 `
    --ulimit stack=67108864 `
    --cap-add CAP_SYS_PTRACE `
    -v "${AppPath}:/workspace/app" `
    $HoloscanImage `
    python3 /workspace/app/main.py

if ($LASTEXITCODE -ne 0) {
    throw "Holoscan application exited with code $LASTEXITCODE"
}