<#
.SYNOPSIS
    Checks repository documentation links and inventories for drift.
#>

param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$SkipSelfTest
)

$ErrorActionPreference = "Stop"

function ConvertTo-RepoPath {
    param([string]$Root, [string]$Path)
    $rootPath = [IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    $fullPath = [IO.Path]::GetFullPath($Path)
    return $fullPath.Substring($rootPath.Length + 1).Replace('\', '/')
}

function Get-LocalMarkdownLinkErrors {
    param([string]$Root, [string[]]$MarkdownPaths)
    $errors = [Collections.Generic.List[string]]::new()
    foreach ($relativePath in $MarkdownPaths) {
        $filePath = Join-Path $Root $relativePath
        $content = Get-Content -LiteralPath $filePath -Raw
        foreach ($match in [regex]::Matches($content, '!?(?:\[[^\]]*\])\((?<target>[^)]+)\)')) {
            $target = $match.Groups['target'].Value.Trim().Trim('<', '>')
            if ($target -match '^(?:https?://|mailto:|#)') { continue }
            $pathPart = ($target -split '#', 2)[0]
            if ($pathPart -match '\s+["''][^"'']+["'']$') {
                $pathPart = $pathPart -replace '\s+["''][^"'']+["'']$', ''
            }
            $pathPart = [Uri]::UnescapeDataString($pathPart)
            if (-not $pathPart) { continue }
            $resolved = [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $filePath) $pathPart))
            if (-not (Test-Path -LiteralPath $resolved)) { $errors.Add("$relativePath -> $target") }
        }
    }
    return $errors
}

function Get-WorkflowInventoryErrors {
    param([string]$Root)
    $doc = Get-Content -LiteralPath (Join-Path $Root 'docs/AUTOMATION.md') -Raw
    $errors = [Collections.Generic.List[string]]::new()
    foreach ($file in Get-ChildItem -LiteralPath (Join-Path $Root '.github/workflows') -File -Filter '*.yml') {
        if (-not $doc.Contains("../.github/workflows/$($file.Name)")) {
            $errors.Add("Workflow missing from docs/AUTOMATION.md: $($file.Name)")
        }
    }
    return $errors
}

function Get-AppEntryPoints {
    param([string]$Root)
    $entries = [Collections.Generic.List[string]]::new()
    foreach ($area in @('Apps Standalone', 'Apps Integrated')) {
        $areaRoot = Join-Path $Root $area
        foreach ($file in Get-ChildItem -LiteralPath $areaRoot -Recurse -File -Filter '*.ahk') {
            $relativeToArea = $file.FullName.Substring($areaRoot.Length + 1)
            $isRootFile = -not $relativeToArea.Contains([IO.Path]::DirectorySeparatorChar)
            $matchesFolder = $file.BaseName.Equals($file.Directory.Name, [StringComparison]::OrdinalIgnoreCase)
            if ($isRootFile -or $matchesFolder) { $entries.Add((ConvertTo-RepoPath $Root $file.FullName)) }
        }
    }
    $dashboardsRoot = Join-Path $Root 'Dashboards'
    foreach ($directory in Get-ChildItem -LiteralPath $dashboardsRoot -Directory) {
        $preferred = @(
            (Join-Path $directory.FullName 'Dashboard.ahk'),
            (Join-Path $directory.FullName 'Logger Host.ahk'),
            (Join-Path $directory.FullName ($directory.Name + '.ahk'))
        ) | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
        if ($preferred) { $entries.Add((ConvertTo-RepoPath $Root $preferred)) }
    }
    return $entries
}

function Get-AppInventoryErrors {
    param([string]$Root)
    $doc = [Uri]::UnescapeDataString((Get-Content -LiteralPath (Join-Path $Root 'docs/APPS.md') -Raw))
    $errors = [Collections.Generic.List[string]]::new()
    foreach ($entry in Get-AppEntryPoints $Root) {
        if ($doc.IndexOf("../$entry", [StringComparison]::OrdinalIgnoreCase) -lt 0) {
            $errors.Add("App entry point missing from docs/APPS.md: $entry")
        }
    }
    return $errors
}

function Get-IssueFormReferenceErrors {
    param([string]$Root, [string[]]$MarkdownPaths)
    $errors = [Collections.Generic.List[string]]::new()
    $knownReferences = @($MarkdownPaths | ForEach-Object { [Uri]::UnescapeDataString($_) } | Sort-Object Length -Descending)
    foreach ($file in Get-ChildItem -LiteralPath (Join-Path $Root '.github/ISSUE_TEMPLATE') -File -Filter '*.yml') {
        $content = Get-Content -LiteralPath $file.FullName -Raw
        foreach ($known in $knownReferences) { $content = $content.Replace($known, '') }
        foreach ($match in [regex]::Matches($content, '(?i)(?<name>[A-Za-z0-9_.-]+\.md)')) {
            $errors.Add("$($file.Name) references missing document: $($match.Groups['name'].Value)")
        }
    }
    return $errors
}

function Invoke-SelfTest {
    $root = Join-Path ([IO.Path]::GetTempPath()) ('ahk-doc-check-' + [guid]::NewGuid().Guid)
    try {
        New-Item -ItemType Directory -Path (Join-Path $root 'docs') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $root 'README.md') -Value '[valid](docs/guide.md) [missing](docs/nope.md)'
        Set-Content -LiteralPath (Join-Path $root 'docs/guide.md') -Value '# Guide'
        $linkErrors = @(Get-LocalMarkdownLinkErrors $root @('README.md', 'docs/guide.md'))
        if ($linkErrors.Count -ne 1 -or $linkErrors[0] -notmatch 'nope\.md') {
            throw 'Documentation checker self-test failed to identify exactly one missing link.'
        }
    } finally {
        Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if (-not $SkipSelfTest) { Invoke-SelfTest }

$root = [IO.Path]::GetFullPath($RepositoryRoot)
$trackedMarkdown = @(& git -c "safe.directory=$($root.Replace('\', '/'))" -C $root ls-files '*.md')
if ($LASTEXITCODE -ne 0) { throw 'Could not enumerate tracked Markdown files with git.' }

$errors = [Collections.Generic.List[string]]::new()
foreach ($result in Get-LocalMarkdownLinkErrors $root $trackedMarkdown) { $errors.Add($result) }
foreach ($result in Get-WorkflowInventoryErrors $root) { $errors.Add($result) }
foreach ($result in Get-AppInventoryErrors $root) { $errors.Add($result) }
foreach ($result in Get-IssueFormReferenceErrors $root $trackedMarkdown) { $errors.Add($result) }

if ($errors.Count -gt 0) {
    Write-Host "Documentation validation failed:"
    $errors | Sort-Object -Unique | ForEach-Object { Write-Host "- $_" }
    exit 1
}

$entryCount = @(Get-AppEntryPoints $root).Count
$workflowCount = @(Get-ChildItem -LiteralPath (Join-Path $root '.github/workflows') -File -Filter '*.yml').Count
Write-Host "Documentation validation passed: $($trackedMarkdown.Count) Markdown files, $entryCount app entry points, and $workflowCount workflows checked."
exit 0
