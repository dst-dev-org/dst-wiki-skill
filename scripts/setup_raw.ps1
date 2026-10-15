# scripts/setup_raw.ps1
# Extract DST scripts from Steam installation into raw/current/
# v2.2: Idempotent preparation with staging and preserved snapshots.
# English only for PowerShell 5.1 compatibility.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$KnowledgeRoot,
    [string]$SteamPath,
    [string]$GamePath,
    [switch]$Force  # Re-extract the same build, preserving the previous snapshot
)

$ErrorActionPreference = "Stop"

function Test-AbsolutePath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    if ([System.IO.Path]::DirectorySeparatorChar -eq '\') {
        return $Path -match '^(?:[A-Za-z]:[\\/]|[\\/]{2}[^\\/]+[\\/][^\\/]+)'
    }
    return [System.IO.Path]::IsPathRooted($Path)
}

# ---------- Path Setup ----------
if (-not (Test-AbsolutePath $KnowledgeRoot)) { throw 'KnowledgeRoot must be absolute.' }
$ProjectRoot = [System.IO.Path]::GetFullPath($KnowledgeRoot)
if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) { throw 'KnowledgeRoot must exist.' }
$RawCurrent  = Join-Path $ProjectRoot "raw\current"
$RawArchive  = Join-Path $ProjectRoot "raw\archive"

Write-Verbose "Project root: $ProjectRoot"
Write-Verbose "Target path: $RawCurrent"

# ---------- Functions ----------
function Find-SteamPath {
    $candidates = @()
    try { $candidates += (Get-ItemProperty "HKCU:\Software\Valve\Steam" -Name SteamPath -EA Stop).SteamPath } catch {}
    try { $candidates += (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam" -Name InstallPath -EA Stop).InstallPath } catch {}
    try { $candidates += (Get-ItemProperty "HKLM:\SOFTWARE\Valve\Steam" -Name InstallPath -EA Stop).InstallPath } catch {}
    $candidates += "C:\Program Files (x86)\Steam"
    $candidates += "C:\Program Files\Steam"

    foreach ($c in $candidates) {
        if ((Test-AbsolutePath $c) -and (Test-Path -LiteralPath $c -PathType Container)) { return $c }
    }
    return $null
}

function Get-SteamLibraries {
    param([string]$SteamRoot)
    $libs = @()
    if ($SteamRoot) { $libs += $SteamRoot }
    $vdf = Join-Path $SteamRoot "steamapps\libraryfolders.vdf"
    if (Test-Path $vdf) {
        $content = Get-Content $vdf -Raw -EA SilentlyContinue
        if ($content) {
            foreach ($m in [regex]::Matches($content, '"path"\s+"([^"]+)"')) {
                $p = $m.Groups[1].Value -replace '\\\\', '\'
                if (Test-Path $p) { $libs += $p }
            }
        }
    }
    return $libs | Select-Object -Unique
}

function Find-DstGame {
    param([string[]]$Libraries)
    foreach ($lib in $Libraries) {
        if (-not $lib) { continue }
        $game = Join-Path $lib "steamapps\common\Don't Starve Together"
        if (Test-Path $game) { return $game }
    }
    return $null
}

function Get-BuildId {
    param([string]$LibraryRoot, [string]$AppId = "322330")
    if (-not $LibraryRoot) { return $null }
    $acf = Join-Path $LibraryRoot "steamapps\appmanifest_$AppId.acf"
    if (Test-Path $acf) {
        $content = Get-Content $acf -Raw -EA SilentlyContinue
        if ($content) {
            $m = [regex]::Match($content, '"buildid"\s+"(\d+)"')
            if ($m.Success) { return $m.Groups[1].Value }
        }
    }
    return $null
}

function Find-ScriptsZip {
    param([string]$GameRoot)
    $candidates = @(
        (Join-Path $GameRoot "data\databundles\scripts.zip"),
        (Join-Path $GameRoot "data\scripts.zip")
    )
    foreach ($c in $candidates) { if (Test-Path $c) { return $c } }
    return $null
}

function Test-ScriptsLayout {
    param([string]$SnapshotRoot)
    $scripts = Join-Path $SnapshotRoot "scripts"
    foreach ($file in @("class.lua", "entityscript.lua")) {
        if (-not (Test-Path -LiteralPath (Join-Path $scripts $file) -PathType Leaf)) { return $false }
    }
    foreach ($directory in @("components", "prefabs")) {
        $folder = Join-Path $scripts $directory
        if (-not (Test-Path -LiteralPath $folder -PathType Container)) { return $false }
        if (-not (Get-ChildItem -LiteralPath $folder -Filter *.lua -File | Select-Object -First 1)) { return $false }
    }
    return $true
}

function Assert-RawTarget {
    param([string]$Target)
    $root = [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot "raw"))
    $absolute = [System.IO.Path]::GetFullPath($Target)
    $prefix = $root.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $absolute.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Filesystem target must remain within raw: $absolute"
    }
}

function Get-ArchiveTarget {
    param([string]$Build)
    $label = "unidentified"
    if ($Build -match '^(\d+|unknown)$') { $label = $Build }
    $target = Join-Path $RawArchive "build-$label"
    while (Test-Path -LiteralPath $target) {
        $suffix = (Get-Date -Format "yyyyMMdd-HHmmss") + "-" + [guid]::NewGuid().ToString("N")
        $target = Join-Path $RawArchive "build-$label-$suffix"
    }
    Assert-RawTarget -Target $target
    return $target
}

# ---------- Main Flow ----------

