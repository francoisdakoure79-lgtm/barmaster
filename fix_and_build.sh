#!/bin/bash

echo "🔧 Correction du fichier login_screen.dart..."

# Chemin du fichier à modifier
FILE="lib/features/auth/presentation/login_screen.dart"

# Vérifier si le fichier existe
if [ ! -f "$FILE" ]; then
    echo "❌ Erreur : Fichier $FILE introuvable"
    exit 1
fi

# Créer une sauvegarde
cp "$FILE" "${FILE}.backup"
echo "✅ Sauvegarde créée : ${FILE}.backup"

# Remplacer le bloc problématique avec sed
# On remplace la méthode _checkConnectivity complète
sed -i 's/_isOnline = result.isNotEmpty && result.first != ConnectivityResult.none;/_isOnline = result != ConnectivityResult.none;/g' "$FILE"

echo "✅ Correction appliquée"
echo ""
echo "📦 Build Flutter Web en cours..."
flutter clean
flutter pub get
flutter build web --release

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build réussi !"
    echo "👉 Lancez le script deploy.sh pour déployer"
else
    echo ""
    echo "❌ Échec du build. Restauration de la sauvegarde..."
    cp "${FILE}.backup" "$FILE"
    echo "✅ Sauvegarde restaurée"
    exit 1
fi
