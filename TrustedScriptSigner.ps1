param (
    [string]$CN,  # Параметр для передачи CN сертификата
    [string]$Path # Параметр для передачи пути к скриптам
)

# Если путь не передан, запрашиваем его у пользователя
if (-not $Path) {
    $Path = Read-Host "`nВведите путь, по которому находятся скрипты"
}

# Получаем все сертификаты для подписи
$certs = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert

# Проверяем, найдены ли сертификаты
if (-not $certs) {
    Write-Host "Сертификаты для подписи не найдены!" -ForegroundColor Red
    exit
}

# Если CN передан, ищем соответствующий сертификат
if ($CN) {
    $cert = $certs | Where-Object { $_.Subject -match "CN=$CN" }
    if (-not $cert) {
        Write-Host "Сертификат с CN=$CN не найден!" -ForegroundColor Red
        exit
    }
} else {
    # Если CN не передан, предлагаем выбрать сертификат из списка
    Write-Host "`nВыберите сертификат для подписи:`n" -ForegroundColor Cyan
    for ($i = 0; $i -lt $certs.Count; $i++) {
        Write-Host "$($i + 1). $($certs[$i].Subject)" -ForegroundColor Yellow
    }
    $choice = Read-Host "`nВведите номер сертификата"
    if ($choice -match '^\d+$' -and $choice -le $certs.Count) {
        $cert = $certs[$choice - 1]
    } else {
        Write-Host "Некорректный выбор!" -ForegroundColor Red
        exit
    }
}

# Получаем все .ps1 файлы в указанной директории и её поддиректориях
$scripts = Get-ChildItem -Path $Path -Recurse -Filter *.ps1

# Проверяем, найдены ли скрипты
if (-not $scripts) {
    Write-Host "Скрипты для подписи не найдены!" -ForegroundColor Red
    exit
}

# Подписываем каждый скрипт с прогресс-баром
$totalScripts = $scripts.Count
$currentScript = 0

foreach ($script in $scripts) {
    $currentScript++
    $progress = [math]::Round(($currentScript / $totalScripts) * 100)
    Write-Progress -Activity "Подписание скриптов" -Status "Подписание $($script.FullName)" -PercentComplete $progress

    try {
        # Подписываем скрипт
        Set-AuthenticodeSignature -FilePath $script.FullName -Certificate $cert
        Write-Host "Скрипт $($script.FullName) успешно подписан." -ForegroundColor Green
    } catch {
        Write-Host "Ошибка при подписании скрипта $($script.FullName): $_" -ForegroundColor Red
    }
}

Write-Host "`nПодписание всех скриптов завершено.`n" -ForegroundColor Cyan