# 1. Locate game directory
if (-not $GamePath) {
    if (-not $SteamPath) {
        $SteamPath = Find-SteamPath
        if (-not $SteamPath) { throw "Steam not found. Please specify with -SteamPath." }
    }
    $SteamPath = $SteamPath.Trim()
    if (-not (Test-AbsolutePath $SteamPath)) { throw 'SteamPath must be absolute.' }
    $SteamPath = [System.IO.Path]::GetFullPath($SteamPath)
    if (-not (Test-Path -LiteralPath $SteamPath -PathType Container)) { throw "Steam path not found: $SteamPath" }
    Write-Verbose "Steam root: $SteamPath"
    $libraries = Get-SteamLibraries -SteamRoot $SteamPath
    $GamePath = Find-DstGame -Libraries $libraries
    if (-not $GamePath) { throw "DST not found. Please specify with -GamePath." }
}
$GamePath = $GamePath.Trim()
if (-not (Test-AbsolutePath $GamePath)) { throw 'GamePath must be absolute.' }
$GamePath = [System.IO.Path]::GetFullPath($GamePath)
if (-not (Test-Path -LiteralPath $GamePath -PathType Container)) { throw "Game path not found: $GamePath" }
Write-Verbose "Game path: $GamePath"

# 2. Get the locally installed build ID
$libraryRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $GamePath))
$newBuild = Get-BuildId -LibraryRoot $libraryRoot
if (-not $newBuild) {
    $p = $GamePath
    while ($p -and -not (Test-Path (Join-Path $p "steamapps"))) {
        $parent = Split-Path -Parent $p
        if ($parent -eq $p) { break }
        $p = $parent
    }
    if ($p) { $newBuild = Get-BuildId -LibraryRoot $p }
}
if (-not $newBuild) { $newBuild = "unknown" }
Write-Verbose "Installed game build: $newBuild"

# 3. Read existing local build ID
$existingBuild = $null
$existingBuildFile = Join-Path $RawCurrent "BUILD.txt"
if (Test-Path $existingBuildFile) {
    $existingBuildRaw = Get-Content $existingBuildFile -Raw -EA SilentlyContinue
    if ($existingBuildRaw) { $existingBuild = $existingBuildRaw.Trim() }
    Write-Verbose "Existing local build: $existingBuild"
} else {
    Write-Verbose "No existing local build found."
}

# 4. Build comparison logic (core idempotency)
if (($existingBuild -eq $newBuild) -and ($newBuild -ne "unknown") -and (Test-ScriptsLayout -SnapshotRoot $RawCurrent) -and (-not $Force)) {
    Write-Host "[Skip] Build ID ($newBuild) has not changed. Skipping extraction." -ForegroundColor Green
    Write-Verbose "Use -Force to force re-extraction."
    exit 0
}

# 5. Locate the archive before changing any existing snapshot
$scriptsZip = Find-ScriptsZip -GameRoot $GamePath
if (-not $scriptsZip) { throw "scripts.zip not found in $GamePath." }
Write-Host "[Zip] Found: $scriptsZip" -ForegroundColor Green

# 6. Extract and validate first; failures leave raw/current usable
$staging = Join-Path (Join-Path $ProjectRoot "raw") (".setup-" + [guid]::NewGuid().ToString("N"))
$archiveTarget = $null
Assert-RawTarget -Target $staging
Assert-RawTarget -Target $RawCurrent
Assert-RawTarget -Target $RawArchive
try {
    New-Item -ItemType Directory -Path $staging -Force | Out-Null
    Write-Host "[Extract] Preparing a temporary snapshot ..." -ForegroundColor Cyan
    # Headless/redirected hosts cannot render Expand-Archive progress; restore afterwards.
    $previousProgressPreference = $global:ProgressPreference
    try {
        $global:ProgressPreference = "SilentlyContinue"
        Expand-Archive -LiteralPath $scriptsZip -DestinationPath $staging -Force
    } finally {
        $global:ProgressPreference = $previousProgressPreference
    }
    if (-not (Test-ScriptsLayout -SnapshotRoot $staging)) { throw "Extracted archive does not contain the expected scripts layout." }
    Set-Content -LiteralPath (Join-Path $staging "BUILD.txt") -Value $newBuild -Encoding ascii

    # 7. Preserve every previous snapshot, including force repairs and duplicates
    if (Test-Path -LiteralPath $RawCurrent) {
        New-Item -ItemType Directory -Force -Path $RawArchive | Out-Null
        $archiveTarget = Get-ArchiveTarget -Build $existingBuild
        Write-Host "[Archive] Preserving previous snapshot -> $archiveTarget" -ForegroundColor Yellow
        Move-Item -LiteralPath $RawCurrent -Destination $archiveTarget
    }
    try {
        Move-Item -LiteralPath $staging -Destination $RawCurrent
    } catch {
        if ($archiveTarget -and (-not (Test-Path -LiteralPath $RawCurrent))) {
            Assert-RawTarget -Target $archiveTarget
            Move-Item -LiteralPath $archiveTarget -Destination $RawCurrent
        }
        throw
    }
} finally {
    if (Test-Path -LiteralPath $staging) {
        Assert-RawTarget -Target $staging
        Remove-Item -LiteralPath $staging -Recurse -Force
    }
}

Write-Host "[Build] ID: $newBuild" -ForegroundColor Green
$luaFiles = @(Get-ChildItem -LiteralPath (Join-Path $RawCurrent "scripts") -Recurse -Filter *.lua -File)
Write-Host "[Done] Extracted $($luaFiles.Count) .lua files." -ForegroundColor Green
