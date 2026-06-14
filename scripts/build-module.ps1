$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $PSCommandPath
$repoRoot = Resolve-Path -LiteralPath (Join-Path $scriptDir '..')
$distDir = Join-Path $repoRoot 'dist'
$moduleProp = Join-Path $repoRoot 'module.prop'

$version = $null
$versionCode = $null
Get-Content -LiteralPath $moduleProp | ForEach-Object {
    if ($_ -match '^version=(.+)$') {
        $version = $Matches[1]
    } elseif ($_ -match '^versionCode=(.+)$') {
        $versionCode = $Matches[1]
    }
}

if (-not $version -or -not $versionCode) {
    throw 'module.prop must contain version and versionCode.'
}

$archiveName = "Sortify-v$version-vc$versionCode-magisk.zip"
$archivePath = Join-Path $distDir $archiveName
$stageDir = Join-Path ([IO.Path]::GetTempPath()) ('sortify-stage-' + [guid]::NewGuid().ToString('N'))
$verifyDir = Join-Path ([IO.Path]::GetTempPath()) ('sortify-verify-' + [guid]::NewGuid().ToString('N'))

$installFiles = @(
    'module.prop',
    'service.sh',
    'action.sh',
    'common.sh',
    'customize.sh',
    'uninstall.sh',
    'config.json',
    'banner.png',
    'webroot/index.html'
)

$textFiles = @(
    'module.prop',
    'service.sh',
    'action.sh',
    'common.sh',
    'customize.sh',
    'uninstall.sh',
    'config.json',
    'webroot/index.html'
)

function Remove-TempTree {
    param([string] $Path)

    if (-not $Path -or -not (Test-Path -LiteralPath $Path)) {
        return
    }

    $resolved = Resolve-Path -LiteralPath $Path
    $tempRoot = [IO.Path]::GetTempPath()
    if (-not $resolved.Path.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove non-temp path: $($resolved.Path)"
    }

    Remove-Item -LiteralPath $resolved.Path -Recurse -Force
}

function Convert-ToLf {
    param([string] $Path)

    $utf8NoBom = [Text.UTF8Encoding]::new($false)
    $content = [IO.File]::ReadAllText($Path)
    $content = $content -replace "`r`n", "`n"
    $content = $content -replace "`r", "`n"
    [IO.File]::WriteAllText($Path, $content, $utf8NoBom)
}

try {
    New-Item -ItemType Directory -Path $stageDir | Out-Null
    New-Item -ItemType Directory -Path $distDir -Force | Out-Null

    foreach ($file in $installFiles) {
        $source = Join-Path $repoRoot $file
        if (-not (Test-Path -LiteralPath $source)) {
            throw "Missing install file: $file"
        }

        $target = Join-Path $stageDir $file
        $targetDir = Split-Path -Parent $target
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        Copy-Item -LiteralPath $source -Destination $target -Force
    }

    foreach ($file in $textFiles) {
        Convert-ToLf -Path (Join-Path $stageDir $file)
    }

    if (Test-Path -LiteralPath $archivePath) {
        Remove-Item -LiteralPath $archivePath -Force
    }

    Push-Location $stageDir
    try {
        & 7z a -tzip $archivePath .\* | Out-Host
    } finally {
        Pop-Location
    }

    & 7z t $archivePath | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw "7z archive test failed with exit code $LASTEXITCODE."
    }

    New-Item -ItemType Directory -Path $verifyDir | Out-Null
    Expand-Archive -LiteralPath $archivePath -DestinationPath $verifyDir -Force

    $expected = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($file in $installFiles) {
        [void] $expected.Add(($file -replace '\\', '/'))
        if (-not (Test-Path -LiteralPath (Join-Path $verifyDir $file))) {
            throw "Archive is missing expected file: $file"
        }
    }

    $actualFiles = Get-ChildItem -LiteralPath $verifyDir -Recurse -File | ForEach-Object {
        $_.FullName.Substring($verifyDir.Length + 1).Replace('\', '/')
    }
    foreach ($file in $actualFiles) {
        if (-not $expected.Contains($file)) {
            throw "Archive contains unexpected file: $file"
        }
    }

    foreach ($file in $textFiles) {
        $bytes = [IO.File]::ReadAllBytes((Join-Path $verifyDir $file))
        for ($i = 0; $i -lt ($bytes.Length - 1); $i++) {
            if ($bytes[$i] -eq 13 -and $bytes[$i + 1] -eq 10) {
                throw "CRLF detected in archive file: $file"
            }
        }
    }

    Write-Output "Built $archivePath"
} finally {
    Remove-TempTree -Path $stageDir
    Remove-TempTree -Path $verifyDir
}
