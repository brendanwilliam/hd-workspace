[CmdletBinding()]
param(
    [ValidateSet('obs', 'web')]
    [string]$Component
)

$ErrorActionPreference = 'Stop'

$workspaceDir = $PSScriptRoot
$obsProjectDir = Join-Path $workspaceDir 'hd-obs'
$webProjectDir = Join-Path $workspaceDir 'hd-web'
$obsPluginsDir = Join-Path $HOME 'Library/Application Support/obs-studio/plugins'
$obsPluginBundle = Join-Path $obsPluginsDir 'hd-obs.plugin'
$obsBuildBundle = Join-Path $obsProjectDir 'build_macos/RelWithDebInfo/hd-obs.plugin'

function Invoke-External([string]$Command, [Parameter(ValueFromRemainingArguments)] [string[]]$Arguments) {
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Command failed with exit code $LASTEXITCODE."
    }
}

function Require-Project([string]$ProjectDir, [string]$ProjectName) {
    if (-not (Test-Path -LiteralPath $ProjectDir -PathType Container)) {
        throw "$ProjectName was not found at $ProjectDir. Initialize the workspace submodules first:`n  git submodule update --init --recursive"
    }
}

function Configure-ObsBuild {
    $cacheFile = Join-Path $obsProjectDir 'build_macos/CMakeCache.txt'
    $cachedSourceDir = ''
    if (Test-Path -LiteralPath $cacheFile -PathType Leaf) {
        $cachedSourceDir = (Select-String -LiteralPath $cacheFile -Pattern '^CMAKE_HOME_DIRECTORY:INTERNAL=(.*)$').Matches.Groups[1].Value
    }

    if ($cachedSourceDir -and $cachedSourceDir -ne $obsProjectDir) {
        Write-Host 'Refreshing the OBS build cache after the workspace moved.'
        Invoke-External cmake --fresh --preset macos
    }
    else {
        Invoke-External cmake --preset macos
    }
}

function Link-ObsPlugin {
    New-Item -ItemType Directory -Force -Path $obsPluginsDir | Out-Null
    $existing = Get-Item -LiteralPath $obsPluginBundle -Force -ErrorAction SilentlyContinue
    if ($existing -and $existing.LinkType -ne 'SymbolicLink') {
        throw "Refusing to replace the existing copied OBS plugin at $obsPluginBundle. Move it to a timestamped backup, then run this command again to create the development symlink."
    }
    if ($existing) {
        Remove-Item -LiteralPath $obsPluginBundle -Force
    }
    New-Item -ItemType SymbolicLink -Path $obsPluginBundle -Target $obsBuildBundle | Out-Null
    Write-Host 'Linked OBS to the current build. Fully quit and reopen OBS to load it.'
}

function Install-ObsPlugin {
    if (-not $IsMacOS) {
        Write-Warning 'Skipping hd-obs: the OBS plugin currently supports macOS only.'
        return
    }

    Require-Project $obsProjectDir 'hd-obs'
    Push-Location $obsProjectDir
    try {
        Configure-ObsBuild
        Invoke-External cmake --build --preset macos --config RelWithDebInfo
        Link-ObsPlugin
    }
    finally {
        Pop-Location
    }
}

function Install-Web {
    Require-Project $webProjectDir 'hd-web'
    Push-Location $webProjectDir
    try {
        if (-not (Test-Path -LiteralPath '.env' -PathType Leaf)) {
            Copy-Item -LiteralPath '.env.example' -Destination '.env'
            Write-Host 'Created hd-web/.env from .env.example. Update its OAuth and secret values before using authentication.'
        }

        Invoke-External docker compose up --detach --wait db
        Invoke-External npm run db:migrate
        Invoke-External npm run build
    }
    finally {
        Pop-Location
    }
}

if ($Component -eq 'obs') {
    Install-ObsPlugin
}
elseif ($Component -eq 'web') {
    Install-Web
}
else {
    Install-ObsPlugin
    Install-Web
}
