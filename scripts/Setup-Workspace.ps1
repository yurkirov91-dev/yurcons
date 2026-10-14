param([string]$Destination = (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Jurist-Workspace'))
$ErrorActionPreference = 'Stop'
$source = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot)).TrimEnd([IO.Path]::DirectorySeparatorChar)
$target = [IO.Path]::GetFullPath($Destination).TrimEnd([IO.Path]::DirectorySeparatorChar)
if ($target.Equals($source, [StringComparison]::OrdinalIgnoreCase) -or $target.StartsWith($source + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Destination must be outside the source folder. No files changed.'
}
if (Test-Path -LiteralPath $target) {
    throw 'Destination already exists. Choose a new path using -Destination. No files changed.'
}
$parent = Split-Path -Parent $target
if (-not (Test-Path -LiteralPath $parent -PathType Container)) { throw 'Destination parent folder does not exist.' }
$staging = Join-Path $parent ('Jurist-staging-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $staging | Out-Null
try {
    Get-ChildItem -LiteralPath $source -Force | Copy-Item -Destination $staging -Recurse
    [IO.Directory]::Move($staging, $target)
} catch {
    Write-Warning "Copy failed. Any copied files remain at: $staging"
    throw
}
Write-Host "Workspace created: $target"
Write-Host 'Open this folder in your local Codex environment. Read README.md first.'
