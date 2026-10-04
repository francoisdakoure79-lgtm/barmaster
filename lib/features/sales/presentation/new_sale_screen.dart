import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/models/product.dart';
import '../../../core/services/print_service.dart';
import '../../../core/services/pdf_ticket_service.dart';
import '../../../core/services/s1pro_print_service.dart';
import '../../../core/services/universal_print_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/theme/app_theme.dart';

class SaleScreen extends StatefulWidget {
  const SaleScreen({super.key});
  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Product> _products = [];
  List<Map<String, dynamic>> _cart = [];
  double _total = 0.0;
  String _selectedPaymentMethod = 'Espèces';
  bool _isProcessing = false;
  String _printMode = 'simulation';
  String _clientPhone = ''; // ✅ Téléphone du client pour WhatsApp
  final List<String> _paymentMethods = ['Espèces', 'Orange Money', 'Moov Money', 'Wave', 'Carte Bancaire'];

  @override
  void initState() { super.initState(); _loadProducts(); _db.addListener(_refreshData); }
  @override
  void dispose() { _db.removeListener(_refreshData); super.dispose(); }
  void _refreshData() { if (mounted) _loadProducts(); }
  void _loadProducts() { final p = _db.getAllProducts(); if (mounted) setState(() => _products = p); }

  void _addToCart(Product product) {
    if (product.currentStock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Stock épuisé'), duration: Duration(seconds: 1)));
      return;
    }
    setState(() {
      final i = _cart.indexWhere((item) => item['productId'] == product.id);
      if (i != -1) {
        if (_cart[i]['quantity'] < product.currentStock) { _cart[i]['quantity']++; _cart[i]['total'] = _cart[i]['quantity'] * product.sellingPrice; }
      } else {
        _cart.add({'productId': product.id, 'name': product.name, 'quantity': 1, 'unitPrice': product.sellingPrice, 'total': product.sellingPrice});
      }
      _calculateTotal();
    });
  }

  void _removeFromCart(int index) { setState(() { _cart.removeAt(index); _calculateTotal(); }); }
  void _updateQuantity(int index, int delta) {
    setState(() {
      final item = _cart[index];
      final product = _products.firstWhere((p) => p.id == item['productId']);
      final newQty = (item['quantity'] as int) + delta;
      if (newQty > 0 && newQty <= product.currentStock) { item['quantity'] = newQty; item['total'] = newQty * product.sellingPrice; }
      else if (newQty <= 0) { _cart.removeAt(index); }
      _calculateTotal();
    });
  }

  void _calculateTotal() { _total = _cart.fold(0.0, (sum, item) => sum + (item['total'] as double)); }

