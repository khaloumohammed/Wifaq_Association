# Script pour lancer Flutter avec les bonnes variables d'environnement
# Fichier: run-app.ps1
# 
# Utilisation:
#   .\run-app.ps1               # Lance avec les vraies config Google Sheets
#   .\run-app.ps1 -Mock         # Lance en mode test/offline
#   .\run-app.ps1 -Device "web" # Lance sur le web au lieu du mobile

param(
    [switch]$Mock = $false,
    [string]$Device = "android",
    [switch]$Verbose = $false
)

# Couleurs pour l'output
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }
function Write-Error { Write-Host $args -ForegroundColor Red }

Write-Info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Info "  Wifaq Association Flutter App Launcher"
Write-Info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Charger la config .env si elle existe
$envFile = ".env"
$defines = @{}

if ($Mock) {
    Write-Warning "📋 MODE TEST ACTIVÉ (données factices)"
    Write-Info ""
    Write-Info "ℹ️  Utilisation du MockCloudSyncService"
    Write-Info "   - Pas de configuration Google Sheets requise"
    Write-Info "   - Données stockées en mémoire"
    Write-Info "   - Parfait pour tester l'UI"
    Write-Info ""
} else {
    Write-Info "📊 MODE PRODUCTION (Google Sheets real)"
    Write-Info ""
    
    if (Test-Path $envFile) {
        Write-Success "✓ Fichier .env trouvé"
        Get-Content $envFile | ForEach-Object {
            if ($_ -match '^([^=]+)=(.*)$') {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                if ($key -and $value) {
                    $defines[$key] = $value
                    Write-Info "  ✓ $key = $(if($value.Length -gt 40) { $value.Substring(0,40) + '...' } else { $value })"
                }
            }
        }
    } else {
        Write-Warning "⚠️  Fichier .env non trouvé"
        Write-Warning "   Copier .env.example → .env et y ajouter vos clés"
        Write-Info ""
        Write-Info "   Cherchez APPS_SCRIPT_API_KEY dans:"
        Write-Info "   https://script.google.com/ > Project Settings > Project ID"
        Write-Info ""
        Read-Host "   Appuyez sur Entrée pour continuer..."
    }
}

# Construire la commande flutter run
$cmd = @("run")

# Jours clés
if ($defines.ContainsKey("APPS_SCRIPT_URL")) {
    $cmd += "--dart-define=APPS_SCRIPT_URL=$($defines['APPS_SCRIPT_URL'])"
}
if ($defines.ContainsKey("APPS_SCRIPT_API_KEY")) {
    $cmd += "--dart-define=APPS_SCRIPT_API_KEY=$($defines['APPS_SCRIPT_API_KEY'])"
}
if ($Mock) {
    $cmd += "--dart-define=MODE_TEST=true"
}

if ($Device) {
    $cmd += "-d"
    $cmd += $Device
}

if ($Verbose) {
    $cmd += "--verbose"
}

Write-Info ""
Write-Info "▶️  Lancement en cours..."
Write-Info ""

# Lancer Flutter
flutter @cmd

if ($LASTEXITCODE -eq 0) {
    Write-Success ""
    Write-Success "✓ Arrêt normal de l'app"
} else {
    Write-Error ""
    Write-Error "✗ Erreur lors du lancement (code: $LASTEXITCODE)"
    Write-Error ""
    Write-Error "Solutions possibles:"
    Write-Error "  1. Vérifier que Flutter est installé: flutter --version"
    Write-Error "  2. Vérifier que .env existe et est correct"
    Write-Error "  3. Relancer 'flutter pub get'"
    Write-Error "  4. Utiliser le mode test: .\run-app.ps1 -Mock"
}

Write-Info ""
