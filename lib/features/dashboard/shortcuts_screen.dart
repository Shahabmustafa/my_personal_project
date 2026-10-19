import 'package:flutter/material.dart';
import 'package:safishoe_app/features/dashboard/sidebar_shell.dart';

/// Sidebar ke saare keyboard shortcuts ki list — admin aur branch dono ke
/// dashboard mein, apne apne nav items ke sath.
class ShortcutsScreen extends StatefulWidget {
  final List<SidebarItem> items;
  const ShortcutsScreen({super.key, required this.items});

  @override
  State<ShortcutsScreen> createState() => _ShortcutsScreenState();
}

class _ShortcutsScreenState extends State<ShortcutsScreen> {
  static const _accent = Color(0xFF3E63DD);
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final withKey = widget.items.where((i) => i.shortcutLabel != null);
    final matches = withKey.where(
      (i) =>
          q.isEmpty ||
          i.label.toLowerCase().contains(q) ||
          i.shortcutLabel!.toLowerCase().contains(q) ||
          (i.group ?? '').toLowerCase().contains(q),
    );

    // Group ke hisab se (group null = "General"), sidebar ke order mein.
    final groups = <String, List<SidebarItem>>{};
    for (final i in matches) {
      groups.putIfAbsent(i.group ?? 'General', () => []).add(i);
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Keyboard Shortcuts',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Press the keys from anywhere in the app to jump to a screen.',
            style: TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 320,
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search screen or key',
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: groups.isEmpty
                ? const Center(
                    child: Text(
                      'No shortcuts found',
                      style: TextStyle(color: Color(0xFF8A8FA3)),
                    ),
                  )
                : ListView(
                    children: [
                      for (final e in groups.entries) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, top: 4),
                          child: Text(
                            e.key.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF8A8FA3),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE7E9F0)),
                          ),
                          child: Column(
                            children: [
                              for (var n = 0; n < e.value.length; n++) ...[
                                if (n > 0)
                                  const Divider(
                                    height: 1,
                                    color: Color(0xFFEEF0F6),
                                  ),
                                _ShortcutRow(item: e.value[n]),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  final SidebarItem item;
  const _ShortcutRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final keys = item.shortcutLabel!.split('+');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          for (var n = 0; n < keys.length; n++) ...[
            if (n > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('+', style: TextStyle(color: Color(0xFF8A8FA3))),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F1F5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFD9DCE6)),
              ),
              child: Text(
                keys[n],
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  color: _ShortcutsScreenState._accent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
