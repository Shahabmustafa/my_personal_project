import 'package:flutter/material.dart';
import '../../data/models/assign_printer_model.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
class AssignPrinterCard extends StatelessWidget {
  final AssignPrinterModel item;
  final VoidCallback onDelete;

  const AssignPrinterCard({
    super.key,
    required this.item,
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
            child: item.printerImageUrl.isNotEmpty
                ? Image.network(
                    item.printerImageUrl,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _DefaultPrinterIcon(),
                  )
                : _DefaultPrinterIcon(),
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Printer name
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.printerName.isEmpty
                            ? 'Unknown Printer'
                            : item.printerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                    // Assigned badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF5E6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Assigned',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Branch section
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE7E9F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF5E6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const AppIcon(AppIcons.storeOutlined,
                            size: 15, color: Color(0xFF2E7D32)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.branchName.isEmpty
                                  ? 'Unknown Branch'
                                  : item.branchName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Color(0xFF2D2D3A)),
                            ),
                            if (item.branchAddress.isNotEmpty ||
                                item.branchCity.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              _IconRow(
                                icon: AppIcons.locationOnOutlined,
                                text: [item.branchAddress, item.branchCity]
                                    .where((s) => s.isNotEmpty)
                                    .join(', '),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Printer details
                if (item.printerPhone.isNotEmpty)
                  _IconRow(
                      icon: AppIcons.phoneOutlined,
                      text: item.printerPhone),
                if (item.printerAddress.isNotEmpty)
                  _IconRow(
                      icon: AppIcons.locationOnOutlined,
                      text: item.printerAddress),

                const SizedBox(height: 4),
                _IconRow(
                  icon: AppIcons.calendarTodayOutlined,
                  text: _fmt(item.createdAt),
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
              child: const AppIcon(AppIcons.deleteOutline,
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

class _DefaultPrinterIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFEAEFFD),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const AppIcon(AppIcons.printOutlined,
          color: Color(0xFF3E63DD), size: 22),
    );
  }
}

class _IconRow extends StatelessWidget {
  final String icon;
  final String text;
  const _IconRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          AppIcon(icon, size: 13, color: const Color(0xFF8A8FA3)),
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
