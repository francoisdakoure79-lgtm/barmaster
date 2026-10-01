import 'package:flutter/material.dart';
import '../../core/services/bar_service.dart';

class TicketHeader extends StatelessWidget {
  final bool showBorder;
  
  const TicketHeader({super.key, this.showBorder = true});

  @override
  Widget build(BuildContext context) {
    final bar = BarService();
    
    if (!bar.hasBar) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: showBorder
          ? BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Column(
        children: [
          Text(
            bar.barName ?? 'BARMASTER',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (bar.barAddress != null) ...[
            const SizedBox(height: 4),
            Text(
              bar.barAddress!,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
          if (bar.barPhone != null) ...[
            const SizedBox(height: 2),
            Text(
              'Tél: ${bar.barPhone}',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
          if (bar.barSlogan != null) ...[
            const SizedBox(height: 2),
            Text(
              bar.barSlogan!,
              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class TicketFooter extends StatelessWidget {
  const TicketFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final bar = BarService();
    
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          const Divider(),
          const Text(
            'Merci de votre visite !',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Text(
            '${bar.barName ?? ''} - Tél: ${bar.barPhone ?? ''}',
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
