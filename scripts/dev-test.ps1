Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

cd "$PSScriptRoot\..\backend"
Write-Host "Executando testes E2E: auth/marketplace/rooms/dm..."
node scripts/test-auth.js
node scripts/test-marketplace.js
node scripts/test-rooms.js
node scripts/test-dm-db.js
Write-Host "Concluído."
