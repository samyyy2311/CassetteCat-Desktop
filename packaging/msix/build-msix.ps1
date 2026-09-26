# Packs an installed CassetteCat (cmake --install ... --component runtime) into an unsigned .msix for the
# Microsoft Store, which signs it on submission. Identity values come from Partner Center > Product identity.
param(
    [Parameter(Mandatory)] [string] $InstallDir,
    [Parameter(Mandatory)] [string] $Version,
    [Parameter(Mandatory)] [string] $IdentityName,
    [Parameter(Mandatory)] [string] $Publisher,
    [Parameter(Mandatory)] [string] $PublisherDisplayName,
    [Parameter(Mandatory)] [string] $Output
)
$ErrorActionPreference = 'Stop'

# The Store requires four version parts with the last one zero.
if ($Version -notmatch '^\d+\.\d+\.\d+$') { throw "Version must look like 1.2.3, got '$Version'." }

$stage = Join-Path ([IO.Path]::GetTempPath()) "cassettecat-msix-$([Guid]::NewGuid())"
try {
    Copy-Item -Recurse $InstallDir $stage
    Copy-Item -Recurse (Join-Path $PSScriptRoot 'Assets') (Join-Path $stage 'Assets')
    $manifest = (Get-Content -Raw (Join-Path $PSScriptRoot 'AppxManifest.xml')).
        Replace('@IDENTITY_NAME@', [Security.SecurityElement]::Escape($IdentityName)).
        Replace('@PUBLISHER@', [Security.SecurityElement]::Escape($Publisher)).
        Replace('@PUBLISHER_DISPLAY_NAME@', [Security.SecurityElement]::Escape($PublisherDisplayName)).
        Replace('@VERSION@', "$Version.0")
    Set-Content -Encoding utf8 (Join-Path $stage 'AppxManifest.xml') $manifest

    $makeAppx = Get-Command makeappx.exe -ErrorAction SilentlyContinue
    if (-not $makeAppx) {
        $makeAppx = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x64\makeappx.exe" |
            Sort-Object FullName -Descending | Select-Object -First 1
    }
    if (-not $makeAppx) { throw 'makeappx.exe was not found; install the Windows SDK.' }
    & $makeAppx pack /d $stage /p $Output /o
    if ($LASTEXITCODE -ne 0) { throw "makeappx failed with exit code $LASTEXITCODE." }
} finally {
    Remove-Item -Recurse -Force $stage -ErrorAction SilentlyContinue
}
