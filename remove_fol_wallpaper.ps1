# 1. Cấu hình đường dẫn (Hãy kiểm tra kỹ các đường dẫn này)
$acfPath = "D:\SteamLibrary\steamapps\workshop\appworkshop_431960.acf"
$workshopContentPath = "D:\SteamLibrary\steamapps\workshop\content\431960"

if (-not (Test-Path $acfPath)) {
    Write-Host "[!] Khong tim thay file .acf tai: $acfPath" -ForegroundColor Red
    return
}

# 2. Đọc và phân tích file .acf
$content = Get-Content $acfPath -Raw

# Lấy ID từ WorkshopItemsInstalled
$installedMatch = [regex]::Match($content, '"WorkshopItemsInstalled"\s*\{([\s\S]*?)\n\t\}')
$installedIds = [regex]::Matches($installedMatch.Value, '"(\d+)"\s*\{') | ForEach-Object { $_.Groups[1].Value }

# Lọc ID hợp lệ (có trường "subscribedby")
$detailsIds = [regex]::Matches($content, '"(\d+)"\s*\{[^}]*?"subscribedby"') | ForEach-Object { $_.Groups[1].Value }

# Tìm các ID "mồ côi" (Có trong Installed nhưng không có trong Details)
$idsToDelete = $installedIds | Where-Object { $_ -notin $detailsIds }

if ($idsToDelete.Count -eq 0) {
    Write-Host "[-] Chuc mung! Khong co thu muc mo coi nao can xoa." -ForegroundColor Green
    return
}

# 3. Liệt kê danh sách các đường dẫn sẽ bị xóa
Write-Host "--- DANH SACH THU MUC MO COI TIM THAY ---" -ForegroundColor Yellow
$foundPaths = @()
foreach ($id in $idsToDelete) {
    $fullPath = Join-Path $workshopContentPath $id
    if (Test-Path $fullPath) {
        Write-Host "-> $fullPath"
        $foundPaths += $fullPath
    }
}

if ($foundPaths.Count -eq 0) {
    Write-Host "[-] Cac ID khac biet ton tai trong file .acf nhung khong tim thay thu muc vat ly tren o dia." -ForegroundColor Gray
    return
}

Write-Host ("`nTong cong: " + $foundPaths.Count + " thu muc.") -ForegroundColor Cyan

# 4. Hiển thị câu hỏi xác nhận
$confirmation = Read-Host "Ban co muon xoa tat ca cac thu muc tren khong? (An 'y' de xoa, 'n' de huy)"

if ($confirmation -eq 'y') {
    Write-Host "`n--- DANG TIEN HANH XOA ---" -ForegroundColor Cyan
    foreach ($path in $foundPaths) {
        try {
            Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
            Write-Host "[THANH CONG] Da xoa: $path" -ForegroundColor Green
        } catch {
            Write-Host "[LOI] Khong the xoa: $path (Co the file dang mo)" -ForegroundColor Red
        }
    }
    Write-Host "`n[!] Da hoan tat qua trinh don dep." -ForegroundColor Cyan
} else {
    Write-Host "`n[X] Da huy lenh xoa. Khong co file nao bi thay doi." -ForegroundColor Yellow
}

# Dung man hinh de xem ket qua
Read-Host "`nAn Enter de thoat..."