# Gestion des Déploiements Production

## Tags Docker

Chaque push sur la branche `genigate-v1.10` crée automatiquement deux tags Docker :
- `latest` : Toujours la dernière version
- `yyyyMMdd_HHmm` : Tag horodaté (ex: `20251201_1430`)

Les tags horodatés permettent de :
- ✅ Revenir à une version antérieure facilement
- ✅ Tracer exactement quelle version est déployée
- ✅ Tester une version spécifique avant de la mettre en production

## Scripts de Déploiement

### 1. Déployer en production

**Déployer la dernière version (latest) :**
```powershell
cd docker
.\deploy-prod.ps1
```

**Déployer une version spécifique :**
```powershell
cd docker
.\deploy-prod.ps1 20251201_1430
```

**Télécharger une image sans redémarrer :**
```powershell
cd docker
.\deploy-prod.ps1 20251201_1430 -PullOnly
```

### 2. Lister les tags disponibles

```powershell
cd docker
.\list-tags.ps1
```

Ou visitez directement :
https://github.com/bellash13/genicare/pkgs/container/genigate-license-api

### 3. Rollback vers une version antérieure

```powershell
cd docker
.\deploy-prod.ps1 20251201_1200  # Utilisez le tag de la version précédente
```

## Workflow Complet

### 1. Développement local
```powershell
# Modifier le code
# Tester localement
.\start-dev.ps1
.\test-dev.ps1
```

### 2. Commit et Push
```powershell
git add .
git commit -m "feat: nouvelle fonctionnalité"
git push origin genigate-v1.10
```

### 3. Attendre le Build GitHub Actions
- Visitez : https://github.com/bellash13/genicare/actions
- Attendez que le build soit vert (✓)
- Notez le tag horodaté créé (visible dans les logs)

### 4. Déployer en Production
```powershell
cd docker

# Option 1: Déployer latest
.\deploy-prod.ps1

# Option 2: Déployer un tag spécifique
.\list-tags.ps1  # Voir les tags disponibles
.\deploy-prod.ps1 20251201_1430
```

### 5. Vérifier le Déploiement
```powershell
# Vérifier les conteneurs
docker ps --filter "name=genigate-"

# Tester les services
.\test-prod.ps1
```

## Variables d'Environnement

Le fichier `.env` dans le dossier `docker/` permet de configurer :

```env
# Tag Docker à utiliser (par défaut: latest)
IMAGE_TAG=latest

# Ou utiliser un tag spécifique
IMAGE_TAG=20251201_1430
```

## Exemples Pratiques

### Scénario 1 : Déploiement Standard
```powershell
# 1. Push du code
git push origin genigate-v1.10

# 2. Attendre GitHub Actions (2-3 min)

# 3. Déployer
cd docker
.\deploy-prod.ps1
```

### Scénario 2 : Rollback d'Urgence
```powershell
# 1. Lister les versions
cd docker
.\list-tags.ps1

# 2. Déployer la version précédente
.\deploy-prod.ps1 20251201_1200
```

### Scénario 3 : Test d'une Nouvelle Version
```powershell
# 1. Télécharger l'image sans déployer
.\deploy-prod.ps1 20251201_1500 -PullOnly

# 2. Tester manuellement
docker run -it --rm ghcr.io/bellash13/genigate-license-api:20251201_1500 /bin/bash

# 3. Si OK, déployer
.\deploy-prod.ps1 20251201_1500
```

## Bonnes Pratiques

1. **Toujours noter le tag déployé en production**
   - Conservez un historique des déploiements
   - Utilisez des tags horodatés pour la traçabilité

2. **Tester avant de déployer**
   - Utilisez `-PullOnly` pour pré-télécharger
   - Vérifiez les logs GitHub Actions avant de déployer

3. **Planifier les rollbacks**
   - Gardez toujours le tag de la version précédente
   - En cas de problème, rollback immédiatement

4. **Monitorer après déploiement**
   - Vérifiez les logs : `docker logs genigate-license-api`
   - Testez les endpoints : `http://localhost:5001/swagger`
