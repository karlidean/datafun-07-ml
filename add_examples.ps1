# ================================================
# Script: add_introto_python_examples_contents.ps1
# Purpose: Copy the CONTENTS of examples/ch10 and
#          examples/ch15 from pdeitel/IntroToPython
#          into your local datafun-07-ml repo.
# ================================================

$ErrorActionPreference = "Stop"

# --- CONFIGURATION ---
$sourceRepoUrl   = "https://github.com/pdeitel/IntroToPython.git"
$tempClonePath   = "C:\Repos\_temp_introtoPython"
$targetRepoPath  = "C:\Repos\datafun-07-ml"
$foldersToGet    = @("examples/ch10", "examples/ch15")

# --- PRECHECKS ---
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  throw "Git is not installed or not on PATH."
}
if (-not (Test-Path $targetRepoPath)) {
  throw "Target repo path not found: $targetRepoPath"
}

# --- CLEAN TEMP IF EXISTS ---
if (Test-Path $tempClonePath) {
  Write-Host "Removing old temp folder..." -ForegroundColor Yellow
  Remove-Item -Recurse -Force $tempClonePath
}

# --- CLONE METADATA ONLY ---
Write-Host "Cloning metadata (no files)..." -ForegroundColor Cyan
git clone --no-checkout $sourceRepoUrl $tempClonePath | Out-Null
Set-Location $tempClonePath

# --- DETERMINE DEFAULT BRANCH (main/master/etc.) ---
$originHead = (git symbolic-ref --short refs/remotes/origin/HEAD 2>$null)
if (-not $originHead) {
  # Fallback if the above fails
  $originHead = "origin/main"
}
$defaultBranch = $originHead.Split("/")[1]

# --- ENABLE SPARSE CHECKOUT & SET PATHS ---
git sparse-checkout init --cone
git sparse-checkout set $foldersToGet

# --- CHECKOUT DEFAULT BRANCH ---
git checkout $defaultBranch | Out-Null

# --- COPY CONTENTS ONLY ---
# Explanation:
#   We copy $sourcePath\* (the CONTENTS), not the parent folder itself.
#   We copy into $targetRepoPath\<chapterName>\ (ensures a tidy home).
#   If you'd rather merge contents directly into the repo root, set $putInSubfolders = $false.
$putInSubfolders = $true

foreach ($folder in $foldersToGet) {
  $chapterName = Split-Path $folder -Leaf                      # e.g., "ch10"
  $sourcePath  = Join-Path $tempClonePath $folder
  $destPath    = if ($putInSubfolders) {
                   Join-Path $targetRepoPath $chapterName      # e.g., ...\datafun-07-ml\ch10
                 } else {
                   $targetRepoPath                             # merge into repo root
                 }

  if (-not (Test-Path $sourcePath)) {
    Write-Warning "Source path not found: $sourcePath"
    continue
  }

  if (-not (Test-Path $destPath)) {
    New-Item -ItemType Directory -Force -Path $destPath | Out-Null
  }

  Write-Host "Copying CONTENTS of '$folder' -> '$destPath' ..." -ForegroundColor Green

  # Copy contents only, skip Git metadata, preserve timestamps
  Get-ChildItem -LiteralPath $sourcePath -Recurse -Force `
    | Where-Object { $_.Name -notlike ".git*" } `
    | ForEach-Object {
        $relative = $_.FullName.Substring($sourcePath.Length).TrimStart("\","/")
        $target   = Join-Path $destPath $relative
        if ($_.PSIsContainer) {
          if (-not (Test-Path $target)) { New-Item -ItemType Directory -Force -Path $target | Out-Null }
        } else {
          $targetDir = Split-Path $target -Parent
          if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Force -Path $targetDir | Out-Null }
          Copy-Item -LiteralPath $_.FullName -Destination $target -Force -ErrorAction Stop
          # preserve LastWriteTime
          (Get-Item $target).LastWriteTime = $_.LastWriteTime
        }
      }
}

# --- CLEAN UP TEMP CLONE ---
Set-Location "C:\Repos"
Write-Host "Cleaning up temp clone..." -ForegroundColor Yellow
Remove-Item -Recurse -Force $tempClonePath

Write-Host "`n✅ Done! Copied the CONTENTS of examples/ch10 and examples/ch15 into $targetRepoPath" -ForegroundColor Green
Write-Host "Tip: Commit your changes now:" -ForegroundColor Cyan
Write-Host "  cd `"$targetRepoPath`"" -ForegroundColor DarkGray
Write-Host "  git add .; git commit -m `"Add ch10 & ch15 contents from IntroToPython`"; git push" -ForegroundColor DarkGray
