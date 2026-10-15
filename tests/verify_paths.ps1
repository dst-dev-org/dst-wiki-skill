# Verify path resolution in isolated folders, with no user configuration writes.
# Runs on PowerShell 5.1 and 7; ASCII for consistent 5.1 script decoding.
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$skillRoot = Split-Path -Parent $PSScriptRoot
$temporaryRoot = [System.IO.Path]::GetFullPath((Join-Path ([System.IO.Path]::GetTempPath()) ('dst-skill-paths-' + [guid]::NewGuid().ToString('N'))))
$installedScript = Join-Path $temporaryRoot 'arbitrary harness/dst-wiki-skill/scripts/resolve_paths.ps1'
$knowledgeRoot = Join-Path $temporaryRoot 'knowledge with spaces'
$configPath = Join-Path $temporaryRoot 'user settings/config.json'
$missingConfig = Join-Path $temporaryRoot 'missing-config.json'
$passed = 0

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Resolve-Test {
    param([hashtable]$Options)
    if (-not $Options.ContainsKey('ConfigPath')) { $Options.ConfigPath = $missingConfig }
    $result = & $installedScript @Options
    return ($result | ConvertFrom-Json)
}

function Expect-Failure {
    param([hashtable]$Options, [string]$Expected)
    $message = $null
    try { Resolve-Test $Options | Out-Null } catch { $message = $_.Exception.Message }
    Assert-True ([bool]$message -and $message.Contains($Expected)) "Expected failure containing '$Expected', got '$message'."
}

function Test-Case {
    param([string]$Name, [scriptblock]$Body)
    & $Body
    $script:passed += 1
    Write-Output "PASS $Name"
}

function Write-Config {
    param($Object)
    $Object | ConvertTo-Json | Set-Content -LiteralPath $configPath -Encoding UTF8
}

