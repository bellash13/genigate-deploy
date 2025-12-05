# Script pour lister les tags Docker disponibles sur GHCR
# Usage: .\list-tags.ps1

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Tags disponibles sur GHCR" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

$repo = "bellash13/genigate-license-api"

Write-Host "Récupération des tags pour $repo..." -ForegroundColor Yellow
Write-Host ""

# Utiliser l'API GitHub pour lister les versions
try {
    $response = Invoke-RestMethod -Uri "https://api.github.com/users/bellash13/packages/container/genigate-license-api/versions" -Headers @{
        "Accept" = "application/vnd.github.v3+json"
    }
    
    Write-Host "Tags disponibles:" -ForegroundColor Green
    Write-Host "----------------------------------------" -ForegroundColor Gray
    
    foreach ($version in $response) {
        $tags = $version.metadata.container.tags -join ", "
        $created = [DateTime]::Parse($version.created_at).ToString("yyyy-MM-dd HH:mm:ss")
        Write-Host "  $tags" -ForegroundColor White
        Write-Host "    Créé: $created" -ForegroundColor Gray
        Write-Host ""
    }
} catch {
    Write-Host "Erreur: Impossible de récupérer les tags depuis l'API GitHub" -ForegroundColor Red
    Write-Host "Essai avec docker search..." -ForegroundColor Yellow
    Write-Host ""
    
    # Alternative: utiliser skopeo si disponible, sinon afficher les instructions
    Write-Host "Pour voir tous les tags, visitez:" -ForegroundColor Yellow
    Write-Host "https://github.com/bellash13/genicare/pkgs/container/genigate-license-api" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Pour déployer avec un tag spécifique:" -ForegroundColor Yellow
Write-Host "  .\deploy-prod.ps1 <tag>" -ForegroundColor White
Write-Host ""
Write-Host "Exemple:" -ForegroundColor Yellow
Write-Host "  .\deploy-prod.ps1 20251201_1430" -ForegroundColor White
