param([string]$Python = "python")
$ErrorActionPreference = "Stop"
$previousPythonUtf8 = $env:PYTHONUTF8
$env:PYTHONUTF8 = '1' # Inherited by pip's isolated build subprocesses (Chinese paths).
Push-Location $PSScriptRoot
try {
    # Repair an earlier editable install before pip itself imports site.
    if (Test-Path -LiteralPath '.venv\Lib\site-packages\_editable_impl_qc_clock_model.pth') {
        & '.\.venv\Scripts\python.exe' -S fix_editable_path.py
        if ($LASTEXITCODE -ne 0) { throw 'Editable path repair failed' }
    }
    if (-not (Test-Path -LiteralPath '.venv\Scripts\python.exe')) {
        & $Python -m venv .venv
        if ($LASTEXITCODE -ne 0) { throw 'Virtual environment creation failed' }
    }
    & '.\.venv\Scripts\python.exe' -m pip install --upgrade pip setuptools wheel
    if ($LASTEXITCODE -ne 0) { throw 'Build tool installation failed; inspect the pip error above' }
    & '.\.venv\Scripts\python.exe' -m pip install -e '.[test]'
    if ($LASTEXITCODE -ne 0) { throw 'Dependency installation failed; check network access and Python version' }
    & '.\.venv\Scripts\python.exe' -S fix_editable_path.py
    if ($LASTEXITCODE -ne 0) { throw 'Editable path repair failed' }
    & '.\.venv\Scripts\python.exe' -m pip check
    if ($LASTEXITCODE -ne 0) { throw 'Dependency validation failed' }
    & '.\.venv\Scripts\python.exe' -m pytest
    if ($LASTEXITCODE -ne 0) { throw 'Physics tests failed' }
    # Written only after successful installation and tests; includes editable local project.
    & '.\.venv\Scripts\python.exe' -m pip freeze --exclude-editable |
        Set-Content -LiteralPath 'requirements-lock.txt' -Encoding utf8
    if ($LASTEXITCODE -ne 0) { throw 'Dependency snapshot failed' }
} finally {
    $env:PYTHONUTF8 = $previousPythonUtf8
    Pop-Location
}
