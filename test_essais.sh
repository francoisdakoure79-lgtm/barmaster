#!/bin/bash
echo "╔══════════════════════════════════════╗"
echo "║   BARMASTER - Préparation Essais   ║"
echo "╚══════════════════════════════════════╝"
echo ""

echo "1️⃣  Build final..."
flutter build web --release
echo ""

echo "2️⃣  Déploiement Vercel..."
cd build/web
vercel --prod
echo ""

echo "3️⃣  URL de l'app :"
echo "   https://web-opal-two-69.vercel.app"
echo ""

echo "✅ Prêt pour les tests !"
echo ""
echo "📋 Checklist de test :"
echo "   [ ] Connexion admin"
echo "   [ ] Connexion caissier"
echo "   [ ] Connexion serveur"
echo "   [ ] Page Ventes"
echo "   [ ] Page Stocks"
echo "   [ ] Page Achats"
echo "   [ ] Page Stats"
echo "   [ ] Paramètres > Historique ventes"
echo "   [ ] Paramètres > Synchro Supabase"
echo "   [ ] Paramètres > Sauvegarde auto"
echo "   [ ] Paramètres > Mon bar"
echo "   [ ] Paramètres > Utilisateurs"
echo "   [ ] Paramètres > Impressions"
echo "   [ ] Paramètres > Rapports"
echo "   [ ] Paramètres > Catégories"
echo "   [ ] Paramètres > À propos"
echo "   [ ] Mode hors connexion (couper WiFi après connexion)"
