Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
cd "$PSScriptRoot\.."
docker-compose down
Write-Host "Serviços encerrados."
