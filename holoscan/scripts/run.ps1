$ErrorActionPreference = "Stop"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$AppPath = Join-Path $ProjectRoot "holoscan\app"

docker run --rm `
    --gpus all `
    --ipc=host `
    --ulimit memlock=-1 `
    --ulimit stack=67108864 `
    --cap-add CAP_SYS_PTRACE `
    -v "${AppPath}:/workspace/app" `
    nvcr.io/nvidia/clara-holoscan/holoscan:v4.5.0-cuda13 `
    python3 /workspace/app/main.py