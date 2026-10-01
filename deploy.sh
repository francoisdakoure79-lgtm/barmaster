#!/bin/bash

echo "🚀 Déploiement sur Vercel..."

# Vérifier si le dossier build existe
if [ ! -d "build/web" ]; then
    echo "❌ Erreur : Dossier build/web introuvable"
    echo "👉 Lancez d'abord fix_and_build.sh"
    exit 1
fi

cd build/web

# Vérifier si Vercel CLI est installé
if ! command -v vercel &> /dev/null; then
    echo "❌ Vercel CLI non installé"
    echo "👉 Installation avec : npm i -g vercel"
    exit 1
fi

echo "📤 Déploiement en production..."
vercel --prod

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Déploiement réussi ! 🎉"
else
    echo ""
    echo "❌ Échec du déploiement"
    exit 1
fi
