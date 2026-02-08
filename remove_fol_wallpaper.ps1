# 1. Configure paths (Please carefully verify these paths)
$acfPath = "D:\SteamLibrary\steamapps\workshop\appworkshop_431960.acf"
$workshopContentPath = "D:\SteamLibrary\steamapps\workshop\content\431960"

if (-not (Test-Path $acfPath)) {
    Write-Host "[!] Cannot find .acf file at: $acfPath" -ForegroundColor Red
    return
}

# 2. Read and parse the .acf file
$content = Get-Content $acfPath -Raw

# Get IDs from WorkshopItemsInstalled
$installedMatch = [regex]::Match($content, '"WorkshopItemsInstalled"\s*\{([\s\S]*?)\n\t\}')
$installedIds = [regex]::Matches($installedMatch.Value, '"(\d+)"\s*\{') | ForEach-Object { $_.Groups[1].Value }

# Filter valid IDs (those containing the "subscribedby" field)
$detailsIds = [regex]::Matches($content, '"(\d+)"\s*\{[^}]*?"subscribedby"') | ForEach-Object { $_.Groups[1].Value }

# Find "orphan" IDs (present in Installed but missing in Details)
$idsToDelete = $installedIds | Where-Object { $_ -notin $detailsIds }

if ($idsToDelete.Count -eq 0) {
    Write-Host "[-] Congratulations! No orphan folders found to delete." -ForegroundColor Green
    return
}

# 3. List directories that will be deleted
Write-Host "--- LIST OF ORPHAN DIRECTORIES FOUND ---" -ForegroundColor Yellow
$foundPaths = @()
foreach ($id in $idsToDelete) {
    $fullPath = Join-Path $workshopContentPath $id
    if (Test-Path $fullPath) {
        Write-Host "-> $fullPath"
        $foundPaths += $fullPath
    }
}

if ($foundPaths.Count -eq 0) {
    Write-Host "[-] The mismatched IDs exist in the .acf file but no physical folders were found on disk." -ForegroundColor Gray
    return
}

Write-Host ("`nTotal: " + $foundPaths.Count + " folders.") -ForegroundColor Cyan

# 4. Show confirmation prompt
$confirmation = Read-Host "Do you want to delete all these folders? (Press 'y' to delete, 'n' to cancel)"

if ($confirmation -eq 'y') {
    Write-Host "`n--- DELETION IN PROGRESS ---" -ForegroundColor Cyan
    foreach ($path in $foundPaths) {
        try {
            Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
            Write-Host "[SUCCESS] Deleted: $path" -ForegroundColor Green
        } catch {
            Write-Host "[ERROR] Unable to delete: $path (The files may be in use)" -ForegroundColor Red
        }
    }
    Write-Host "`n[!] Cleanup process completed." -ForegroundColor Cyan
} else {
    Write-Host "`n[X] Deletion cancelled. No files were modified." -ForegroundColor Yellow
}

# Pause screen to view results
Read-Host "`nPress Enter to exit..."
