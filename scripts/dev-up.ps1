Param(
  [int]$ApiPort = 3000
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function ComposeUp {
  cd "$PSScriptRoot\.."
  docker-compose up -d db redis minio
}
function Wait-Db {
  Write-Host "Aguardando Postgres ficar saudável..."
  for ($i=0; $i -lt 20; $i++) {
    try {
      $health = docker inspect -f "{{.State.Health.Status}}" pokegentrade-db
      if ($health -eq "healthy") { Write-Host "Postgres saudável"; return }
    } catch {}
    Start-Sleep -Seconds 2
  }
  Write-Host "Aviso: Postgres pode não estar saudável ainda"
}
function PreparePrisma {
  cd "$PSScriptRoot\..\backend"
  & npx prisma generate
  & npx prisma db push
  & npm run seed:db
}
function StartApi {
  cd "$PSScriptRoot\..\backend"
  Start-Process -WindowStyle Minimized powershell -ArgumentList "-NoProfile -Command npm run start:dev"
}

ComposeUp
Wait-Db
PreparePrisma
StartApi
Write-Host "API iniciada em http://localhost:$ApiPort e serviços db/redis/minio em execução."
