Param(
  [string]$Host = "localhost",
  [int]$Port = 5432,
  [string]$AdminUser = "postgres",
  [string]$PsqlPath = "C:\Program Files\PostgreSQL\16\bin\psql.exe"
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (!(Test-Path $PsqlPath)) {
  Write-Error "psql não encontrado em $PsqlPath. Ajuste o caminho para sua instalação do PostgreSQL."
}

$pwd = Read-Host -Prompt "Senha do usuário $AdminUser" -AsSecureString
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwd))
$env:PGPASSWORD = $plain

& $PsqlPath -h $Host -p $Port -U $AdminUser -f "$PSScriptRoot\psql-bootstrap.sql"

Write-Host "Banco poketibia e usuário poketibia criados com sucesso."
