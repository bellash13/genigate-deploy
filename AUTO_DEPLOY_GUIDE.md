# Guide d'Installation - Auto-Déploiement sur Windows Server 2022

## Méthode 1 : Webhook Listener (Simple et Rapide) ⚡

### Étape 1 : Installation sur le Serveur Windows

1. **Cloner le repo sur le serveur** (via AnyDesk)
```powershell
cd E:\
git clone https://github.com/bellash13/genicare.git genigate
cd genigate
git checkout genigate-v1.10
```

2. **Installer NSSM** (pour créer le service Windows)
```powershell
# Option A: Via Chocolatey (recommandé)
choco install nssm -y

# Option B: Manuel
# Télécharger depuis https://nssm.cc/download
# Extraire dans C:\Tools\
```

3. **Installer le service webhook**
```powershell
cd docker
.\install-webhook-service.ps1
```

4. **Vérifier que le service fonctionne**
```powershell
Get-Service GenigateWebhookListener
# Devrait afficher: Running

# Voir les logs en temps réel
Get-Content logs\webhook-stdout.log -Tail 50 -Wait
```

### Étape 2 : Configuration GitHub Webhook

1. Allez sur **GitHub** → votre repo → **Settings** → **Webhooks** → **Add webhook**

2. Configurez :
   - **Payload URL**: `http://VOTRE_IP_SERVEUR:9000/webhook/`
   - **Content type**: `application/json`
   - **Secret**: Laissez vide (ou configurez un secret)
   - **Which events**: Sélectionnez `Just the push event`
   - **Active**: ✅ Coché

3. Cliquez sur **Add webhook**

### Étape 3 : Test

1. **Faire un push depuis votre PC local**
```powershell
# Sur votre PC
echo "# Test" >> README.md
git add .
git commit -m "test: webhook deployment"
git push origin genigate-v1.10
```

2. **Observer sur le serveur**
```powershell
# Sur le serveur Windows (via AnyDesk)
Get-Content E:\genigate\docker\logs\webhook-stdout.log -Tail 50 -Wait
```

Vous devriez voir :
- ✅ Webhook reçu
- ⏳ Attente de 180 secondes pour le build
- 🚀 Déploiement automatique
- ✅ Déploiement terminé

---

## Méthode 2 : GitHub Actions Self-Hosted Runner (Production) 🏭

### Avantages
- ✅ Plus sécurisé (pas de port ouvert)
- ✅ Logs intégrés dans GitHub
- ✅ Pas besoin de webhook public
- ✅ Support des secrets GitHub

### Installation

1. **Sur le serveur Windows, aller sur GitHub**
   - Repo → Settings → Actions → Runners → New self-hosted runner
   - Sélectionnez **Windows**

2. **Exécuter les commandes fournies par GitHub**
```powershell
# Créer un dossier pour le runner
mkdir C:\actions-runner ; cd C:\actions-runner

# Télécharger le runner
Invoke-WebRequest -Uri https://github.com/actions/runner/releases/download/v2.XXX.X/actions-runner-win-x64-2.XXX.X.zip -OutFile actions-runner-win-x64-2.XXX.X.zip

# Extraire
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory("$PWD/actions-runner-win-x64-2.XXX.X.zip", "$PWD")

# Configurer
.\config.cmd --url https://github.com/bellash13/genicare --token VOTRE_TOKEN

# Installer comme service
.\svc.sh install
.\svc.sh start
```

3. **Modifier le workflow GitHub Actions**

Je vais créer un nouveau workflow pour le déploiement automatique :

```yaml
# .github/workflows/deploy-production.yml
name: Deploy to Production

on:
  workflow_run:
    workflows: ["Build and Push Docker Images"]
    types:
      - completed
    branches:
      - genigate-v1.10

jobs:
  deploy:
    runs-on: self-hosted
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    
    steps:
      - name: Pull latest changes
        run: |
          cd E:\genigate
          git pull origin genigate-v1.10
      
      - name: Deploy production
        run: |
          cd E:\genigate\docker
          .\deploy-prod.ps1
```

---

## Comparaison des Méthodes

| Critère | Webhook Listener | Self-Hosted Runner |
|---------|------------------|-------------------|
| **Complexité** | ⭐ Simple | ⭐⭐ Moyen |
| **Sécurité** | ⚠️ Port ouvert | ✅ Pas de port |
| **Setup** | 5 minutes | 15 minutes |
| **Maintenance** | Faible | Moyenne |
| **Logs** | Fichier local | GitHub UI |
| **Secrets** | ❌ Non | ✅ Oui |
| **Recommandé pour** | Dev/Test | Production |

---

## Dépannage

### Webhook ne fonctionne pas
```powershell
# Vérifier le service
Get-Service GenigateWebhookListener

# Vérifier les logs
Get-Content E:\genigate\docker\logs\webhook-stdout.log -Tail 100

# Vérifier le port
Test-NetConnection -ComputerName localhost -Port 9000

# Vérifier le pare-feu
Get-NetFirewallRule -DisplayName "Genigate Webhook"
```

### Redémarrer le service
```powershell
Restart-Service GenigateWebhookListener
```

### Désinstaller le service
```powershell
Stop-Service GenigateWebhookListener
nssm remove GenigateWebhookListener confirm
```

---

## Recommandation

**Pour votre cas (Windows Server 2022 distant via AnyDesk):**

👉 **Commencez avec la Méthode 1 (Webhook)** car :
- Installation en 5 minutes
- Facile à tester
- Parfait pour un environnement de test/staging

👉 **Passez à la Méthode 2 (Runner)** quand :
- Vous avez besoin de plus de sécurité
- Vous voulez utiliser des secrets GitHub
- Vous déployez en production finale
