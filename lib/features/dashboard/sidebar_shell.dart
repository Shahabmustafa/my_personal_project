import 'package:flutter/material.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/constants/app_constants.dart';

class SidebarItem {
  final String icon;
  final String label;
  final String? group;
  const SidebarItem({required this.icon, required this.label, this.group});
}

class SidebarShell extends StatefulWidget {
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

  @override
  State<SidebarShell> createState() => _SidebarShellState();
}

class _SidebarShellState extends State<SidebarShell> {
  static const _bg = Color(0xFFFFFFFF);
  static const _line = Color(0xFFE7E9F0);
  static const _accent = Color(0xFF3E63DD);
  static const _accentSoft = Color(0xFFEAEFFD);
  static const _textDark = Color(0xFF1B1F3B);
  static const _textDim = Color(0xFF8A8FA3);

  static const double _expandedWidth = 250;
  static const double _collapsedWidth = 76;

  bool _collapsed = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final safeIndex = widget.selectedIndex < widget.pages.length
        ? widget.selectedIndex
        : 0;
    final isMobile =
        MediaQuery.of(context).size.width < AppConstants.mobileMaxWidth;

    if (isMobile) {
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          foregroundColor: _textDark,
          elevation: 0.5,
          surfaceTintColor: _bg,
          titleSpacing: 4,
          title: Text(
            widget.navItems.isNotEmpty ? widget.navItems[safeIndex].label : '',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textDark,
            ),
          ),
          iconTheme: const IconThemeData(color: _textDark),
        ),
        drawer: Drawer(
          backgroundColor: _bg,
          child: SafeArea(
            child: _sidebarContent(
              collapsed: false,
              safeIndex: safeIndex,
              onSelect: (i) {
                Navigator.of(context).pop();
                widget.onSelect(i);
              },
            ),
          ),
        ),
        body: widget.pages[safeIndex],
      );
    }

    return Scaffold(
      body: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: _collapsed ? _collapsedWidth : _expandedWidth,
                decoration: const BoxDecoration(
                  color: _bg,
                  border: Border(right: BorderSide(color: _line)),
                ),
                // Driven by the box's actual (mid-animation) width rather
                // than `_collapsed` directly, so the content never renders
                // wider than the space the AnimatedContainer has reached.
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final collapsed =
                        constraints.maxWidth <
                        (_expandedWidth + _collapsedWidth) / 2;
                    return _sidebarContent(
                      collapsed: collapsed,
                      safeIndex: safeIndex,
                      onSelect: widget.onSelect,
                    );
                  },
                ),
              ),

              // Collapse/expand toggle — floats on the sidebar's edge.
              Positioned(
                top: 28,
                right: -12,
                child: Tooltip(
                  message: _collapsed ? 'Expand' : 'Collapse',
                  child: InkWell(
                    onTap: () => setState(() => _collapsed = !_collapsed),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: _line),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: AppIcon(
                        _collapsed
                            ? AppIcons.chevronRight
                            : AppIcons.chevronLeft,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Page
          Expanded(child: widget.pages[safeIndex]),
        ],
      ),
    );
  }

  // Full sidebar body — brand header, nav tree, user footer. Shared by the
  // desktop rail (collapsible) and the mobile Drawer (always expanded).
  Widget _sidebarContent({
    required bool collapsed,
    required int safeIndex,
    required ValueChanged<int> onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Row(
            mainAxisAlignment: collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
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
                child: const Text(
                  'A',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              if (!collapsed) ...[
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Panel',
                        style: TextStyle(
                          color: _textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Management Console',
                        style: TextStyle(
                          color: _textDim,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(color: _line, height: 1),

        if (!collapsed)
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Text(
              'MENU',
              style: TextStyle(
                color: _textDim,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
          )
        else
          const SizedBox(height: 12),

        // Nav items — scrollable so grouped/expanded items never
        // overflow the sidebar's fixed height.
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: collapsed
                  ? _buildNavTreeCollapsed(safeIndex, onSelect)
                  : _buildNavTree(safeIndex, onSelect),
            ),
          ),
        ),
        const Divider(color: _line, height: 1),

        // User info + logout
        Padding(
          padding: const EdgeInsets.all(16),
          child: collapsed
              ? Column(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: _accentSoft,
                      child: Text(
                        widget.userName.isNotEmpty
                            ? widget.userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: _accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Tooltip(
                      message: 'Logout',
                      child: InkWell(
                        onTap: widget.onLogout,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEECEC),
                            borderRadius: BorderRadius.circular(
                              8,
                            ),
                          ),
                          child: const AppIcon(
                            AppIcons.logout,
                            size: 16,
                            color: Color(0xFFC62828),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: _accentSoft,
                      child: Text(
                        widget.userName.isNotEmpty
                            ? widget.userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: _accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.userName,
                            style: const TextStyle(
                              color: _textDark,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.userRole,
                            style: const TextStyle(
                              color: _textDim,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Tooltip(
                      message: 'Logout',
                      child: InkWell(
                        onTap: widget.onLogout,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEECEC),
                            borderRadius: BorderRadius.circular(
                              8,
                            ),
                          ),
                          child: const AppIcon(
                            AppIcons.logout,
                            size: 16,
                            color: Color(0xFFC62828),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // Consecutive items sharing the same `group` are bundled into one
  // ExpansionTile; ungrouped items render as flat tiles like before.
  List<Widget> _buildNavTree(int safeIndex, ValueChanged<int> onSelect) {
    final widgets = <Widget>[];
    int i = 0;
    while (i < widget.navItems.length) {
      final group = widget.navItems[i].group;
      if (group == null) {
        widgets.add(_navTile(i, safeIndex, onSelect));
        i++;
      } else {
        final start = i;
        while (i < widget.navItems.length &&
            widget.navItems[i].group == group) {
          i++;
        }
        final indices = List.generate(i - start, (k) => start + k);
        widgets.add(_groupTile(group, indices, safeIndex, onSelect));
      }
    }
    return widgets;
  }

  // Collapsed rail: every item (grouped or not) renders as a single
  // icon-only tile so nothing depends on expandable width.
  List<Widget> _buildNavTreeCollapsed(
    int safeIndex,
    ValueChanged<int> onSelect,
  ) {
    return List.generate(
      widget.navItems.length,
      (i) => _navTileCollapsed(i, safeIndex, onSelect),
    );
  }

  Widget _navTileCollapsed(int i, int safeIndex, ValueChanged<int> onSelect) {
    final item = widget.navItems[i];
    final active = i == safeIndex;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Tooltip(
        message: item.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: () => onSelect(i),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: active ? _accentSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: active
                      ? _accent.withOpacity(0.25)
                      : Colors.transparent,
                ),
              ),
              alignment: Alignment.center,
              child: AppIcon(
                item.icon,
                size: 19,
                color: active ? _accent : _textDim,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navTile(int i, int safeIndex, ValueChanged<int> onSelect) {
    final item = widget.navItems[i];
    final active = i == safeIndex;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: () => onSelect(i),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: active ? _accentSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: active ? _accent.withOpacity(0.25) : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                AppIcon(
                  item.icon,
                  size: 19,
                  color: active ? _accent : _textDim,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active ? _textDark : _textDim,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _groupTile(
    String group,
    List<int> indices,
    int safeIndex,
    ValueChanged<int> onSelect,
  ) {
    final containsActive = indices.contains(safeIndex);
    return Theme(
      data: ThemeData(dividerColor: Colors.transparent),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: ExpansionTile(
          initiallyExpanded: containsActive,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.only(left: 8),
          shape: const Border(),
          collapsedShape: const Border(),
          leading: AppIcon(
            widget.navItems[indices.first].icon,
            size: 19,
            color: containsActive ? _accent : _textDim,
          ),
          title: Text(
            group,
            style: TextStyle(
              color: containsActive ? _textDark : _textDim,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          children:
              indices.map((i) => _navTile(i, safeIndex, onSelect)).toList(),
        ),
      ),
    );
  }
}
