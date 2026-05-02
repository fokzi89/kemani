$lines = netstat -ano | Select-String ":5173\s"
foreach ($line in $lines) {
    $parts = $line.ToString().Trim() -split "\s+"
    $pid2 = $parts[-1]
    if ($pid2 -match "^\d+$") {
        Stop-Process -Id ([int]$pid2) -Force -ErrorAction SilentlyContinue
        Write-Host "Killed PID $pid2"
    }
}
Write-Host "Port 5173 freed"
