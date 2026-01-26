Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
cd "$PSScriptRoot\..\backend"
npx prisma generate
npx prisma migrate dev --name init
npm run seed:db
Write-Host "Migrações aplicadas e seed executado."
