import 'package:flutter/material.dart';
import '../../data/models/printer_head_model.dart';

class PrinterHeadCard extends StatelessWidget {
  final PrinterHeadModel printer;
  final VoidCallback onDelete;

  const PrinterHeadCard({
    super.key,
    required this.printer,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E9F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Printer image / icon
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: printer.imageUrl.isNotEmpty
                ? Image.network(
                    printer.imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _DefaultIcon(),
                  )
                : _DefaultIcon(),
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  printer.name.isEmpty ? 'Unknown Printer' : printer.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 6),
                if (printer.address.isNotEmpty)
                  _IconRow(
                    icon: Icons.location_on_outlined,
                    text: printer.address,
                  ),
                if (printer.phoneNumber.isNotEmpty)
                  _IconRow(
                    icon: Icons.phone_outlined,
                    text: printer.phoneNumber,
                  ),
                const SizedBox(height: 4),
                _IconRow(
                  icon: Icons.calendar_today_outlined,
                  text: _fmt(printer.createdAt),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Delete
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline,
                  size: 18, color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}

class _DefaultIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFEAEFFD),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.print_outlined,
          color: Color(0xFF3E63DD), size: 24),
    );
  }
}

class _IconRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _IconRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: const Color(0xFF8A8FA3)),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF8A8FA3)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
