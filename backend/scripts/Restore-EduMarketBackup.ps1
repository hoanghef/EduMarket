[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$BackupFile,
  [string]$DatabaseUrl = $env:DATABASE_URL,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($DatabaseUrl)) {
  throw 'DATABASE_URL is required. Set it in the environment or pass -DatabaseUrl.'
}
if (-not (Test-Path -LiteralPath $BackupFile)) { throw 'BackupFile was not found.' }
if (-not (Get-Command pg_restore -ErrorAction SilentlyContinue)) {
  throw 'pg_restore was not found. Install PostgreSQL client tools and add them to PATH.'
}
if (-not $Force) {
  throw 'Restore can overwrite database objects. Re-run with -Force only after confirming the target is disposable or backed up.'
}

# Target must already exist. Use a disposable development/test database URL.
& pg_restore --clean --if-exists --no-owner --no-privileges --dbname $DatabaseUrl $BackupFile
if ($LASTEXITCODE -ne 0) { throw "pg_restore failed with exit code $LASTEXITCODE." }

Write-Output 'Restore completed. Run prisma migrate status and application smoke tests next.'
