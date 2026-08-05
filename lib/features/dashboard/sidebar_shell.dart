import 'package:flutter/material.dart';

class SidebarItem {
  final IconData icon;
  final String label;
  const SidebarItem({required this.icon, required this.label});
}

class SidebarShell extends StatelessWidget {
  final List<SidebarItem> navItems;
  final List<Widget> pages;
  final int selectedIndex;
  final String userName;
  final String userRole;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  const SidebarShell({
    super.key,
    required this.navItems,
    required this.pages,
    required this.selectedIndex,
    required this.userName,
    required this.userRole,
    required this.onSelect,
    required this.onLogout,
  });

  static const _bg = Color(0xFFFFFFFF);
  static const _line = Color(0xFFE7E9F0);
  static const _accent = Color(0xFF3E63DD);
  static const _accentSoft = Color(0xFFEAEFFD);
  static const _textDark = Color(0xFF1B1F3B);
  static const _textDim = Color(0xFF8A8FA3);

  @override
  Widget build(BuildContext context) {
    final safeIndex = selectedIndex < pages.length ? selectedIndex : 0;

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 250,
            decoration: const BoxDecoration(
              color: _bg,
              border: Border(right: BorderSide(color: _line)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_accent, Color(0xFF5B7FEF)],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text('A',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Admin Panel',
                              style: TextStyle(
                                  color: _textDark,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                          Text('Management Console',
                              style: TextStyle(color: _textDim, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(color: _line, height: 1),

                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 14, 20, 6),
                  child: Text('MENU',
                      style: TextStyle(
                          color: _textDim, fontSize: 11, letterSpacing: 0.8)),
                ),

                // Nav items
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: List.generate(navItems.length, (i) {
                      final item = navItems[i];
                      final active = i == safeIndex;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(9),
                            onTap: () => onSelect(i),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 11),
                              decoration: BoxDecoration(
                                color: active ? _accentSoft : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: active
                                      ? _accent.withOpacity(0.25)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(item.icon,
                                      size: 19,
                                      color: active ? _accent : _textDim),
                                  const SizedBox(width: 12),
                                  Text(item.label,
                                      style: TextStyle(
                                          color: active ? _textDark : _textDim,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const Spacer(),
                const Divider(color: _line, height: 1),

                // User info + logout
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: _accentSoft,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                          style: const TextStyle(
                              color: _accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(userName,
                                style: const TextStyle(
                                    color: _textDark,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis),
                            Text(userRole,
                                style: const TextStyle(
                                    color: _textDim, fontSize: 11),
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Tooltip(
                        message: 'Logout',
                        child: InkWell(
                          onTap: onLogout,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEECEC),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.logout,
                                size: 16, color: Color(0xFFC62828)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Page
          Expanded(child: pages[safeIndex]),
        ],
      ),
    );
  }
}
