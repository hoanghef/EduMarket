[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$submissionRoot = Join-Path $repositoryRoot '_submission'
$requiredDirectories = @('01_SourceCode', '02_Database', '03_Deployment', '04_Testing', '05_Documents', '06_Media')
$problems = [System.Collections.Generic.List[string]]::new()

foreach ($directory in $requiredDirectories) {
  if (-not (Test-Path -LiteralPath (Join-Path $submissionRoot $directory) -PathType Container)) {
    $problems.Add("Missing required directory: $directory")
  }
}
if (-not (Test-Path -LiteralPath (Join-Path $submissionRoot 'README.txt') -PathType Leaf)) {
  $problems.Add('Missing README.txt')
}

$forbiddenNames = @('.env', 'node_modules', '.git', '.dart_tool', 'build', 'coverage', 'dist')
$forbidden = Get-ChildItem -LiteralPath $submissionRoot -Force -Recurse | Where-Object { $forbiddenNames -contains $_.Name }
foreach ($item in $forbidden) {
  $problems.Add("Forbidden staged item: $($item.FullName)")
}

$largeFiles = Get-ChildItem -LiteralPath $submissionRoot -Recurse -File | Where-Object { $_.Length -gt 50MB }
foreach ($file in $largeFiles) {
  $problems.Add("Unusually large file (>50 MB): $($file.FullName)")
}

$bytes = (Get-ChildItem -LiteralPath $submissionRoot -Recurse -File | Measure-Object -Property Length -Sum).Sum
$sizeMb = [math]::Round(($bytes / 1MB), 2)
Write-Output "Submission path: $submissionRoot"
Write-Output "Total size: $sizeMb MB"

if ($problems.Count -gt 0) {
  $problems | ForEach-Object { Write-Warning $_ }
  throw "Submission check failed with $($problems.Count) issue(s)."
}

Write-Output 'Submission check passed: required structure exists and no forbidden/generated directories were found.'
