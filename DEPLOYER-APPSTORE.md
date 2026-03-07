# 🍎 Guide de déploiement App Store — RamiTN

## Prérequis obligatoires

### Tu as besoin de :
1. **Un Mac** (macOS 13+ Ventura ou plus récent) — PAS possible sur Windows
2. **Xcode 15+** installé depuis le Mac App Store
3. **Un compte Apple Developer** ($99/an) → https://developer.apple.com/programs/
4. **CocoaPods** installé (`sudo gem install cocoapods`)

---

## Étape 1 : Préparer le projet sur Mac

```bash
# Cloner ton repo sur le Mac
git clone https://github.com/mahdi01x/ramitn.git
cd ramitn/mobile

# Installer les dépendances Flutter
flutter pub get

# Installer les pods iOS
cd ios
pod install
cd ..

# Générer les icônes
dart run flutter_launcher_icons
```

## Étape 2 : Configurer le signing dans Xcode

```bash
open ios/Runner.xcworkspace
```

Dans Xcode :
1. Sélectionne **Runner** dans le navigateur de projet
2. Onglet **Signing & Capabilities**
3. Coche **"Automatically manage signing"**
4. Sélectionne ton **Team** (ton compte Apple Developer)
5. Le **Bundle Identifier** est déjà : `com.ramitunisien.ramiTunisien`
   - Si le bundle ID est pris, change-le en `com.ramitn.app` (dans Xcode + Info.plist)

## Étape 3 : Build l'archive iOS

```bash
# Depuis le dossier mobile/
flutter build ipa --release
```

Cela va créer le fichier `.ipa` dans :
```
build/ios/ipa/rami_tunisien.ipa
```

## Étape 4 : Uploader sur App Store Connect

### Option A : Via Xcode (recommandé)
```bash
# Ouvre l'archive dans Xcode
open build/ios/archive/Runner.xcarchive
```
Puis : **Distribute App** → **App Store Connect** → **Upload**

### Option B : Via Transporter
1. Télécharge **Transporter** depuis le Mac App Store
2. Glisse le fichier `.ipa` dedans
3. Clique **Deliver**

### Option C : Via CLI
```bash
xcrun altool --upload-app --type ios \
  --file build/ios/ipa/rami_tunisien.ipa \
  --apiKey YOUR_API_KEY \
  --apiIssuer YOUR_ISSUER_ID
```

## Étape 5 : Configurer dans App Store Connect

Va sur https://appstoreconnect.apple.com :

1. **Mon app** → **+** → **Nouvelle app**
   - Plateforme : iOS
   - Nom : **RamiTN**
   - Langue : Français
   - Bundle ID : `com.ramitunisien.ramiTunisien`
   - SKU : `ramitn-001`

2. **Informations de l'app** :
   - Catégorie : Jeux → Jeux de cartes
   - Sous-catégorie : Jeux de société
   - Classification : 4+ (pas de contenu offensant)

3. **Screenshots requis** (OBLIGATOIRE) :
   - iPhone 6.7" (1290×2796) — au moins 3 screenshots
   - iPhone 6.5" (1284×2778)
   - iPad 12.9" (2048×2732) — si tu supportes iPad
   
   **Astuce** : lance l'app sur simulateur et fais des screenshots :
   ```bash
   flutter run -d "iPhone 15 Pro Max"
   # Puis Cmd+S dans le simulateur pour capturer
   ```

4. **Description** (suggestion) :
   ```
   RamiTN — Le vrai Rami Tunisien ! 🇹🇳
   
   Jouez au rami comme au café, sur votre téléphone !
   
   ✅ Mode hors-ligne contre des bots intelligents
   ✅ Mode en ligne avec vos amis (salons privés par code)
   ✅ Règles authentiques du rami tunisien
   ✅ Ouverture à 71 points avec suite sans joker
   ✅ Ambiance café tunisien avec musique
   ✅ Drag & drop fluide pour ranger vos cartes
   
   Créez une partie, partagez le code, et jouez !
   قهوة و كارطة 🎴
   ```

5. **Mots-clés** : `rami, tunisien, cartes, jeu, café, rummy, tunisie, carte, online, multijoueur`

6. **Politique de confidentialité** : Obligatoire !
   - Tu peux utiliser un générateur gratuit (ex: privacypolicies.com)
   - Héberge-la sur une page GitHub ou ton site

7. **Support URL** : ton email ou une page de contact

## Étape 6 : Soumettre pour review

1. Sélectionne le **build** uploadé
2. Clique **Soumettre pour examen**
3. Apple review prend généralement **24h à 48h**

---

## ⚠️ Points importants

### Tu n'as pas de Mac ?
Options alternatives :
- **GitHub Actions** avec `macos-latest` runner → build + upload automatique
- **Codemagic.io** — CI/CD gratuit pour Flutter, build iOS sans Mac
- **MacInCloud** / **MacStadium** — location de Mac virtuel

### Politique de confidentialité
- **OBLIGATOIRE** pour l'App Store
- Même si tu ne collectes rien, tu dois avoir une page qui le dit

### Export Compliance
- L'app utilise HTTPS (socket.io) → coche "Yes" pour encryption
- Mais c'est une "standard encryption exemption" → pas de problème

### Âge minimum
- Jeu de cartes sans argent réel → classé **4+**
- Si tu ajoutes un chat en ligne → potentiellement **12+**

---

## Configuration CI/CD avec Codemagic (GRATUIT — recommandé si pas de Mac)

1. Va sur https://codemagic.io
2. Connecte ton repo GitHub
3. Sélectionne le workflow **Flutter iOS**
4. Configure :
   - **Xcode version** : 15.4
   - **Flutter version** : stable
   - **Build command** : `flutter build ipa --release`
   - **Code signing** : Upload ton certificat Apple + provisioning profile
5. Lance le build → obtiens le `.ipa`
6. Upload automatique vers App Store Connect

C'est la solution la plus simple si tu n'as pas de Mac !

