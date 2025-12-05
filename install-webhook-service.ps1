# Script pour installer le Webhook Listener comme Service Windows
# Exécuter en tant qu'Administrateur

param(
    [string]$ServiceName = "GenigateWebhookListener",
    [string]$ServiceDisplayName = "Genigate Auto-Deploy Webhook Listener",
    [string]$ServiceDescription = "Écoute les webhooks GitHub et redéploie automatiquement Genigate",
    [int]$Port = 9000
)

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Installation du Service Windows" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier les droits admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "❌ Ce script doit être exécuté en tant qu'Administrateur" -ForegroundColor Red
    exit 1
}

# Chemins
$scriptPath = Join-Path $PSScriptRoot "webhook-listener.ps1"
$nssm = "C:\Tools\nssm.exe"  # Vous devrez installer NSSM

# Vérifier que webhook-listener.ps1 existe
if (-not (Test-Path $scriptPath)) {
    Write-Host "❌ Erreur: webhook-listener.ps1 introuvable dans $PSScriptRoot" -ForegroundColor Red
    exit 1
}

# Instructions pour installer NSSM si nécessaire
if (-not (Test-Path $nssm)) {
    Write-Host "📥 NSSM n'est pas installé. Installation via Chocolatey..." -ForegroundColor Yellow
    
    # Vérifier si Chocolatey est installé
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host ""
        Write-Host "Pour installer NSSM, vous avez deux options:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Option 1 - Via Chocolatey (recommandé):" -ForegroundColor Cyan
        Write-Host "  1. Installer Chocolatey: https://chocolatey.org/install" -ForegroundColor White
        Write-Host "  2. Exécuter: choco install nssm -y" -ForegroundColor White
        Write-Host ""
        Write-Host "Option 2 - Manuel:" -ForegroundColor Cyan
        Write-Host "  1. Télécharger NSSM: https://nssm.cc/download" -ForegroundColor White
        Write-Host "  2. Extraire dans C:\Tools\" -ForegroundColor White
        Write-Host "  3. Relancer ce script" -ForegroundColor White
        exit 1
    }
    
    choco install nssm -y
    $nssm = "C:\ProgramData\chocolatey\bin\nssm.exe"
}

# Arrêter et supprimer le service s'il existe
$existingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($existingService) {
    Write-Host "Arrêt du service existant..." -ForegroundColor Yellow
    Stop-Service -Name $ServiceName -Force
    & $nssm remove $ServiceName confirm
    Start-Sleep -Seconds 2
}

# Installer le service
Write-Host "Installation du service..." -ForegroundColor Green
& $nssm install $ServiceName "powershell.exe" "-ExecutionPolicy Bypass -File `"$scriptPath`" -Port $Port"
& $nssm set $ServiceName AppDirectory $PSScriptRoot
& $nssm set $ServiceName DisplayName $ServiceDisplayName
& $nssm set $ServiceName Description $ServiceDescription
& $nssm set $ServiceName Start SERVICE_AUTO_START

# Configurer les logs
$logDir = Join-Path $PSScriptRoot "logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}
& $nssm set $ServiceName AppStdout (Join-Path $logDir "webhook-stdout.log")
& $nssm set $ServiceName AppStderr (Join-Path $logDir "webhook-stderr.log")

# Ouvrir le port dans le pare-feu
Write-Host "Configuration du pare-feu..." -ForegroundColor Green
$firewallRule = Get-NetFirewallRule -DisplayName "Genigate Webhook" -ErrorAction SilentlyContinue
if (-not $firewallRule) {
    New-NetFirewallRule -DisplayName "Genigate Webhook" -Direction Inbound -LocalPort $Port -Protocol TCP -Action Allow | Out-Null
}

# Démarrer le service
Write-Host "Démarrage du service..." -ForegroundColor Green
Start-Service -Name $ServiceName

Start-Sleep -Seconds 2

# Vérifier le statut
$service = Get-Service -Name $ServiceName
Write-Host ""
Write-Host "================================" -ForegroundColor Green
Write-Host "Service installé avec succès!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""
Write-Host "Nom du service: $ServiceName" -ForegroundColor White
Write-Host "Statut: $($service.Status)" -ForegroundColor $(if ($service.Status -eq 'Running') { 'Green' } else { 'Red' })
Write-Host "Port: $Port" -ForegroundColor White
Write-Host "Logs: $logDir" -ForegroundColor White
Write-Host ""
Write-Host "Configuration GitHub Webhook:" -ForegroundColor Cyan
Write-Host "  URL: http://VOTRE_IP_PUBLIQUE:$Port/webhook/" -ForegroundColor Yellow
Write-Host "  Content type: application/json" -ForegroundColor White
Write-Host "  Events: Just the push event" -ForegroundColor White
Write-Host ""
Write-Host "Commandes utiles:" -ForegroundColor Cyan
Write-Host "  Voir les logs: Get-Content '$logDir\webhook-stdout.log' -Tail 50 -Wait" -ForegroundColor White
Write-Host "  Redémarrer: Restart-Service $ServiceName" -ForegroundColor White
Write-Host "  Arrêter: Stop-Service $ServiceName" -ForegroundColor White
Write-Host "  Désinstaller: nssm remove $ServiceName confirm" -ForegroundColor White
