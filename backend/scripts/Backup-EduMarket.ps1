[CmdletBinding()]
param(
  [string]$DatabaseUrl = $env:DATABASE_URL,
  [string]$OutputDirectory = (Join-Path $PSScriptRoot '..\..\backups')
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($DatabaseUrl)) {
  throw 'DATABASE_URL is required. Set it in the environment or pass -DatabaseUrl.'
}
if (-not (Get-Command pg_dump -ErrorAction SilentlyContinue)) {
  throw 'pg_dump was not found. Install PostgreSQL client tools and add them to PATH.'
}

$resolvedOutput = [System.IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Force -Path $resolvedOutput | Out-Null
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupFile = Join-Path $resolvedOutput "edumarket-$timestamp.backup"

# Custom format is compressed and can be inspected with pg_restore --list.
& pg_dump --format=custom --no-owner --no-privileges --file $backupFile $DatabaseUrl
if ($LASTEXITCODE -ne 0) { throw "pg_dump failed with exit code $LASTEXITCODE." }

Write-Output "Backup created: $backupFile"
