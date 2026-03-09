# Mode Test Rapide - Tester l'App sans Configuration Cloud

Si vous ne voulez pas configurer Google Sheets tout de suite, vous pouvez tester l'app en mode offline avec des données factices.

## Option 1: Mode Mock (Recommandé pour tester l'UI)

Le fichier `lib/cloud_sync_mock.dart` contient une version offline de CloudSyncService qui stocke les données en mémoire.

### Comment l'utiliser:

**Méthode A: Quick Test (Temporaire)**

Ouvrir `lib/main.dart` et chercher cette ligne (environ ligne 3250):

```dart
class CloudSyncService {
```

Ajouter avant cette classe:

```dart
// MODE TEST - Décommenter pour tester sans config Google Sheets
// #define MODE_TEST

#if MODE_TEST
  typedef CloudSyncService = MockCloudSyncService;
#endif
```

Puis compiler avec:
```bash
flutter run --dart-define=MODE_TEST=true
```

**Méthode B: Plus propre - Créer un wrapper**

Dans `lib/main.dart`, créer une fonction globale après les imports:

```dart
import 'cloud_sync_mock.dart';

// Fonction globale pour obtenir le bon service
CloudSyncServiceBase getCloudSync() {
  // Retourner mock si pas de config, sinon le vrai service
  const hasConfig = String.fromEnvironment('APPS_SCRIPT_API_KEY') != '';
  if (!hasConfig && kDebugMode) {
    return MockCloudSyncService.instance;
  }
  return CloudSyncService.instance;
}

// Puis remplacer CloudSyncService.instance par getCloudSync() dans le code
```

## Option 2: Configuration Google Sheets (Solution définitive)

### Étape 1: Obtenir les identifiants

1. Ouvrir [Google Apps Script Console](https://script.google.com/)
2. Ouvrir votre projet Apps Script
3. Cliquer sur **"Deploy" > "New deployment"**
4. Choisir type: **Web app**
5. Remplir:
   - Execute as: **Your email**
   - Who has access: **Anyone**
6. Cliquer **Deploy**
7. Copier l'URL complète, elle ressemble à:

```
https://script.google.com/macros/d/**AKfycbw_1234567890ABCDEFGHIJ**rrP69Q/userweb
```

**APPS_SCRIPT_API_KEY** = la partie en gras (entre `/d/` et `/userweb`)

**APPS_SCRIPT_URL** = l'URL complète

### Étape 2: Passer les variables à Flutter

#### Sur Windows (PowerShell):

```powershell
$url = "https://script.google.com/macros/d/YOUR_API_KEY/userweb"
$key = "YOUR_API_KEY"

flutter run `
  --dart-define=APPS_SCRIPT_URL=$url `
  --dart-define=APPS_SCRIPT_API_KEY=$key
```

#### Sur Linux/Mac (Bash):

```bash
flutter run \
  --dart-define=APPS_SCRIPT_URL="https://script.google.com/macros/d/YOUR_API_KEY/userweb" \
  --dart-define=APPS_SCRIPT_API_KEY="YOUR_API_KEY"
```

#### Via fichier `.env` (si vous installez `flutter_dotenv`):

1. Créer fichier `.env`:
```
APPS_SCRIPT_URL=https://script.google.com/macros/d/YOUR_API_KEY/userweb
APPS_SCRIPT_API_KEY=YOUR_API_KEY
```

2. Dans `pubspec.yaml`, ajouter:
```yaml
dev_dependencies:
  flutter_dotenv: ^5.1.0
```

3. Dans `lib/main.dart`, ajouter après `main()`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load();
  runApp(const MyApp());
}
```

### Étape 3: Tester

```bash
flutter run
```

Cliquer sur "إضافة عضو" (Add member) → normale screen doit fonctionner maintenant!

## Données de Test (Mode Mock)

Le MockCloudSyncService contient déjà des données:

- **2 executive members** (الرئيس, النائبة الأولى)
- **1 achievement** (قافلة تضامنية)
- **1 objective** (ترسيخ ثقافة التضامن)

Vous pouvez ajouter plus de données en éditant `lib/cloud_sync_mock.dart` dans la section `_mockData`.

## Dépannage

### Erreur: "Cloud not configured خطأ"

**Cause**: Les variables d'environnement ne sont pas passées

**Solution**:
1. Vérifier que vous avez copié les bonnes valeurs (APPS_SCRIPT_URL et APPS_SCRIPT_API_KEY)
2. Utiliser le mode Mock pour tester en l'absence de configuration
3. Relancer `flutter run` avec les bonnes variables `--dart-define`

### Erreur: "No data returned from Google Sheets"

**Cause**: La Google Sheet n'existe pas ou l'Apps Script n'est pas configurée correctement

**Solution**:
1. Vérifier que la Google Sheet existe et est accessible
2. Vérifier que l'Apps Script a les bons noms de feuilles
3. Vérifier les logs de l'Apps Script (Apps Script > Executions)

### Mode Mock ne fonctionne pas

**Solution**: 
1. Vérifier que `lib/cloud_sync_mock.dart` est présent
2. Vérifier la syntaxe du code wrapper
3. Compiler en mode debug: `flutter run -d all --verbose`

## Commandes Rapides

```bash
# Compiler et lancer l'app
flutter run

# Avec configuration Google Sheets
flutter run --dart-define=APPS_SCRIPT_URL="..." --dart-define=APPS_SCRIPT_API_KEY="..."

# Mode debug avec logs détaillés
flutter run -vm-service-port 8181 --verbose

# Nettoyer le cache et relancer
flutter clean
flutter pub get
flutter run
```

---

**Prochaines étapes après celui-ci**:
1. ✅ Tester l'UI avec Mode Mock
2. ✅ Configurer Google Sheets
3. ✅ Tester avec vraies données
4. ✅ Lancer le test suite: `flutter test test/cloud_sync_integration_test.dart`
