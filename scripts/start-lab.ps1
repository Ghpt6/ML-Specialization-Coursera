[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('1', '2')]
    [string]$Course = '1'
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'courses.ps1')
$CoursePath = Join-Path $ProjectRoot $CourseDirectories[$Course]
$VenvPython = Join-Path $CoursePath '.venv\Scripts\python.exe'
if (-not (Test-Path -LiteralPath $VenvPython)) {
    Write-Host "Run setup.cmd $Course first."
    exit 1
}

$Settings = @{
    JUPYTER_CONFIG_DIR = (Join-Path $ProjectRoot '.tools\jupyter\config')
    JUPYTER_DATA_DIR = (Join-Path $ProjectRoot '.tools\jupyter\data')
    JUPYTER_RUNTIME_DIR = (Join-Path $ProjectRoot '.tools\jupyter\runtime')
    MPLCONFIGDIR = (Join-Path $ProjectRoot '.tools\matplotlib')
    IPYTHONDIR = (Join-Path $ProjectRoot '.tools\ipython')
}
$PreviousSettings = @{}
foreach ($name in $Settings.Keys) {
    $PreviousSettings[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
    [Environment]::SetEnvironmentVariable($name, $Settings[$name], 'Process')
}

try {
    Push-Location -LiteralPath $CoursePath
    & $VenvPython -m jupyterlab --notebook-dir $CoursePath
    $Result = $LASTEXITCODE
} finally {
    Pop-Location
    foreach ($name in $PreviousSettings.Keys) {
        [Environment]::SetEnvironmentVariable($name, $PreviousSettings[$name], 'Process')
    }
}
exit $Result
