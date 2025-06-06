# Функция для установки speedtest-cli
function Install-SpeedTest {
    if (-not (Test-Path ".\speedtest.exe")) {
        Write-Host "Установка Speedtest CLI..." -ForegroundColor Yellow

        $arch = if ([Environment]::Is64BitOperatingSystem) { "win64" } else { "win32" }
        $url = "https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-$arch.zip"

        try {
            Invoke-WebRequest -Uri $url -OutFile "speedtest.zip"
            Expand-Archive -Path "speedtest.zip" -DestinationPath "." -Force
            Remove-Item "speedtest.zip" -Force

            # Переместим exe в текущую директорию
            Get-ChildItem -Recurse -Filter "speedtest.exe" | ForEach-Object {
                Move-Item $_.FullName -Destination ".\speedtest.exe" -Force
            }

            Write-Host "Speedtest CLI успешно установлен." -ForegroundColor Green
        } catch {
            Write-Host "Ошибка при установке Speedtest CLI: $_" -ForegroundColor Red
            exit 1
        }
    }
}

# Вызов установки
Install-SpeedTest

# Путь к speedtest.exe
$speedtestPath = ".\speedtest.exe"

# Проверка наличия исполняемого файла
if (-not (Test-Path $speedtestPath)) {
    Write-Error "speedtest.exe не найден. Проверьте установку."
    exit 1
}

# Список ID серверов
$serverIds = @(49870,5768,39860,1907,4247,4718,65484,17039,20200,2732,2661,21456,2697,44144,6827,44487,32983,1348,28922)

# Хранилище результатов
$results = @()

# Заголовок
Write-Host "`n=== Результаты тестирования скорости Speedtest.net Ookla ===`n" -ForegroundColor Cyan

foreach ($id in $serverIds) {
    Write-Host "Тест сервера ID $id..." -ForegroundColor Yellow

    # Запуск speedtest
    $output = & $speedtestPath --server-id $id --format json

    if ($LASTEXITCODE -eq 0) {
        $data = $output | ConvertFrom-Json

        $downloadMbps = [math]::Round($data.download.bandwidth * 8 / 1MB, 2)
        $uploadMbps   = [math]::Round($data.upload.bandwidth * 8 / 1MB, 2)
        $ping         = [math]::Round($data.ping.latency, 2)

        $result = [PSCustomObject]@{
            "ID сервера"          = $id
            "Провайдер"           = $data.server.name
            "Локация"             = $data.server.location
            "Пинг (мс)"           = $ping
            "⬇ Загрузка (Мбит/с)" = "⬇ $downloadMbps"
            "⬆ Отдача (Мбит/с)"   = "⬆ $uploadMbps"
        }

        $results += $result

        # Очистка и заголовок — прямо в цикле
        Clear-Host
        Write-Host "`n=== Результаты тестирования скорости Speedtest.net Ookla ===`n" -ForegroundColor Cyan

        # Пошаговый вывод всех накопленных результатов
        foreach ($r in $results) {
            $pingColor = if ($r."Пинг (мс)" -gt 20) { "Red" } else { "White" }

            Write-Host ("ID сервера:          {0}" -f $r."ID сервера")
            Write-Host ("Провайдер:           {0}" -f $r."Провайдер")
            Write-Host ("Локация:             {0}" -f $r."Локация")
            Write-Host ("Пинг (мс):           ") -NoNewline
            Write-Host ("{0}" -f $r."Пинг (мс)") -ForegroundColor $pingColor
            Write-Host ("⬇ Загрузка (Мбит/с): {0}" -f $r."⬇ Загрузка (Мбит/с)")
            Write-Host ("⬆ Отдача (Мбит/с):   {0}" -f $r."⬆ Отдача (Мбит/с)")
            Write-Host ("-----------------------------")
        }
    }
    else {
        Write-Warning "Ошибка при тестировании сервера ID $id"
    }

    Start-Sleep -Seconds 1
}
