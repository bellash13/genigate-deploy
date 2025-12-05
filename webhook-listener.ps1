# Webhook Listener pour Auto-Déploiement
# Ce script écoute sur le port 9000 et redéploie à chaque push GitHub

param(
    [int]$Port = 9000,
    [string]$Secret = "VotreSecretWebhook123!"
)

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:$Port/webhook/")
$listener.Start()

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Webhook Listener démarré sur port $Port" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "En attente de webhooks GitHub..." -ForegroundColor Yellow
Write-Host "Appuyez sur Ctrl+C pour arrêter" -ForegroundColor Gray
Write-Host ""

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        # Lire le body
        $reader = New-Object System.IO.StreamReader($request.InputStream)
        $body = $reader.ReadToEnd()
        $reader.Close()
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$timestamp] Webhook reçu depuis $($request.RemoteEndPoint)" -ForegroundColor Green
        
        # Parser le JSON
        try {
            $payload = $body | ConvertFrom-Json
            
            # Vérifier que c'est un push event
            if ($request.Headers["X-GitHub-Event"] -eq "push") {
                $branch = $payload.ref -replace "refs/heads/", ""
                $pusher = $payload.pusher.name
                
                Write-Host "  Branch: $branch" -ForegroundColor White
                Write-Host "  Pusher: $pusher" -ForegroundColor White
                Write-Host "  Commits: $($payload.commits.Count)" -ForegroundColor White
                
                # Déployer seulement si c'est genigate-v1.10
                if ($branch -eq "genigate-v1.10") {
                    Write-Host ""
                    Write-Host "🚀 Démarrage du déploiement automatique..." -ForegroundColor Yellow
                    Write-Host ""
                    
                    # Attendre que GitHub Actions finisse le build (2-3 minutes)
                    Write-Host "⏳ Attente de 180 secondes pour le build GitHub Actions..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 180
                    
                    # Lancer le déploiement
                    $deployScript = Join-Path $PSScriptRoot "deploy-prod.ps1"
                    if (Test-Path $deployScript) {
                        & $deployScript
                        Write-Host ""
                        Write-Host "✅ Déploiement terminé!" -ForegroundColor Green
                    } else {
                        Write-Host "❌ Erreur: deploy-prod.ps1 introuvable" -ForegroundColor Red
                    }
                    
                    Write-Host ""
                    Write-Host "En attente du prochain webhook..." -ForegroundColor Yellow
                } else {
                    Write-Host "  ⏭️ Branche ignorée (pas genigate-v1.10)" -ForegroundColor Gray
                }
            }
            
            # Répondre OK
            $responseString = '{"status":"ok"}'
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseString)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.OutputStream.Close()
            
        } catch {
            Write-Host "❌ Erreur lors du traitement: $_" -ForegroundColor Red
            $response.StatusCode = 500
            $response.Close()
        }
    }
} finally {
    $listener.Stop()
    Write-Host ""
    Write-Host "Webhook Listener arrêté" -ForegroundColor Yellow
}
