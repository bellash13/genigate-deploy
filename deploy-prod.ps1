# Script de déploiement en production
# Usage: .\deploy-prod.ps1 [tag]
# Exemples: 
#   .\deploy-prod.ps1              # Utilise le tag 'latest'
#   .\deploy-prod.ps1 20251201_1430  # Utilise un tag spécifique

param(
    [string]$ImageTag = "latest",
    [switch]$PullOnly = $false
)

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Déploiement Genigate Production" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Définir le tag d'image
$env:IMAGE_TAG = $ImageTag
Write-Host "Tag Docker: $ImageTag" -ForegroundColor Yellow
Write-Host ""

if ($PullOnly) {
    Write-Host "Mode: Pull uniquement (pas de redémarrage)" -ForegroundColor Yellow
    Write-Host ""
    
    # Pull les nouvelles images
    Write-Host "Téléchargement de la nouvelle image..." -ForegroundColor Green
    docker pull ghcr.io/bellash13/genigate-license-api:$ImageTag
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erreur lors du téléchargement de l'image!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Image téléchargée avec succès!" -ForegroundColor Green
} else {
    # Arrêter les conteneurs existants
    Write-Host "Arrêt des conteneurs existants..." -ForegroundColor Yellow
    docker-compose -p genigate -f docker-compose.prod.yml down
    
    # Pull les nouvelles images
    Write-Host "Téléchargement des nouvelles images..." -ForegroundColor Green
    docker-compose -p genigate -f docker-compose.prod.yml pull
    
    # Démarrer les services
    Write-Host "Démarrage des services..." -ForegroundColor Green
    docker-compose -p genigate -f docker-compose.prod.yml up -d --remove-orphans
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erreur lors du déploiement!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "Attente du démarrage des services (10 secondes)..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    # Vérifier le statut
    Write-Host ""
    Write-Host "Statut des conteneurs:" -ForegroundColor Cyan
    docker ps --filter "name=genigate-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    Write-Host ""
    Write-Host "================================" -ForegroundColor Green
    Write-Host "Déploiement terminé avec succès!" -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Services disponibles:" -ForegroundColor Cyan
    Write-Host "  - Keycloak Admin:    http://localhost:8080/admin" -ForegroundColor White
    Write-Host "  - RabbitMQ Mgmt:     http://localhost:15672" -ForegroundColor White
    Write-Host "  - License-API:       http://localhost:5001/swagger" -ForegroundColor White
    Write-Host "  - Traefik Dashboard: http://localhost:8081" -ForegroundColor White
}
