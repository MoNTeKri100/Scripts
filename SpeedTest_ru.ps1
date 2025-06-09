# Путь к исполняемому файлу Speedtest
$speedtestPath = ".\speedtest.exe"

# Запрос максимальной скорости загрузки у пользователя
do {
    $maxDownloadInput = Read-Host "Enter provider speed DOWNLOAD Mbit/s"
} while (-not [double]::TryParse($maxDownloadInput, [ref]$null))

$maxDownloadMbps = [double]$maxDownloadInput
$thresholdDownload = $maxDownloadMbps * 0.8  # 80% от максимальной

# Функция установки Speedtest CLI
function Install-SpeedTest {
    if (-not (Test-Path $speedtestPath)) {
        Write-Host "Intsall Speedtest CLI..." -ForegroundColor Yellow

        $arch = if ([Environment]::Is64BitOperatingSystem) { "win64" } else { "win32" }
        $url = "https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-$arch.zip"

        try {
            Invoke-WebRequest -Uri $url -OutFile "speedtest.zip"
            Expand-Archive -Path "speedtest.zip" -DestinationPath . -Force
            Remove-Item "speedtest.zip" -Force

            $exePath = Get-ChildItem -Path ".\speedtest-*" -Recurse -Filter "speedtest.exe" | Select-Object -First 1
            if ($exePath) {
                Copy-Item $exePath.FullName -Destination $speedtestPath -Force
                Remove-Item $exePath.DirectoryName -Recurse -Force
            }

            Write-Host "Speedtest CLI install OK." -ForegroundColor Green
        } catch {
            Write-Host "ERROR Install Speedtest CLI: $_" -ForegroundColor Red
            exit 1
        }
    }
}

# Запуск установки (если нужно)
Install-SpeedTest

# Список ID серверов
$serverIds = @(49870,5768,39860,1907,4247,4718,65484,17039,20200,2732,2661,21456,2697,6827,44487,32983,1348,57807)

Clear-Host

# Заголовок таблицы
Write-Host "`n======================= Speedtest.net Ookla® =========================`n" -ForegroundColor Cyan
$headerFormat = "{0,-10} {1,-20} {2,-20} {3,-10} {4,-15} {5,-15}"
$headerLine = $headerFormat -f "ID server", "Provider", "Location", "Ping (ms)", "Download (Mbit/s)", "Upload (Mbit/s)"
Write-Host $headerLine

# Подчеркивание шапки
$underline = "-" * $headerLine.Length
Write-Host $underline

foreach ($id in $serverIds) {
    try {
        $output = & $speedtestPath --server-id $id --format json
        $data = $output | ConvertFrom-Json

        $downloadMbps = [math]::Round($data.download.bandwidth * 8 / 1MB, 2)
        $uploadMbps   = [math]::Round($data.upload.bandwidth * 8 / 1MB, 2)
        $ping = [math]::Round($data.ping.latency, 2)

        $line = $headerFormat -f $id, $data.server.name, $data.server.location, $ping, "$downloadMbps", "$uploadMbps"

        # Логика отображения
        if ($ping -gt 50 -and $downloadMbps -lt $maxDownloadMbps) {
            # Пинг высокий и загрузка ниже максимума - фон красный, текст черный
            Write-Host $line -BackgroundColor Red -ForegroundColor Black
        }
        elseif ($ping -gt 50) {
            # Только пинг высокий - фон красный, текст белый
            Write-Host $line -BackgroundColor Red -ForegroundColor White
        }
        elseif ($ping -le 50 -and $downloadMbps -lt $thresholdDownload) {
            # Пинг нормальный, но загрузка ниже 80% - фон красный, текст желтый
            Write-Host $line -BackgroundColor Red -ForegroundColor Yellow
        }
        else {
            # Всё в пределах нормы - стандартный цвет
            Write-Host $line
        }
    } catch {
        Write-Warning "ERROR Testin server ID $id"
    }

    Start-Sleep -Seconds 2
}

Write-Host "`nEND TESTING." -ForegroundColor Cyan
