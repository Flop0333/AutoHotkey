$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$sourceRoots = @(
    'Lib/Actions',
    'Apps Integrated',
    'Apps Standalone',
    'Dashboards',
    'Startup'
)

$files = foreach ($relativeRoot in $sourceRoots) {
    Get-ChildItem -LiteralPath (Join-Path $repositoryRoot $relativeRoot) -Recurse -File |
        Where-Object { $_.Extension -in '.ahk', '.json' }
}

$definitionPattern = [regex]'Action\(\s*"(?<id>[a-z0-9]+(?:[.-][a-z0-9]+)*)"'
$referencePatterns = @(
    [regex]'"actionId"\s*:\s*"(?<id>[a-z0-9]+(?:[.-][a-z0-9]+)*)"',
    [regex]'(?<![A-Za-z0-9_.])Button\(\s*"(?<id>[a-z0-9]+(?:[.-][a-z0-9]+)*)"',
    [regex]'Gestures\.Add\([^,]+,\s*"(?<id>[a-z0-9]+(?:[.-][a-z0-9]+)*)"',
    [regex]'ActionBinding\.(?:Callback|Invoke)\(\s*"(?<id>[a-z0-9]+(?:[.-][a-z0-9]+)*)"',
    [regex]'ActionRegistry\.Invoke\(\s*"(?<id>[a-z0-9]+(?:[.-][a-z0-9]+)*)"',
    [regex]'AppSpecificHotkey\.Set\([^,]+,\s*"(?<id>[a-z0-9]+(?:[.-][a-z0-9]+)*)"'
)

$definitions = @{}
$references = @{}

foreach ($file in $files) {
    $text = Get-Content -LiteralPath $file.FullName -Raw
    $referenceText = [regex]::Replace($text, '(?m)^\s*;.*$', '')
    foreach ($match in $definitionPattern.Matches($text)) {
        $id = $match.Groups['id'].Value.ToLowerInvariant()
        if (-not $definitions.ContainsKey($id)) { $definitions[$id] = @() }
        $definitions[$id] += $file.FullName
    }

    foreach ($pattern in $referencePatterns) {
        foreach ($match in $pattern.Matches($referenceText)) {
            $id = $match.Groups['id'].Value.ToLowerInvariant()
            if (-not $references.ContainsKey($id)) { $references[$id] = @() }
            $references[$id] += $file.FullName
        }
    }
}

$duplicateDefinitions = @($definitions.GetEnumerator() | Where-Object { @($_.Value | Select-Object -Unique).Count -gt 1 })
$missingDefinitions = @($references.Keys | Where-Object { -not $definitions.ContainsKey($_) } | Sort-Object)

if ($duplicateDefinitions.Count -gt 0) {
    Write-Error ('Duplicate canonical action IDs: ' + (($duplicateDefinitions | ForEach-Object Key) -join ', '))
}
if ($missingDefinitions.Count -gt 0) {
    Write-Error ('Consumer action IDs without canonical definitions: ' + ($missingDefinitions -join ', '))
}

Write-Output "Action reference validation passed: $($definitions.Count) definitions, $($references.Count) referenced IDs."
