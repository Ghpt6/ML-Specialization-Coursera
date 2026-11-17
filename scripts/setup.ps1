[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('1', '2', 'all')]
    [string]$Course = 'all'
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'courses.ps1')

# Save process-local settings so calling this script does not change the caller's environment.
$Settings = @{
    UV_CACHE_DIR = (Join-Path $ProjectRoot '.tools\cache')
    UV_PYTHON_INSTALL_DIR = (Join-Path $ProjectRoot '.tools\python')
    UV_PYTHON_INSTALL_BIN = '0'
    UV_PYTHON_INSTALL_REGISTRY = '0'
    UV_PROJECT_ENVIRONMENT = $null
    JUPYTER_CONFIG_DIR = (Join-Path $ProjectRoot '.tools\jupyter\config')
    JUPYTER_DATA_DIR = (Join-Path $ProjectRoot '.tools\jupyter\data')
    JUPYTER_RUNTIME_DIR = (Join-Path $ProjectRoot '.tools\jupyter\runtime')
    MPLCONFIGDIR = (Join-Path $ProjectRoot '.tools\matplotlib')
    IPYTHONDIR = (Join-Path $ProjectRoot '.tools\ipython')
    TF_CPP_MIN_LOG_LEVEL = '2'
}
$PreviousSettings = @{}
foreach ($name in $Settings.Keys) {
    $PreviousSettings[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
    [Environment]::SetEnvironmentVariable($name, $Settings[$name], 'Process')
}

try {
    if (-not [Environment]::Is64BitOperatingSystem -or
        $env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or
        $env:PROCESSOR_ARCHITEW6432 -eq 'ARM64') {
        throw 'This installer supports Windows x64.'
    }

    $UvVersion = '0.11.24'
    $UvDirectory = Join-Path $ProjectRoot ".tools\uv-$UvVersion"
    $UvExe = Join-Path $UvDirectory 'uv.exe'
    if (-not (Test-Path -LiteralPath $UvExe)) {
        Write-Host "Downloading uv $UvVersion into this project..."
        New-Item -ItemType Directory -Path $UvDirectory -Force | Out-Null
        $Archive = Join-Path $UvDirectory 'uv.zip'
        $DownloadUrl = "https://github.com/astral-sh/uv/releases/download/$UvVersion/uv-x86_64-pc-windows-msvc.zip"
        $ExpectedHash = 'af9573a2e36f7020b18ec5fdde20117aae74bbad3f4acb3dc3fc03319f1aa083'
        $OldProgressPreference = $ProgressPreference
        try {
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -UseBasicParsing -Uri $DownloadUrl -OutFile $Archive
        } finally {
            $ProgressPreference = $OldProgressPreference
        }
        if ((Get-FileHash -LiteralPath $Archive -Algorithm SHA256).Hash -ne $ExpectedHash) {
            throw 'The downloaded uv archive failed its SHA256 check. Run setup again to retry.'
        }
        Expand-Archive -LiteralPath $Archive -DestinationPath $UvDirectory -Force
    }
    $ActualUvVersion = & $UvExe --version
    if ($LASTEXITCODE -ne 0 -or $ActualUvVersion -notlike "uv $UvVersion *") {
        throw "Cannot run the expected uv $UvVersion at $UvExe"
    }

    $SelectedCourses = if ($Course -eq 'all') { @('1', '2') } else { @($Course) }
    foreach ($number in $SelectedCourses) {
        $CoursePath = Join-Path $ProjectRoot $CourseDirectories[$number]
        $VenvPath = Join-Path $CoursePath '.venv'
        $VenvPython = Join-Path $VenvPath 'Scripts\python.exe'
        $PythonVersion = (Get-Content -LiteralPath (Join-Path $CoursePath '.python-version') -Raw).Trim()
        Write-Host "`nSetting up Course $number with Python $PythonVersion..."

        if (Test-Path -LiteralPath $VenvPath) {
            if (-not (Test-Path -LiteralPath $VenvPython)) {
                throw "An incomplete environment exists at $VenvPath. Rename it and run setup again."
            }
            $ExistingVersion = & $VenvPython -c 'import platform; print(platform.python_version())'
            if ($LASTEXITCODE -ne 0 -or $ExistingVersion -ne $PythonVersion) {
                throw "The existing $VenvPath is not Python $PythonVersion. Rename it before retrying."
            }
        }

        & $UvExe python install $PythonVersion --no-bin --no-registry
        if ($LASTEXITCODE -ne 0) { throw 'Downloading the project-local Python runtime failed.' }
        $RuntimePython = & $UvExe python find --managed-python --no-project $PythonVersion
        if ($LASTEXITCODE -ne 0) { throw 'Cannot find the project-local Python runtime.' }
        $RuntimeRoot = [IO.Path]::GetFullPath($env:UV_PYTHON_INSTALL_DIR) + [IO.Path]::DirectorySeparatorChar
        if (-not [IO.Path]::GetFullPath($RuntimePython).StartsWith($RuntimeRoot, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Python unexpectedly resolved outside the project: $RuntimePython"
        }

        $env:UV_PROJECT_ENVIRONMENT = $VenvPath
        & $UvExe sync --project $CoursePath --python $RuntimePython --locked --no-dev
        if ($LASTEXITCODE -ne 0) { throw "Dependency installation failed for Course $number." }

        & $VenvPython (Join-Path $PSScriptRoot 'repair_venv_version.py')
        if ($LASTEXITCODE -ne 0) { throw "Version metadata repair failed for Course $number." }

        & $VenvPython -m ipykernel install --sys-prefix --name "ml-course-$number" --display-name "ML Course $number (Python 3.11)"
        if ($LASTEXITCODE -ne 0) { throw "Kernel setup failed for Course $number." }
        & $VenvPython -m pip check
        if ($LASTEXITCODE -ne 0) { throw "Dependency verification failed for Course $number." }
        & $VenvPython (Join-Path $PSScriptRoot 'check_environment.py') $number
        if ($LASTEXITCODE -ne 0) { throw "The Course $number smoke check failed." }
    }
    Write-Host "`nSetup complete. Run start-lab.cmd 1 or start-lab.cmd 2."
    Write-Host 'For VS Code, open ML-Specialization.code-workspace and select the matching course .venv kernel.'
} catch {
    Write-Host "`nSetup failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    foreach ($name in $PreviousSettings.Keys) {
        [Environment]::SetEnvironmentVariable($name, $PreviousSettings[$name], 'Process')
    }
}
