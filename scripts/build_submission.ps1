[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$submissionRoot = Join-Path $repositoryRoot '_submission'
$sourceOutput = Join-Path $submissionRoot '01_SourceCode'

function Invoke-RobocopyClean {
  param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Destination,
    [string[]]$ExcludedDirectories = @()
  )

  New-Item -ItemType Directory -Force -Path $Destination | Out-Null
  $arguments = @($Source, $Destination, '/E', '/R:1', '/W:1', '/NFL', '/NDL', '/NJH', '/NJS', '/NP',
    '/XF', '.env', '*.log', '*.backup', '*.dump', '*.sql.gz', '*.iml', '.flutter-plugins', '.flutter-plugins-dependencies')
  if ($ExcludedDirectories.Count -gt 0) {
    $arguments += '/XD'
    # Full paths make the exclusion unambiguous for robocopy, including hidden
    # directories such as .dart_tool.
    $arguments += $ExcludedDirectories | ForEach-Object { Join-Path $Source $_ }
  }
  & robocopy @arguments
  if ($LASTEXITCODE -gt 7) {
    throw "robocopy failed for '$Source' with exit code $LASTEXITCODE."
  }
}

if (Test-Path -LiteralPath $sourceOutput) {
  Remove-Item -LiteralPath $sourceOutput -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $sourceOutput | Out-Null

Invoke-RobocopyClean -Source (Join-Path $repositoryRoot 'frontend') -Destination (Join-Path $sourceOutput 'frontend') -ExcludedDirectories @(
  'node_modules', 'build', '.dart_tool', '.git', '.idea', '.vscode', 'coverage', 'dist', 'tmp', 'temp', 'cache', '_submission'
)
Invoke-RobocopyClean -Source (Join-Path $repositoryRoot 'backend') -Destination (Join-Path $sourceOutput 'backend') -ExcludedDirectories @(
  'node_modules', 'build', '.dart_tool', '.git', '.idea', '.vscode', 'coverage', 'dist', 'tmp', 'temp', 'cache', '_submission', 'private_storage', 'src\generated'
)

# Defend against any robocopy version/pattern differences: this cleanup applies
# only inside the just-created staging source folder, never to the repository.
$generatedDirectoryNames = @('node_modules', 'build', '.dart_tool', '.git', '.idea', '.vscode', 'coverage', 'dist', 'tmp', 'temp', 'cache', '_submission', 'private_storage', 'generated')
Get-ChildItem -LiteralPath $sourceOutput -Force -Recurse -Directory |
  Where-Object { $generatedDirectoryNames -contains $_.Name } |
  Sort-Object { $_.FullName.Length } -Descending |
  Remove-Item -Recurse -Force
Get-ChildItem -LiteralPath $sourceOutput -Force -Recurse -File |
  Where-Object { $_.Name -eq '.env' -or $_.Extension -in @('.log', '.backup', '.dump') -or $_.Name -eq '.flutter-plugins-dependencies' -or $_.Extension -eq '.iml' } |
  Remove-Item -Force

# Explicit paths cover hidden Flutter/IDE directories that some Windows
# robocopy builds may preserve despite /XD.
@(
  'frontend\node_modules', 'frontend\build', 'frontend\.dart_tool', 'frontend\.git', 'frontend\.idea', 'frontend\.vscode', 'frontend\coverage',
  'backend\node_modules', 'backend\build', 'backend\.dart_tool', 'backend\.git', 'backend\.idea', 'backend\.vscode', 'backend\coverage',
  'backend\private_storage', 'backend\src\generated'
) | ForEach-Object {
  $stagedPath = Join-Path $sourceOutput $_
  if (Test-Path -LiteralPath $stagedPath) {
    Remove-Item -LiteralPath $stagedPath -Recurse -Force
  }
}

# Keep the two Flutter-generated artifacts explicit as well; they are hidden
# files and must never be present in a hand-in source archive.
$flutterGeneratedFiles = @(
  (Join-Path $sourceOutput 'frontend\.dart_tool'),
  (Join-Path $sourceOutput 'frontend\.flutter-plugins'),
  (Join-Path $sourceOutput 'frontend\.flutter-plugins-dependencies'),
  (Join-Path $sourceOutput 'frontend\edumarket.iml')
)
foreach ($generatedPath in $flutterGeneratedFiles) {
  if (Test-Path -LiteralPath $generatedPath) {
    Remove-Item -LiteralPath $generatedPath -Recurse -Force
  }
}

$bytes = (Get-ChildItem -LiteralPath $submissionRoot -Recurse -File | Measure-Object -Property Length -Sum).Sum
$sizeMb = [math]::Round(($bytes / 1MB), 2)
Write-Output "Submission source copy created: $sourceOutput"
Write-Output "Current _submission size: $sizeMb MB"
if ($sizeMb -gt 200) {
  Write-Warning 'The staging package is larger than 200 MB. Review large files before submitting.'
}
