# Certificats SSL pour Nginx

## Génération des certificats auto-signés (pour le développement/test)

Sur la VM de production, exécutez ces commandes pour générer les certificats :

```bash
# Créer le dossier ssl s'il n'existe pas
mkdir -p /opt/genigate/docker/nginx/ssl
cd /opt/genigate/docker/nginx/ssl

# Générer une clé privée
openssl genrsa -out genigate.key 2048

# Générer un certificat auto-signé (valide 365 jours)
openssl req -new -x509 -key genigate.key -out genigate.crt -days 365 \
    -subj "/C=FR/ST=IDF/L=Paris/O=Genigate/CN=genigate.local"
```

## Pour un vrai certificat (Let's Encrypt)

Utilisez certbot pour obtenir un certificat valide :

```bash
apt install certbot
certbot certonly --standalone -d votre-domaine.com
```

Les certificats seront dans `/etc/letsencrypt/live/votre-domaine.com/`
