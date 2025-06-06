# Путь к speedtest.exe
$speedtestPath = "C:\Windows\System32\speedtest.exe"

# Список ID серверов
$serverIds = @(48045, 1268)  # Замени на нужные ID

# Хранилище результатов
$results = @()

# Заголовок
Write-Host "`n=== Результаты тестирования скорости Speedtest.net Ookla  ===`n" -ForegroundColor Cyan

foreach ($id in $serverIds) {
    Write-Host "Получение информации о сервере ID $id..." -ForegroundColor Yellow

    # Получаем информацию о сервере
    $serverInfoJson = & $speedtestPath -L --format json
    $serverList = $serverInfoJson | ConvertFrom-Json

    $currentServer = $serverList.servers | Where-Object { $_.id -eq "$id" }

    if ($null -ne $currentServer) {
        $provider = $currentServer.name
        $location = $currentServer.location

        Write-Host "Тест сервера: ID $id | Провайдер: $provider | Локация: $location" -ForegroundColor Green

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

            # Очистка и заголовок
            Clear-Host
            Write-Host "`n=== Результаты тестирования скорости Speedtest.net Ookla  ===`n" -ForegroundColor Cyan

            # Вывод вручную с цветом только у значения пинга
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
    }
    else {
        Write-Warning "Не удалось найти информацию о сервере ID $id"
    }

    Start-Sleep -Seconds 0
}
