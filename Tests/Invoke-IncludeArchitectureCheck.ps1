<#
.SYNOPSIS
    Validates the repository-local AutoHotkey #Include dependency graph.

.DESCRIPTION
    AutoHotkey includes are source composition, so cycles and imports from
    reusable code into application bootstrap code are easy to introduce and
    difficult to see in a syntax-only check. This script resolves maintained
    repository-local includes, reports missing targets, detects strongly
    connected components, and enforces the dependency boundaries documented in
    docs/ARCHITECTURE.md.
#>

param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$SkipSelfTest
)

$ErrorActionPreference = "Stop"

$excludedRelativePaths = @(
    "Lib/Tools/Gdip/Examples/",
    "Lib/Tools/OCR/Examples/",
    "Lib/Tools/UIA-v2/Examples/",
    "Lib/Tools/WebView/Webview Setup Template/"
)

function ConvertTo-RepoPath {
    param([string]$Root, [string]$Path)
    $resolvedRoot = [IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    $resolvedPath = [IO.Path]::GetFullPath($Path)
    if ($resolvedPath.StartsWith($resolvedRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        return $resolvedPath.Substring($resolvedRoot.Length + 1).Replace('\', '/')
    }
    return $resolvedPath.Replace('\', '/')
}

function Test-IsExcluded {
    param([string]$RelativePath, [string[]]$ExcludedPaths)
    foreach ($prefix in $ExcludedPaths) {
        if ($RelativePath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    return $false
}

function Resolve-IncludeTarget {
    param(
        [string]$Root,
        [IO.FileInfo]$Source,
        [string]$RawTarget
    )

    $target = $RawTarget.Trim()
    if ($target.StartsWith("*i ", [StringComparison]::OrdinalIgnoreCase)) {
        $target = $target.Substring(3).Trim()
    }

    if (($target.StartsWith('"') -and $target.EndsWith('"')) -or
        ($target.StartsWith("'") -and $target.EndsWith("'"))) {
        $target = $target.Substring(1, $target.Length - 2)
    }

    if ($target -match '^<(.+)>$') {
        $libraryPath = $Matches[1]
        if (-not [IO.Path]::HasExtension($libraryPath)) {
            $libraryPath += '.ahk'
        }
        return [IO.Path]::GetFullPath((Join-Path (Join-Path $Root 'Lib') $libraryPath))
    }

    if ($target.Contains('%')) {
        return $null
    }

    return [IO.Path]::GetFullPath((Join-Path $Source.DirectoryName $target))
}

function Get-IncludeGraph {
    param([string]$Root, [string[]]$ExcludedPaths = @())

    $resolvedRoot = [IO.Path]::GetFullPath($Root)
    $graph = @{}
    $missing = [Collections.Generic.List[object]]::new()

    $files = Get-ChildItem -LiteralPath $resolvedRoot -Recurse -Filter '*.ahk' -File
    foreach ($file in $files) {
        $relativeSource = ConvertTo-RepoPath $resolvedRoot $file.FullName
        if (Test-IsExcluded $relativeSource $ExcludedPaths) {
            continue
        }

        $graph[$file.FullName] = [Collections.Generic.List[string]]::new()
        $lineNumber = 0
        foreach ($line in Get-Content -LiteralPath $file.FullName) {
            $lineNumber++
            if ($line -notmatch '^\s*#Include(?:Again)?\s+(.+?)\s*(?:;.*)?$') {
                continue
            }

            $target = Resolve-IncludeTarget $resolvedRoot $file $Matches[1]
            if ($null -eq $target) {
                continue
            }

            if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
                $missing.Add([pscustomobject]@{
                    Source = $relativeSource
                    Line = $lineNumber
                    Target = ConvertTo-RepoPath $resolvedRoot $target
                })
                continue
            }

            $relativeTarget = ConvertTo-RepoPath $resolvedRoot $target
            if (-not (Test-IsExcluded $relativeTarget $ExcludedPaths)) {
                $graph[$file.FullName].Add($target)
            }
        }
    }

    return [pscustomobject]@{ Root = $resolvedRoot; Graph = $graph; Missing = $missing }
}

function Get-IncludeCycles {
    param([hashtable]$Graph)

    $state = @{ Index = 0 }
    $stack = [Collections.Generic.Stack[string]]::new()
    $indices = @{}
    $lowLinks = @{}
    $onStack = @{}
    $components = [Collections.Generic.List[object]]::new()

    function Visit-IncludeNode {
        param([string]$Node)

        $indices[$Node] = $state.Index
        $lowLinks[$Node] = $state.Index
        $state.Index++
        $stack.Push($Node)
        $onStack[$Node] = $true

        foreach ($target in $Graph[$Node]) {
            if (-not $Graph.ContainsKey($target)) {
                continue
            }
            if (-not $indices.ContainsKey($target)) {
                Visit-IncludeNode $target
                $lowLinks[$Node] = [Math]::Min($lowLinks[$Node], $lowLinks[$target])
            } elseif ($onStack[$target]) {
                $lowLinks[$Node] = [Math]::Min($lowLinks[$Node], $indices[$target])
            }
        }

        if ($lowLinks[$Node] -eq $indices[$Node]) {
            $component = [Collections.Generic.List[string]]::new()
            do {
                $member = $stack.Pop()
                $onStack[$member] = $false
                $component.Add($member)
            } while ($member -ne $Node)

            $selfCycle = $component.Count -eq 1 -and $Graph[$Node].Contains($Node)
            if ($component.Count -gt 1 -or $selfCycle) {
                $components.Add($component)
            }
        }
    }

    foreach ($node in $Graph.Keys) {
        if (-not $indices.ContainsKey($node)) {
            Visit-IncludeNode $node
        }
    }

    return ,$components
}

function Get-BoundaryViolations {
    param([string]$Root, [hashtable]$Graph)

    $violations = [Collections.Generic.List[object]]::new()
    foreach ($source in $Graph.Keys) {
        $relativeSource = ConvertTo-RepoPath $Root $source
        foreach ($target in $Graph[$source]) {
            $relativeTarget = ConvertTo-RepoPath $Root $target
            if ($relativeSource.StartsWith('Lib/', [StringComparison]::OrdinalIgnoreCase) -and
                $relativeTarget.Equals('Lib/Core.ahk', [StringComparison]::OrdinalIgnoreCase)) {
                $violations.Add([pscustomobject]@{
                    Rule = 'Reusable Lib files must declare immediate dependencies, not include Lib/Core.ahk.'
                    Source = $relativeSource
                    Target = $relativeTarget
                })
            }
            if (-not $relativeSource.StartsWith('Startup/', [StringComparison]::OrdinalIgnoreCase) -and
                $relativeTarget.StartsWith('Startup/', [StringComparison]::OrdinalIgnoreCase)) {
                $violations.Add([pscustomobject]@{
                    Rule = 'Only Startup files may include Startup bootstrap files.'
                    Source = $relativeSource
                    Target = $relativeTarget
                })
            }
        }
    }
    return $violations
}

function Assert-Check {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) {
        throw "Include architecture self-test failed: $Message"
    }
}

function Invoke-IncludeArchitectureSelfTest {
    $fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('ahk-include-graph-' + [guid]::NewGuid())
    New-Item -ItemType Directory -Path (Join-Path $fixtureRoot 'Lib') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $fixtureRoot 'Startup') -Force | Out-Null
    try {
        Set-Content -LiteralPath (Join-Path $fixtureRoot 'Main.ahk') -Value '#Include Lib\Valid.ahk'
        Set-Content -LiteralPath (Join-Path $fixtureRoot 'Lib\Valid.ahk') -Value 'Valid() => true'
        $valid = Get-IncludeGraph $fixtureRoot
        Assert-Check ($valid.Missing.Count -eq 0) 'valid graph reported a missing include'
        Assert-Check ((Get-IncludeCycles $valid.Graph).Count -eq 0) 'valid graph reported a cycle'

        Set-Content -LiteralPath (Join-Path $fixtureRoot 'Missing.ahk') -Value '#Include DoesNotExist.ahk'
        $missing = Get-IncludeGraph $fixtureRoot
        Assert-Check ($missing.Missing.Count -eq 1) 'missing include was not detected'
        Remove-Item -LiteralPath (Join-Path $fixtureRoot 'Missing.ahk')

        Set-Content -LiteralPath (Join-Path $fixtureRoot 'A.ahk') -Value '#Include B.ahk'
        Set-Content -LiteralPath (Join-Path $fixtureRoot 'B.ahk') -Value '#Include A.ahk'
        $cyclic = Get-IncludeGraph $fixtureRoot
        Assert-Check (@(Get-IncludeCycles $cyclic.Graph).Count -gt 0) 'cycle was not detected'
        Remove-Item -LiteralPath (Join-Path $fixtureRoot 'A.ahk'), (Join-Path $fixtureRoot 'B.ahk')

        Set-Content -LiteralPath (Join-Path $fixtureRoot 'Lib\Core.ahk') -Value 'Core() => true'
        Set-Content -LiteralPath (Join-Path $fixtureRoot 'Lib\Forbidden.ahk') -Value '#Include Core.ahk'
        $forbidden = Get-IncludeGraph $fixtureRoot
        Assert-Check (@(Get-BoundaryViolations $fixtureRoot $forbidden.Graph).Count -eq 1) 'Lib-to-Core boundary violation was not detected'
    } finally {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if (-not $SkipSelfTest) {
    Invoke-IncludeArchitectureSelfTest
    Write-Host 'Include architecture self-tests passed.'
}

$result = Get-IncludeGraph $RepositoryRoot $excludedRelativePaths
$cycles = Get-IncludeCycles $result.Graph
$boundaryViolations = Get-BoundaryViolations $result.Root $result.Graph
$hasFailures = $false

foreach ($item in $result.Missing) {
    $hasFailures = $true
    Write-Host "MISSING: $($item.Source):$($item.Line) -> $($item.Target)"
}

foreach ($component in $cycles) {
    $hasFailures = $true
    $paths = $component | ForEach-Object { ConvertTo-RepoPath $result.Root $_ }
    Write-Host "CYCLE: $($paths -join ' -> ')"
}

foreach ($violation in $boundaryViolations) {
    $hasFailures = $true
    Write-Host "BOUNDARY: $($violation.Source) -> $($violation.Target)"
    Write-Host "          $($violation.Rule)"
}

if ($hasFailures) {
    Write-Host 'Include architecture check failed.'
    exit 1
}

$edgeCount = @($result.Graph.Values | ForEach-Object { $_ }).Count
Write-Host "Include architecture check passed: $($result.Graph.Count) files, $edgeCount resolved edges, no cycles or boundary violations."
exit 0
