# 🚀 Déployer le serveur RamiTN sur Render.com

## Prérequis
- Un compte GitHub (gratuit)
- Un compte Render.com (gratuit)

---

## Étape 1 : Push sur GitHub

### Option A : Nouveau repo (recommandé)
1. Va sur https://github.com/new
2. Nom du repo : `ramitn-server`
3. Public ou Private (au choix)
4. Ne coche rien d'autre → Create repository

### Puis dans PowerShell :
```powershell
cd C:\Users\Karim\AndroidStudioProjects\MyApplication

# Initialise git si pas déjà fait
git init

# Ajoute tout
git add simple-server/ render.yaml

# Commit
git commit -m "RamiTN server - ready for Render deployment"

# Ajoute le remote (remplace TON_USERNAME)
git remote add origin https://github.com/TON_USERNAME/ramitn-server.git

# Push
git push -u origin main
```

---

## Étape 2 : Déployer sur Render

1. Va sur https://render.com
2. Clique **"Get Started for Free"** → connecte avec GitHub
3. Clique **"New +"** → **"Web Service"**
4. Connecte ton repo GitHub `ramitn-server`
5. Configure :

| Paramètre | Valeur |
|-----------|--------|
| **Name** | `ramitn-server` |
| **Region** | Frankfurt (EU) ou Ohio (US) |
| **Root Directory** | `simple-server` |
| **Runtime** | Node |
| **Build Command** | `npm install` |
| **Start Command** | `node server.js` |
| **Plan** | Free |

6. Clique **"Create Web Service"**

7. Attends 2-3 minutes que ça se déploie...

8. Tu obtiens une URL comme : **`https://ramitn-server.onrender.com`**

---

## Étape 3 : Vérifier

Ouvre dans ton navigateur :
```
https://ramitn-server.onrender.com
```

Tu dois voir :
```json
{
  "status": "ok",
  "service": "RamiTN Server",
  "rooms": 0,
  "players": 0,
  "uptime": 123
}
```

---

## Étape 4 : Configurer l'app

L'app est déjà configurée avec `https://ramitn-server.onrender.com` par défaut.

Si l'URL Render est différente :
- Ouvre l'app → écran d'accueil → **appui long sur le logo** → entre l'URL → OK

---

## ⚠️ Note sur le plan Free de Render

Le plan gratuit de Render met le serveur en **veille après 15 min d'inactivité**.
La première connexion après la veille prend ~30 secondes (cold start).

### Pour éviter ça (optionnel) :
- Plan Starter à $7/mois → pas de veille
- Ou utilise un service comme UptimeRobot (gratuit) pour ping le serveur toutes les 14 min

---

## Alternative : AWS (plus complexe mais plus fiable)

Si tu veux AWS, les options sont :
1. **AWS Lightsail** ($3.50/mois) — le plus simple
2. **AWS EC2 t2.micro** (gratuit 12 mois)
3. **AWS App Runner** — comme Render mais AWS

Pour Lightsail :
```bash
# Sur l'instance Lightsail (Ubuntu)
sudo apt update && sudo apt install -y nodejs npm
git clone https://github.com/TON_USERNAME/ramitn-server.git
cd ramitn-server/simple-server
npm install
PORT=3000 node server.js &
```

