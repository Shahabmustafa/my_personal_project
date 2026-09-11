import 'package:flutter/material.dart';
import '../../data/model/warehouse_model.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
class WarehouseCard extends StatelessWidget {
  final WarehouseModel warehouse;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const WarehouseCard({
    super.key,
    required this.warehouse,
    required this.canEdit,
    required this.onEdit,
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
            child: const AppIcon(AppIcons.warehouseOutlined, color: Color(0xFF2E7D32), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(warehouse.warehouseName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
                    _StatusPill(isActive: warehouse.isActive),
                  ],
                ),
                const SizedBox(height: 6),
                if (warehouse.address.isNotEmpty) _IconRow(icon: AppIcons.locationOnOutlined, text: warehouse.address),
                if (warehouse.city.isNotEmpty) _IconRow(icon: AppIcons.locationCity, text: warehouse.city),
                if (warehouse.phoneNumber.isNotEmpty) _IconRow(icon: AppIcons.phoneOutlined, text: warehouse.phoneNumber),
              ],
            ),
          ),
          if (canEdit) ...[
            const SizedBox(width: 8),
            Column(
              children: [
                _ActionBtn(icon: AppIcons.editOutlined, color: const Color(0xFF3E63DD), onTap: onEdit),
                const SizedBox(height: 6),
                _ActionBtn(icon: AppIcons.deleteOutline, color: Colors.redAccent, onTap: onDelete),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isActive;
  const _StatusPill({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFEAF5E6) : const Color(0xFFFEECEC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(color: isActive ? const Color(0xFF2E7D32) : const Color(0xFFC62828), fontSize: 11, fontWeight: FontWeight.w600),
      ),
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
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF8A8FA3)))),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
        child: AppIcon(icon, size: 18, color: color),
      ),
    );
  }
}