try {
    New-Item -ItemType Directory -Path (Split-Path -Parent $installedScript) -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $knowledgeRoot 'wiki') -Force | Out-Null
    New-Item -ItemType Directory -Path (Split-Path -Parent $configPath) -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $skillRoot 'scripts/resolve_paths.ps1') -Destination $installedScript
    Set-Content -LiteralPath (Join-Path $knowledgeRoot 'wiki/index.md') -Value '# Synthetic knowledge' -Encoding UTF8
    $indexHash = (Get-FileHash -LiteralPath (Join-Path $knowledgeRoot 'wiki/index.md')).Hash

    Test-Case 'relocated helper; explicit Wiki-only root without config/toolbox' {
        $r = Resolve-Test @{ KnowledgeRoot = $knowledgeRoot }
        Assert-True ($r.knowledge_root -eq $knowledgeRoot -and $r.wiki_available) 'Wrong knowledge root.'
        Assert-True (-not $r.source_available -and -not $r.toolbox_available -and $r.source_version -eq 'unknown') 'Optional resources incorrectly required/reported.'
    }
    Test-Case 'missing required root gives a focused error' {
        Expect-Failure @{} 'Specify an absolute KnowledgeRoot'
    }
    Test-Case 'configuration supplies actual knowledge/toolbox paths' {
        $toolbox = Join-Path $temporaryRoot 'independent toolbox'
        New-Item -ItemType Directory -Path (Join-Path $toolbox 'scripts/tools') -Force | Out-Null
        Write-Config @{ knowledge_root = $knowledgeRoot; toolbox_root = $toolbox; preserved = 'keep' }
        $configHash = (Get-FileHash -LiteralPath $configPath).Hash
        $r = Resolve-Test @{ ConfigPath = $configPath }
        Assert-True ($r.wiki_available -and $r.toolbox_available -and $r.toolbox_root -eq $toolbox) 'Configuration was not used.'
        Assert-True ((Get-FileHash -LiteralPath $configPath).Hash -eq $configHash) 'Configuration changed during resolution.'
    }
    Test-Case 'malformed config reported; explicit root bypasses it' {
        Set-Content -LiteralPath $configPath -Value '{ invalid' -Encoding UTF8
        Expect-Failure @{ ConfigPath = $configPath } 'Cannot read path configuration'
        $r = Resolve-Test @{ KnowledgeRoot = $knowledgeRoot; ConfigPath = $configPath }
        Assert-True $r.wiki_available 'Explicit path did not bypass malformed config.'
    }
    Test-Case 'non-object and non-string required configuration are rejected' {
        foreach ($value in @('[]', 'null', '{"knowledge_root":42}', '{"knowledge_root":false}')) {
            Set-Content -LiteralPath $configPath -Value $value -Encoding UTF8
            Expect-Failure @{ ConfigPath = $configPath } 'Cannot read path configuration'
        }
    }
    Test-Case 'relative and drive-relative roots cannot depend on working directory' {
        Expect-Failure @{ KnowledgeRoot = 'relative/path' } 'Specify an absolute KnowledgeRoot'
        if ([System.IO.Path]::DirectorySeparatorChar -eq '\') {
            Expect-Failure @{ KnowledgeRoot = 'D:relative' } 'Specify an absolute KnowledgeRoot'
            Expect-Failure @{ KnowledgeRoot = '\root-relative' } 'Specify an absolute KnowledgeRoot'
        }
    }
    Test-Case 'wrong root rejected; explicit bootstrap permits it without writes' {
        $emptyRoot = Join-Path $temporaryRoot 'empty knowledge'
        New-Item -ItemType Directory -Path $emptyRoot -Force | Out-Null
        Expect-Failure @{ KnowledgeRoot = $emptyRoot } 'must contain wiki/index.md'
        $r = Resolve-Test @{ KnowledgeRoot = $emptyRoot; AllowUninitialized = $true }
        Assert-True ($r.knowledge_exists -and -not $r.wiki_available) 'Empty root state incorrect.'
        Assert-True (@(Get-ChildItem -LiteralPath $emptyRoot -Force).Count -eq 0) 'Resolver initialized files.'
    }
    Test-Case 'bootstrap permits nonexistent destination without creating it' {
        $newRoot = Join-Path $temporaryRoot 'not created'
        $r = Resolve-Test @{ KnowledgeRoot = $newRoot; AllowUninitialized = $true }
        Assert-True (-not $r.knowledge_exists -and -not (Test-Path -LiteralPath $newRoot)) 'Resolver created destination.'
    }
    Test-Case 'file cannot masquerade as a knowledge directory' {
        $fileRoot = Join-Path $temporaryRoot 'a-file'
        Set-Content -LiteralPath $fileRoot -Value 'preserve' -Encoding ASCII
        Expect-Failure @{ KnowledgeRoot = $fileRoot; AllowUninitialized = $true } 'must be a directory'
    }
    Test-Case 'invalid optional toolbox does not block Wiki use' {
        foreach ($value in @('relative/toolbox', 42, $false)) {
            Write-Config @{ knowledge_root = $knowledgeRoot; toolbox_root = $value }
            $r = Resolve-Test @{ ConfigPath = $configPath }
            Assert-True ($r.wiki_available -and -not $r.toolbox_available -and [bool]$r.toolbox_warning) 'Optional toolbox failure blocked/misreported Wiki.'
        }
        $r = Resolve-Test @{ KnowledgeRoot = $knowledgeRoot; ToolboxRoot = (Join-Path $temporaryRoot 'missing-toolbox') }
        Assert-True ($r.wiki_available -and -not $r.toolbox_available -and [bool]$r.toolbox_warning) 'Missing toolbox blocked Wiki.'
    }
    Test-Case 'explicit absolute toolbox root is used when it exists' {
        $explicitToolbox = Join-Path $temporaryRoot 'explicit toolbox'
        New-Item -ItemType Directory -Path (Join-Path $explicitToolbox 'scripts/tools') -Force | Out-Null
        $r = Resolve-Test @{ KnowledgeRoot = $knowledgeRoot; ToolboxRoot = $explicitToolbox }
        Assert-True ($r.wiki_available -and $r.toolbox_available -and $r.toolbox_root -eq $explicitToolbox) 'Explicit toolbox root was not used.'
        Assert-True (-not $r.toolbox_warning) 'Valid toolbox root reported a warning.'
    }
    Test-Case 'empty source directory is not usable source' {
        New-Item -ItemType Directory -Path (Join-Path $knowledgeRoot 'raw/current/scripts') -Force | Out-Null
        $r = Resolve-Test @{ KnowledgeRoot = $knowledgeRoot }
        Assert-True ($r.source_directory_exists -and -not $r.source_available) 'Empty source directory marked available.'
    }
    Test-Case 'source structure and recorded numeric Steam version reported' {
        foreach ($name in @('class.lua', 'entityscript.lua', 'components/example.lua', 'prefabs/example.lua')) {
            $path = Join-Path $knowledgeRoot ('raw/current/scripts/' + $name)
            New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
            Set-Content -LiteralPath $path -Value '-- synthetic source' -Encoding ASCII
        }
        Set-Content -LiteralPath (Join-Path $knowledgeRoot 'raw/current/BUILD.txt') -Value '101' -Encoding ASCII
        $r = Resolve-Test @{ KnowledgeRoot = $knowledgeRoot }
        Assert-True ($r.source_available -and $r.build_available -and $r.source_version -eq 'steam-buildid:101') 'Source/version not reported.'
    }
    Test-Case 'empty recorded version remains unknown' {
        Set-Content -LiteralPath (Join-Path $knowledgeRoot 'raw/current/BUILD.txt') -Value '' -Encoding ASCII
        $r = Resolve-Test @{ KnowledgeRoot = $knowledgeRoot }
        Assert-True ($r.source_available -and $r.source_version -eq 'unknown') 'Empty version incorrectly identified.'
    }
    Test-Case 'absolute but missing source root is reported without touching current' {
        $missingSource = Join-Path $temporaryRoot 'missing snapshot/scripts'
        $currentHash = (Get-FileHash -LiteralPath (Join-Path $knowledgeRoot 'raw/current/BUILD.txt')).Hash
        $r = Resolve-Test @{ KnowledgeRoot = $knowledgeRoot; SourceRoot = $missingSource }
        Assert-True (-not $r.source_directory_exists -and -not $r.source_available -and -not $r.build_available -and $r.source_version -eq 'unknown') 'Missing historical source was misreported.'
        Assert-True ((Get-FileHash -LiteralPath (Join-Path $knowledgeRoot 'raw/current/BUILD.txt')).Hash -eq $currentHash) 'Current snapshot changed.'
    }
    Test-Case 'explicit historical source preserves current and identifier namespace' {
        $historical = Join-Path $temporaryRoot 'historical snapshot/scripts'
        New-Item -ItemType Directory -Path $historical -Force | Out-Null
        Set-Content -LiteralPath (Join-Path (Split-Path -Parent $historical) 'BUILD.txt') -Value 'dst-build:999' -Encoding ASCII
        $currentHash = (Get-FileHash -LiteralPath (Join-Path $knowledgeRoot 'raw/current/BUILD.txt')).Hash
        $r = Resolve-Test @{ KnowledgeRoot = $knowledgeRoot; SourceRoot = $historical }
        Assert-True ($r.source_root -eq $historical -and $r.source_version -eq 'dst-build:999') 'Historical selection changed namespace or used current.'
        Assert-True ((Get-FileHash -LiteralPath (Join-Path $knowledgeRoot 'raw/current/BUILD.txt')).Hash -eq $currentHash) 'Current snapshot changed.'
        Expect-Failure @{ KnowledgeRoot = $knowledgeRoot; SourceRoot = 'relative/scripts' } 'SourceRoot must be an absolute'
    }
    Assert-True ((Get-FileHash -LiteralPath (Join-Path $knowledgeRoot 'wiki/index.md')).Hash -eq $indexHash) 'Knowledge changed.'
    Write-Output "Completed $passed path cases. User config, real knowledge, and game installation were not used."
} finally {
    $tempBase = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $temporaryRoot.StartsWith($tempBase, [System.StringComparison]::OrdinalIgnoreCase) -or
        -not (Split-Path -Leaf $temporaryRoot).StartsWith('dst-skill-paths-')) {
        throw 'Refusing cleanup outside the verified temporary test directory.'
    }
    if (Test-Path -LiteralPath $temporaryRoot) { Remove-Item -LiteralPath $temporaryRoot -Recurse -Force }
}