  // ✅ Envoyer le ticket par WhatsApp au client
  Future<void> _sendWhatsAppTicket(String ticketNumber, String date, List<Map<String, dynamic>> cart, double total) async {
    if (_clientPhone.isEmpty) return;
    
    final user = AuthService.getCurrentUser();
    final phone = _clientPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    
    String message = '🧾 *TICKET - ${user?.barName ?? 'BARMASTER'}*\n';
    message += '══════════════════\n';
    message += '🎫 $ticketNumber\n';
    message += '📅 $date\n';
    message += '💳 $_selectedPaymentMethod\n';
    message += '──────────────────\n';
    for (var item in cart) {
      message += '${item['name']} x${item['quantity']} = ${item['total']} F\n';
    }
    message += '──────────────────\n';
    message += '*TOTAL: $total FCFA*\n';
    message += '══════════════════\n';
    message += 'Merci de votre visite !\n';
    message += '${user?.barName ?? ''}\n';
    message += '${user?.barPhone ?? ''}';

    final encoded = Uri.encodeComponent(message);
    final url = Uri.parse('https://wa.me/$phone?text=$encoded');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // ✅ Vérifier les stocks bas et alerter l'admin
  void _checkLowStock() {
    final lowStock = _products.where((p) => p.currentStock <= p.minStockThreshold).toList();
    if (lowStock.isNotEmpty) {
      final user = AuthService.getCurrentUser();
      final products = lowStock.map((p) => '📦 ${p.name}: ${p.currentStock}/${p.minStockThreshold}').join('\n');
      
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(children: [Icon(Icons.warning, color: Colors.red), SizedBox(width: 8), Text('⚠️ Stock Bas')]),
          content: SingleChildScrollView(child: Text(products, style: const TextStyle(fontSize: 13))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ElevatedButton.icon(
              onPressed: () async {
                final admin = _db.getAllUsers().firstWhere((u) => u.isAdmin, orElse: () => _db.getAllUsers().first);
                final phone = admin.barPhone?.replaceAll(RegExp(r'[^0-9+]'), '') ?? '2250700000001';
                final msg = '⚠️ *ALERTE STOCK BAS - ${user?.barName ?? ''}*\n\n$products';
                final url = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(msg)}');
                if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                Navigator.pop(ctx);
              },
              icon: const Icon(Icons.whatshot, color: Colors.white),
              label: const Text('Alerter Admin', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _validateSale() async {
    if (_cart.isEmpty) return;
    setState(() => _isProcessing = true);
    
    final ticketNumber = 'TKT-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final date = DateTime.now().toString().substring(0, 19);
    final user = AuthService.getCurrentUser();
    final cartCopy = List<Map<String, dynamic>>.from(_cart);
    final totalCopy = _total;
    
    try {
      _db.createSale(ticketNumber: ticketNumber, totalAmount: _total, paymentMethod: _selectedPaymentMethod, items: cartCopy);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e')));
      setState(() => _isProcessing = false);
      return;
    }

    setState(() { _cart.clear(); _total = 0.0; });
    _loadProducts();
    setState(() => _isProcessing = false);
    
    // ✅ Vérifier les stocks bas
    _checkLowStock();
    
    // ✅ Envoyer ticket WhatsApp si numéro client renseigné
    if (_clientPhone.isNotEmpty) {
      _sendWhatsAppTicket(ticketNumber, date, cartCopy, totalCopy);
    }
    
    // Afficher le ticket
    _showTicket(ticketNumber, date, cartCopy, totalCopy, user);
  }

  void _showTicket(String ticketNumber, String date, List<Map<String, dynamic>> cart, double total, dynamic user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [Icon(Icons.receipt, color: AppTheme.primaryGold), SizedBox(width: 8), Text('TICKET DE VENTE')]),
        content: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Text(AuthService.barName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            if (AuthService.barAddress.isNotEmpty) Center(child: Text(AuthService.barAddress, style: const TextStyle(fontSize: 11))),
            if (AuthService.barPhone.isNotEmpty) Center(child: Text(AuthService.barPhone, style: const TextStyle(fontSize: 11))),
            const Divider(),
            Text('Ticket: $ticketNumber'), Text('Date: $date'), Text('Paiement: $_selectedPaymentMethod'),
            const Divider(),
            ...cart.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text('${item['name']} x${item['quantity']}')),
                Text('${item['total']} F', style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
            )),
            const Divider(thickness: 2),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('TOTAL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('$total FCFA', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
            ]),
            const SizedBox(height: 10),
            const Center(child: Text('Merci de votre visite !', style: TextStyle(fontStyle: FontStyle.italic))),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('FERMER')),
          ElevatedButton.icon(
            onPressed: () async {
              final items = cart.map((item) => {'name': item['name'], 'quantity': item['quantity'], 'total': item['total']}).toList();
              bool success = false;

              // Lire le mode sauvegardé
              final prefs = await SharedPreferences.getInstance();
              final mode = prefs.getString('print_mode') ?? 'pdf';

              if (mode == 'bluetooth_ble_s1pro' || mode == 'bluetooth_ble_espos') {
                final bytes = await UniversalPrintService.generateS1ProBytes(
                  ticketNumber: ticketNumber, date: date, paymentMethod: _selectedPaymentMethod,
                  total: total, items: items,
                  shopName: user?.barName ?? 'BARMASTER', shopPhone: user?.barPhone ?? '',
                  shopAddress: user?.barAddress ?? '', shopSlogan: user?.barEmail ?? '',
                );
                success = await S1ProPrintService.printBytes(bytes);
              } else {
                success = await PrintService.printTicket(
                  ticketNumber: ticketNumber, date: date, paymentMethod: _selectedPaymentMethod,
                  total: total, items: items,
                  shopName: user?.barName ?? 'BARMASTER', shopPhone: user?.barPhone ?? '',
                  shopAddress: user?.barAddress ?? '', shopSlogan: user?.barEmail ?? '',
                  printMode: mode,
                );
              }

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '✅ Impression envoyée' : '⚠️ Impression terminée'),
                    backgroundColor: success ? Colors.green : Colors.grey,
                  ),
                );
              }
            },
            icon: const Icon(Icons.print, color: Colors.white),
            label: const Text('IMPRESSION', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
          // ✅ Bouton PARTAGER (vers S1 Pro ou autre app)
          ElevatedButton.icon(
            onPressed: () async {
              final items = cart.map((item) => {'name': item['name'], 'quantity': item['quantity'], 'total': item['total']}).toList();
              await PdfTicketService.shareTicketPdf(
                ticketNumber: ticketNumber, date: date, paymentMethod: _selectedPaymentMethod,
                total: total, items: items,
                shopName: user?.barName ?? 'BARMASTER', shopPhone: user?.barPhone ?? '',
                shopAddress: user?.barAddress ?? '', shopSlogan: user?.barEmail ?? '',
              );
            },
            icon: const Icon(Icons.share, color: Colors.white),
            label: const Text('PARTAGER', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          ),
          // ✅ Bouton WHATSAPP sur le ticket
          if (_clientPhone.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () => _sendWhatsAppTicket(ticketNumber, date, cart, total),
              icon: const Icon(Icons.whatshot, color: Colors.white),
              label: const Text('WHATSAPP', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.getCurrentUser();
    final barName = user?.barName ?? 'BARMASTER';

    return Scaffold(
      appBar: AppBar(
        title: Text(barName, style: const TextStyle(fontSize: 14)),
        actions: [
          if (_cart.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: DropdownButton<String>(
                value: _selectedPaymentMethod, underline: const SizedBox(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                dropdownColor: Colors.grey[800],
                items: _paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
              ),
            ),
        ],
      ),
      body: Column(children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.all(8), color: Colors.grey[900],
          child: Text(barName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
        ),
        // ✅ Champ téléphone client pour WhatsApp
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: TextField(
            onChanged: (v) => _clientPhone = v,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: '📱 N° client WhatsApp (optionnel)',
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
              prefixIcon: const Icon(Icons.phone_android, color: Color(0xFF25D366), size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true, fillColor: Colors.grey[850],
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            keyboardType: TextInputType.phone,
          ),
        ),
        if (_cart.isNotEmpty)
          Container(
            height: 130, color: Colors.grey[850],
            child: ListView.builder(
              padding: const EdgeInsets.all(6), itemCount: _cart.length,
              itemBuilder: (_, i) {
                final item = _cart[i];
                return Card(
                  child: ListTile(
                    dense: true,
                    title: Text(item['name'], style: const TextStyle(fontSize: 12)),
                    subtitle: Text('${item['unitPrice']} F x ${item['quantity']} = ${item['total']} F', style: const TextStyle(fontSize: 11, color: AppTheme.primaryGold)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.remove, size: 16), onPressed: () => _updateQuantity(i, -1)),
                      IconButton(icon: const Icon(Icons.delete, size: 16, color: Colors.red), onPressed: () => _removeFromCart(i)),
                    ]),
                  ),
                );
              },
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), color: Colors.black,
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('TOTAL', style: TextStyle(fontSize: 11, color: Colors.grey)),
              Text('$_total FCFA', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
            ]),
            const Spacer(),
            SizedBox(
              height: 48, width: 140,
              child: ElevatedButton.icon(
                onPressed: _cart.isEmpty || _isProcessing ? null : _validateSale,
                icon: const Icon(Icons.check_circle, size: 22, color: Colors.white),
                label: const Text('VALIDER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: _cart.isEmpty ? Colors.grey : Colors.green, disabledBackgroundColor: Colors.grey, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ),
          ]),
        ),
        Expanded(
          child: _products.isEmpty
              ? const Center(child: Text('Aucun produit'))
              : GridView.builder(
                  padding: const EdgeInsets.all(6),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.1, crossAxisSpacing: 6, mainAxisSpacing: 6),
                  itemCount: _products.length,
                  itemBuilder: (_, i) {
                    final p = _products[i];
                    return Card(
                      child: InkWell(
                        onTap: () => _addToCart(p),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(p.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                            Text('${p.sellingPrice} F', style: const TextStyle(fontSize: 11, color: AppTheme.primaryGold)),
                            Text('Stock: ${p.currentStock}', style: TextStyle(fontSize: 9, color: p.currentStock > 0 ? Colors.green : Colors.red)),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
