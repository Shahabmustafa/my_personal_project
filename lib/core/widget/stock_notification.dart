import 'package:flutter/material.dart';

/// Dashboard ke upar floating notification (naya assignment / return aane par).
void showStockNotification(
  BuildContext context, {
  required String title,
  required String subtitle,
  IconData icon = Icons.local_shipping_outlined,
  VoidCallback? onView,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      width: 420,
      duration: const Duration(seconds: 8),
      backgroundColor: const Color(0xFF1F2333),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Row(
        children: [
          Icon(icon, color: const Color(0xFF8ED4AA), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB8BDD0),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      action: onView == null
          ? null
          : SnackBarAction(
              label: 'View',
              textColor: const Color(0xFF8ED4AA),
              onPressed: onView,
            ),
    ),
  );
}
