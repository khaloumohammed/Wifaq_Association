# Configuration de la Synchronisation Google Sheets

## 🔴 Erreur: "Cloud not configured"

Tu dois passer **deux** variables d'environnement à `flutter run`.

## ✅ Solution

### 1. Obtenir ta clé API

Ouvre ton **Apps Script Google**:
- L'URL actuelle du Apps Script dans l'app
- Va à **Project Settings** (⚙️ engrenage en bas à gauche)
- Copie le **Script ID**

### 2. Lancer l'app avec la configuration

**PowerShell:**
```powershell
$URL="https://script.google.com/macros/s/AKfycbyPATgRKqC6KC5TN1OrO7YfY_g9CqKOcqG0qe_1PgU5yEixbD-mpPpxC1h_nv-5edWe/exec"
$KEY="YOUR_SCRIPT_ID_HERE"

flutter run --dart-define=APPS_SCRIPT_URL=$URL --dart-define=APPS_SCRIPT_API_KEY=$KEY
```

**Bash/Terminal:**
```bash
flutter run \
  --dart-define=APPS_SCRIPT_URL="https://script.google.com/macros/s/AKfycbyPATgRKqC6KC5TN1OrO7YfY_g9CqKOcqG0qe_1PgU5yEixbD-mpPpxC1h_nv-5edWe/exec" \
  --dart-define=APPS_SCRIPT_API_KEY="YOUR_SCRIPT_ID_HERE"
```

### 3. Alternative: Fichier de configuration

Créer un fichier `.env.local`:
```
APPS_SCRIPT_URL=https://script.google.com/macros/s/...
APPS_SCRIPT_API_KEY=YOUR_KEY
```

Puis utiliser un package comme `flutter_dotenv` pour le charger.

## 📋 Vérification

Une fois configuré, tu devrais:
1. Ouvrir l'app
2. Appuyer sur "إضافة عضو" (Ajouter un membre)
3. Remplir les infos
4. Cliquer "حفظ"
5. Voir le message: ✅ "تم حفظ العضو بنجاح"
6. Les données apparaîtront dans ta Google Sheets

## 🔧 Troubleshooting

### "Exception: Cloud not configured"
→ Assure-toi d'avoir passé BOTH `--dart-define=APPS_SCRIPT_URL` ET `--dart-define=APPS_SCRIPT_API_KEY`

### "HTTP 403" ou "Permission denied"
→ Vérifie que les permissions sur Apps Script sont correctes
→ L'Apps Script doit être déployé et accessible

### Les données ne s'enregistrent pas dans Sheets
→ Appuie sur le bouton "حفظ السحابة" (Sauvegarder nuage) pour forcer la sync
→ Vérifiée que ta Google Sheets a les colonnes: `id`, `name`, `role`, `order_index`, `photo_url`, `is_deleted`, etc.

## 📞 Besoin d'aide?

1. Vérifier les logs: cherche "Cloud not configured" dans la console
2. Vérifier que kAppsScriptApiKey n'est pas vide:
   ```dart
   print(kAppsScriptApiKey.isEmpty ? "❌ API_KEY missing" : "✓ API_KEY set");
   ```
3. Teste l'URL directement dans le navigateur pour voir si elle répond
