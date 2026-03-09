# Guide d'installation - Backend Google Apps Script

## Étape 1 : Récupérer l'ID de votre Google Sheets existant

1. Ouvrez votre Google Sheets existant (celui avec les onglets: registrations, executive_members, etc.)
2. Copiez l'ID du tableur depuis l'URL :
   ```
   https://docs.google.com/spreadsheets/d/VOTRE_SPREADSHEET_ID_ICI/edit
   ```
   L'ID est la longue chaîne de caractères entre `/d/` et `/edit`

## Étape 2 : Créer le Google Apps Script

1. Dans votre Google Sheets, allez dans **Extensions > Apps Script**
2. Si un script existe déjà, vous pouvez le remplacer ou créer un nouveau fichier
3. Copiez-collez le contenu du fichier `Code.gs` fourni
4. **IMPORTANT** : Remplacez `VOTRE_SPREADSHEET_ID_ICI` (ligne 9) par l'ID de votre tableur
5. Sauvegardez le projet (Ctrl+S ou Cmd+S)

## Étape 3 : Déployer le script

1. Cliquez sur **Déployer > Nouveau déploiement**
2. Cliquez sur l'icône ⚙️ (engrenage) à côté de "Sélectionner un type"
3. Choisissez **Application Web**
4. Configurez :
   - **Description** : "Wifaq Association API v1"
   - **Exécuter en tant que** : Moi (votre email)
   - **Qui a accès** : Tout le monde
5. Cliquez sur **Déployer**
6. **Autorisez l'application** (cliquez sur "Autoriser l'accès")
7. **Copiez l'URL du déploiement** - elle ressemble à :
   ```
   https://script.google.com/macros/s/AKfycbxxx.../dev
   ```

## Étape 4 : Configurer l'application Flutter

Utilisez l'URL copiée (celle qui se termine par `/dev`) dans votre commande Flutter :

```powershell
flutter run `
  --dart-define=APPS_SCRIPT_URL="https://script.google.com/macros/s/AKfycbxxx.../dev" `
  --dart-define=APPS_SCRIPT_API_KEY="wifaq_mo94so99ro04ma10"
```

**IMPORTANT** : Utilisez l'URL `/dev` et NON l'URL `/exec` pour éviter les problèmes de redirection.

## Étape 5 : Tester

1. Lancez l'application Flutter
2. Ajoutez un nouvel enregistrement
3. Vérifiez dans Google Sheets que les données apparaissent dans l'onglet "Inscriptions"

## Structure des feuilles créées automatiquement

Le script créera automatiquement ces feuilles dans votre Google Sheets :

- **Inscriptions** : Enregistrements des membres
- **Membres_Bureau** : Membres du bureau exécutif
- **Realisations** : Réalisations de l'association
- **Photos_Realisations** : Photos des réalisations
- **Objectifs** : Objectifs de l'association
- **Manifestations** : Événements et manifestations

## Sécurité

- La clé API `wifaq_mo94so99ro04ma10` est définie dans le script (ligne 8)
- Toutes les requêtes POST doivent inclure cette clé
- Les images sont stockées dans Google Drive avec accès public en lecture seule

## Dépannage

### Erreur "Invalid API key"
- Vérifiez que la clé API dans le script correspond à celle dans votre commande Flutter

### Erreur "HTTP 302" ou "HTTP 405"
- Assurez-vous d'utiliser l'URL `/dev` et non `/exec`

### Les données ne s'affichent pas
- Vérifiez que le SPREADSHEET_ID est correct dans le script
- Vérifiez les logs dans Apps Script : **Exécutions** dans le menu de gauche

### Erreur de permissions
- Réautorisez le script : **Déployer > Gérer les déploiements > Modifier > Déployer**
