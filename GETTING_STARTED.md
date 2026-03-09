# ✅ GUIDE DE DÉMARRAGE - Wifaq Association App

Bienvenue! Ce guide vous aidera à configurer et tester l'application.

---

## 🚀 OPTION 1: Tester RAPIDEMENT sans Configuration (5 min)

Si vous voulez juste voir l'app fonctionner:**

### Étape 1: Ouvrir PowerShell
```powershell
cd C:\Users\SuperElectro\Wifaq_Association
```

### Étape 2: Lancer l'app en MODE TEST
```powershell
.\run-app.ps1 -Mock
```

**C'est tout!** L'app devrait apparaître avec des données de test.

- Cliquer sur "إضافة عضو" (Add member) → ça marche!  
- Ajouter/modifier/supprimer des membres → tout est local
- Les données ne sont pas sauvegardées entre les redémarrages

---

## ⚙️ OPTION 2: Configuration Réelle avec Google Sheets (15 min)

Si vous voulez que les données soient **sauvegardées dans Google Sheets**:

### Étape 1: Obtenir les clés Google

1. Aller sur https://script.google.com/
2. Ouvrir votre projet Apps Script
3. Cliquer **"Deploy" → "New deployment"**
4. Choisir **"Web app"** dans le dropdown
5. Remplir:
   - Execute as: **Votre email**
   - Who has access: **Anyone**
6. Cliquer **"Deploy"**
7. Copier l'URL affichée, elle ressemble à:

```
https://script.google.com/macros/d/AKfycbw1234567890ABCDEFGHIJKrrP69Q/userweb
```

⚠️ **Gardez cette URL, elle est importante!**

### Étape 2: Créer le fichier de configuration

1. Ouvrir `C:\Users\SuperElectro\Wifaq_Association\.env`  
   **(Si le fichier n'existe pas, copier `.env.example` en `.env`)**

2. Compléter avec vos clés:

```
APPS_SCRIPT_URL=https://script.google.com/macros/d/AKfycbw1234567890ABCDEFGHIJKrrP69Q/userweb
APPS_SCRIPT_API_KEY=AKfycbw1234567890ABCDEFGHIJKrrP69Q
```

Où:
- **APPS_SCRIPT_URL** = l'URL complète copiée ci-dessus
- **APPS_SCRIPT_API_KEY** = la partie entre `/d/` et `/userweb` (ex: `AKfycbw1234567890ABCDEFGHIJKrrP69Q`)

### Étape 3: Lancer l'app

```powershell
.\run-app.ps1
```

L'app devrait maintenant sauvegarder les données dans Google Sheets!

### Étape 4: Vérifier que ça marche

1. Cliquer "إضافة عضو" (Add member)
2. Remplir le formulaire
3. Cliquer "حفظ" (Save)
4. Voir le message vert "تم حفظ العضو بنجاح" (Member saved successfully)
5. Ouvrir votre Google Sheet → les données doivent y être! ✓

---

## 📋 COMMANDES PRINCIPALES

```powershell
# Lancer l'app normalement
.\run-app.ps1

# Lancer en mode test (pas de config nécessaire)
.\run-app.ps1 -Mock

# Lancer sur le web au lieu du mobile
.\run-app.ps1 -Device web

# Lancer avec débogage détaillé (logs)
.\run-app.ps1 -Verbose

# Lancer une suite de tests
flutter test test/cloud_sync_integration_test.dart
```

---

## ❌ SI ÇA NE MARCHE PAS

### Erreur: "Cloud not configured خطأ"

**Cause**: La config Google Sheets n'est pas trouvée

**Solutions**:
1. ✓ Vérifier que le fichier `.env` existe et contient les clés
2. ✓ Relancer PowerShell (fermer/rouvrir)
3. ✓ Utiliser le mode test: `.\run-app.ps1 -Mock`

### Erreur: "Flutter not found"

**Cause**: Flutter n'est pas installé ou PATH n'est pas bon

**Solution**:
```powershell
flutter --version  # Vérifier que Flutter répond
flutter doctor     # Vérifier la configuration
```

### L'app démarre mais pas de bouton "Add member"

**Cause**: Problème de rendu

**Solution**:
```powershell
flutter clean
flutter pub get
.\run-app.ps1 -Mock
```

### Aucune donnée n'apparaît

**Cause**: Google Sheet mal configurée ou Apps Script ne répond pas

**Solutions**:
1. Vérifier la Google Sheet (elle doit avoir les bonnes colonnes)
2. Vérifier les logs de l'Apps Script: https://script.google.com/ > Executions
3. Vérifier les clés (URL et API Key)
4. Relancer l'app

---

## 📚 FICHIERS IMPORTANTS

- **`lib/main.dart`** → Code principal de l'app (4300 lignes)
- **`lib/cloud_sync_mock.dart`** → Mode test sans config
- **`.env`** → Vos clés Google (⚠️ ne pas commit!)
- **`TEST_MODE_QUICK_START.md`** → Plus de détails sur le mode test
- **`SETUP_CLOUD_SYNC.md`** → Documentation complète de la config
- **`run-app.ps1`** → Script pour lancer l'app facilement
- **`test/cloud_sync_integration_test.dart`** → Test suite (optionnel)

---

## ✨ PROCHAINES ÉTAPES

1. ✓ Configurer l'app (déjà fait!)
2. ✓ Tester en local avec quelques données
3. ✓ Ajouter vos photos de membres exécutifs
4. ✓ Exporter un APK si vous voulez déployer: `flutter build apk`
5. ✓ Lancer la suite de tests si vous voulez: `flutter test`

---

## 💬 BESOIN D'AIDE?

- Consulter `SETUP_CLOUD_SYNC.md` pour les détails techniques
- Consulter `TEST_MODE_QUICK_START.md` pour le mode test avancé
- Vérifier les logs: `flutter run -v` (verbose mode)
- Vérifier les Executions dans https://script.google.com/

---

**Bonne chance! 🚀**
