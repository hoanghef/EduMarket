[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$BackupFile
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $BackupFile)) { throw 'BackupFile was not found.' }
if (-not (Get-Command pg_restore -ErrorAction SilentlyContinue)) {
  throw 'pg_restore was not found. Install PostgreSQL client tools and add them to PATH.'
}

# This is non-destructive: it validates that the archive can be read without
# connecting to or overwriting a database.
& pg_restore --list $BackupFile | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Backup archive validation failed with exit code $LASTEXITCODE." }
Write-Output 'Backup archive dry run passed (pg_restore --list).'
