# 🃏 Rami Tunisien - Jouer à Distance

## 🚀 Méthode 1 : LOCALE (même WiFi)

### Étape 1 : Lancer le serveur
```
Double-clique sur LANCER-SERVEUR.bat
```
Note l'adresse IP qui s'affiche (ex: `192.168.1.42`).

### Étape 2 : Lancer l'app
```
cd mobile
flutter run
```

### Étape 3 : Configurer l'app
- Jouer en ligne → ⚙️ (engrenage en haut à droite)
- Mets: `http://192.168.1.42:3000` (ton IP)
- Enregistrer

### Étape 4 : Jouer !
- Joueur 1 : Créer une partie → copie le code
- Joueur 2 : Rejoindre une partie → colle le code

---

## 🌍 Méthode 2 : À DISTANCE (réseaux différents) avec ngrok

### Prérequis
1. Installe ngrok: https://ngrok.com/download
2. Crée un compte gratuit
3. `ngrok config add-authtoken TON_TOKEN`

### Étape 1 : Lancer le serveur
```
Double-clique sur LANCER-SERVEUR.bat
```

### Étape 2 : Lancer ngrok
Dans un AUTRE terminal :
```
ngrok http 3000
```
Tu verras une URL comme : `https://abc123.ngrok-free.app`

### Étape 3 : Configurer l'app
- Jouer en ligne → ⚙️ (engrenage)
- Mets l'URL ngrok: `https://abc123.ngrok-free.app`
- Enregistrer

### Étape 4 : Partager
Envoie cette même URL ngrok à ton ami.
Il fait pareil dans son app.

---

## ☁️ Méthode 3 : DÉPLOYÉ (toujours accessible) avec Render

### Étape 1 : Déployer
1. Push le dossier `simple-server/` sur GitHub
2. Va sur https://render.com
3. New → Web Service
4. Connecte ton repo GitHub
5. Root Directory: `simple-server`
6. Build Command: `npm install`
7. Start Command: `node server.js`
8. Plan: Free

Tu obtiens une URL permanente comme : `https://rami-tunisien-server.onrender.com`

### Étape 2 : Configurer l'app
- ⚙️ → mets l'URL Render
- C'est tout ! Fonctionne 24/7.

