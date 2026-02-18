# 🔨 Guide de Build - EDT App

Ce guide explique comment builder l'application pour différentes plateformes.

---

## A faire en premier

Dans le fichier `lib\config\api_config.dart` remplacer `baseUrl` par son backend.

## 📱 Android

### Option 1 : APK Non-Signé (Debug/Test)

Pour un APK de test rapide (non signé, ne fonctionne pas sur Google Play) :

```bash
# Nettoyer le projet
flutter clean

# Récupérer les dépendances
flutter pub get

# Builder l'APK de debug
flutter build apk --debug

# Ou APK de release non signé
flutter build apk --release
```

📦 **Fichier généré :** `build/app/outputs/flutter-apk/app-release.apk`

### Option 2 : APK Signé (Production)

Pour un APK signé prêt pour la distribution :

#### 1. Générer un keystore (première fois seulement)

```bash
cd android/app

keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Vous serez invité à entrer :
- Mot de passe du keystore
- Mot de passe de la clé
- Informations (nom, organisation, etc.)

⚠️ **Sauvegardez ces mots de passe en lieu sûr !**

#### 2. Créer le fichier key.properties

Créez le fichier `android/key.properties` :

```properties
storePassword=VOTRE_MOT_DE_PASSE_STORE
keyPassword=VOTRE_MOT_DE_PASSE_KEY
keyAlias=upload
storeFile=upload-keystore.jks
```

#### 3. Builder l'APK signé

```bash
flutter build apk --release
```

📦 **Fichier généré :** `build/app/outputs/flutter-apk/app-release.apk`

### Option 3 : App Bundle (Google Play)

Pour publier sur Google Play Store :

```bash
flutter build appbundle --release
```

📦 **Fichier généré :** `build/app/outputs/bundle/release/app-release.aab`

---

## 🍎 iOS

### Prérequis

- macOS avec Xcode installé
- Apple Developer Account (pour la distribution)
- Certificats et profils de provisioning configurés

### Build

```bash
# Nettoyer
flutter clean

# Build iOS
flutter build ios --release

# Ouvrir dans Xcode pour archivage
open ios/Runner.xcworkspace
```

Dans Xcode :
1. Product → Archive
2. Distribute App
3. Choisir la méthode de distribution

---

## 🌐 Web

```bash
# Build web
flutter build web --release

# Les fichiers sont dans build/web/
# Déployez sur Firebase Hosting, Netlify, etc.
```

---

## 🖥️ Windows (si le dossier existe)

```bash
flutter build windows --release
```

📦 **Fichier généré :** `build/windows/runner/Release/`

---

## ❌ Problèmes courants

### L'app crash au lancement (APK)

**Symptôme :** L'app s'arrête immédiatement après l'installation

**Solutions :**

1. **Vérifier les permissions** dans `AndroidManifest.xml` :
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
   ```

2. **Vérifier le cleartext traffic** (pour HTTP) :
   ```xml
   <application
       android:usesCleartextTraffic="true"
       android:networkSecurityConfig="@xml/network_security_config">
   ```

3. **Voir les logs** :
   ```bash
   adb logcat | grep -i flutter
   ```

### Erreur de signature

**Erreur :** `Execution failed for task ':app:validateSigningRelease'`

**Solution :** Vérifier que :
- Le fichier `upload-keystore.jks` existe dans `android/app/`
- Le fichier `key.properties` existe dans `android/`
- Les mots de passe sont corrects

Ou builder sans signature :
```bash
flutter build apk --debug
```

### Taille de l'APK trop grande

**Solution :** Builder des APKs séparés par architecture :

```bash
flutter build apk --split-per-abi
```

Génère 3 APKs optimisés :
- `app-armeabi-v7a-release.apk` (ARM 32-bit)
- `app-arm64-v8a-release.apk` (ARM 64-bit)
- `app-x86_64-release.apk` (Intel 64-bit)

---

## 🧪 Tester l'APK

### Installer via ADB

```bash
# Installer l'APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Voir les logs en direct
adb logcat | grep -i flutter
```

### Installer manuellement

1. Transférez l'APK sur votre téléphone
2. Ouvrez le fichier APK
3. Autorisez l'installation depuis des sources inconnues si demandé

---

## 📊 Vérifier la taille du build

```bash
# Analyser la taille de l'APK
flutter build apk --analyze-size

# Générer un rapport détaillé
flutter build apk --release --analyze-size --target-platform android-arm64
```

---

## 🔐 Sécurité

### Fichiers à NE JAMAIS commiter sur Git

- ❌ `android/app/upload-keystore.jks`
- ❌ `android/key.properties`
- ❌ `android/app/google-services.json` (si contient des clés sensibles)
- ❌ `ios/Runner/GoogleService-Info.plist`

Ces fichiers sont déjà dans `.gitignore`.

---

## 🚀 Build automatisé (CI/CD)

### GitHub Actions

Créez `.github/workflows/build.yml` :

```yaml
name: Build APK

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.0.0'
    - run: flutter pub get
    - run: flutter build apk --release
    - uses: actions/upload-artifact@v3
      with:
        name: app-release
        path: build/app/outputs/flutter-apk/app-release.apk
```

---

## 📝 Versions et releases

### Incrémenter la version

Dans `pubspec.yaml` :

```yaml
version: 1.0.1+2
#        ^     ^
#        |     build number (Android versionCode)
#        version name (Android versionName)
```

### Générer un changelog

```bash
git log --oneline --decorate > CHANGELOG.md
```

---

## 🆘 Support

Pour plus d'informations :
- [Documentation Flutter](https://docs.flutter.dev/deployment)
- [Build et release Android](https://docs.flutter.dev/deployment/android)
- [Build et release iOS](https://docs.flutter.dev/deployment/ios)
