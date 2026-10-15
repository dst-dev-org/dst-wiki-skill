[CmdletBinding()]
param(
    [string]$KnowledgeRoot,
    [string]$ToolboxRoot,
    [string]$SourceRoot,
    [string]$ConfigPath = (Join-Path ([Environment]::GetFolderPath('UserProfile')) '.dst-wiki/config.json'),
    [switch]$AllowUninitialized
)
$ErrorActionPreference = 'Stop'
$config = $null
if (-not $KnowledgeRoot) {
    if (Test-Path -LiteralPath $ConfigPath -PathType Leaf) {
        try {
            $config = Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($null -eq $config -or $config.GetType().FullName -ne 'System.Management.Automation.PSCustomObject') { throw 'Expected a JSON object.' }
            if ($null -ne $config.knowledge_root -and $config.knowledge_root -isnot [string]) { throw 'knowledge_root must be a string.' }
        } catch {
            throw "Cannot read path configuration at ${ConfigPath}: $($_.Exception.Message)"
        }
    }
}
if (-not $KnowledgeRoot -and $config) { $KnowledgeRoot = $config.knowledge_root }
$invalidToolboxConfig = $false
if (-not $ToolboxRoot -and $config) {
    if ($null -ne $config.toolbox_root -and $config.toolbox_root -isnot [string]) { $invalidToolboxConfig = $true }
    else { $ToolboxRoot = $config.toolbox_root }
}
function Test-AbsolutePath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    if ([System.IO.Path]::DirectorySeparatorChar -eq '\') {
        return $Path -match '^(?:[A-Za-z]:[\\/]|[\\/]{2}[^\\/]+[\\/][^\\/]+)'
    }
    return [System.IO.Path]::IsPathRooted($Path)
}

if (-not (Test-AbsolutePath $KnowledgeRoot)) {
    throw 'Specify an absolute KnowledgeRoot or configure knowledge_root in ~/.dst-wiki/config.json.'
}
$resolvedKnowledge = [System.IO.Path]::GetFullPath($KnowledgeRoot)
$knowledgeExists = Test-Path -LiteralPath $resolvedKnowledge -PathType Container
if ((Test-Path -LiteralPath $resolvedKnowledge) -and -not $knowledgeExists) {
    throw "KnowledgeRoot must be a directory: $resolvedKnowledge"
}
$wikiAvailable = Test-Path -LiteralPath (Join-Path $resolvedKnowledge 'wiki/index.md') -PathType Leaf
if (-not $wikiAvailable -and -not $AllowUninitialized) {
    throw "Knowledge root must contain wiki/index.md: $resolvedKnowledge"
}
$resolvedToolbox = $null
$toolboxWarning = $null
if ($invalidToolboxConfig) { $toolboxWarning = 'toolbox_root must be a string; optional toolbox disabled.' }
if ($ToolboxRoot) {
    if (Test-AbsolutePath $ToolboxRoot) {
        $resolvedToolbox = [System.IO.Path]::GetFullPath($ToolboxRoot)
    } else {
        $toolboxWarning = 'toolbox_root must be absolute; optional toolbox disabled.'
    }
}
$toolboxAvailable = [bool]($resolvedToolbox -and (Test-Path -LiteralPath (Join-Path $resolvedToolbox 'scripts/tools') -PathType Container))
if ($resolvedToolbox -and -not $toolboxAvailable) { $toolboxWarning = 'Optional toolbox is unavailable at the configured path.' }

$resolvedSource = Join-Path $resolvedKnowledge 'raw/current/scripts'
if ($SourceRoot) {
    if (-not (Test-AbsolutePath $SourceRoot)) { throw 'SourceRoot must be an absolute scripts directory.' }
    $resolvedSource = [System.IO.Path]::GetFullPath($SourceRoot)
}
$buildFile = Join-Path (Split-Path -Parent $resolvedSource) 'BUILD.txt'
$sourceDirectoryExists = Test-Path -LiteralPath $resolvedSource -PathType Container
$sourceAvailable = $sourceDirectoryExists -and
    (Test-Path -LiteralPath (Join-Path $resolvedSource 'class.lua') -PathType Leaf) -and
    (Test-Path -LiteralPath (Join-Path $resolvedSource 'entityscript.lua') -PathType Leaf) -and
    (Test-Path -LiteralPath (Join-Path $resolvedSource 'components') -PathType Container) -and
    (Test-Path -LiteralPath (Join-Path $resolvedSource 'prefabs') -PathType Container)
$buildAvailable = Test-Path -LiteralPath $buildFile -PathType Leaf
$sourceVersion = 'unknown'
if ($buildAvailable) {
    $recordedBuild = ([string](Get-Content -LiteralPath $buildFile -Raw -Encoding UTF8)).Trim()
    if ($recordedBuild -match '^\d+$') { $sourceVersion = "steam-buildid:$recordedBuild" }
    elseif ($recordedBuild) { $sourceVersion = $recordedBuild }
}
[ordered]@{
    knowledge_root = $resolvedKnowledge
    knowledge_exists = [bool]$knowledgeExists
    wiki_root = Join-Path $resolvedKnowledge 'wiki'
    wiki_available = [bool]$wikiAvailable
    source_root = $resolvedSource
    build_file = $buildFile
    output_root = Join-Path $resolvedKnowledge 'output'
    source_directory_exists = [bool]$sourceDirectoryExists
    source_available = [bool]$sourceAvailable
    build_available = [bool]$buildAvailable
    source_version = $sourceVersion
    toolbox_root = $resolvedToolbox
    toolbox_available = $toolboxAvailable
    toolbox_warning = $toolboxWarning
} | ConvertTo-Json -Compress
