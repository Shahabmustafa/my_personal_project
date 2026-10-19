import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/widget/text_field_icon.dart';

/// Searchable dropdown (dropdown_search) jo keyboard se chalta hai: open hote
/// hi search box par focus, ↑ / ↓ se list mein upar-neeche, Enter se select.
/// Bahar se [KeyboardDropdownState.open] se kholi ja sakti hai (shortcuts).
class KeyboardDropdown<T> extends StatefulWidget {
  /// Search text ke hisab se filtered list.
  final List<T> Function(String filter) filter;
  final T? selectedItem;
  final String Function(T) itemAsString;
  final bool Function(T a, T b) compareFn;
  final ValueChanged<T?> onSelected;
  final InputDecoration decoration;
  final String? searchHint;
  final double maxHeight;

  /// Custom row — [highlighted] keyboard se chuni hui row hai.
  final Widget Function(BuildContext context, T item, bool selected)?
  itemBuilder;

  const KeyboardDropdown({
    super.key,
    required this.filter,
    required this.selectedItem,
    required this.itemAsString,
    required this.compareFn,
    required this.onSelected,
    required this.decoration,
    this.searchHint,
    this.maxHeight = 260,
    this.itemBuilder,
  });

  @override
  State<KeyboardDropdown<T>> createState() => KeyboardDropdownState<T>();
}

class KeyboardDropdownState<T> extends State<KeyboardDropdown<T>> {
  final _dropKey = GlobalKey<DropdownSearchState<T>>();
  final _highlight = ValueNotifier<int>(0);
  late final FocusNode _searchFocus;
  List<T> _visible = [];
  String? _lastFilter;

  @override
  void initState() {
    super.initState();
    _searchFocus = FocusNode(debugLabel: 'keyboardDropdownSearch')
      ..onKeyEvent = _onKey;
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _highlight.dispose();
    super.dispose();
  }

  /// Shortcut se kholo.
  void open() => _dropKey.currentState?.openDropDownSearch();

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      if (_visible.isNotEmpty) {
        _highlight.value = (_highlight.value + 1).clamp(0, _visible.length - 1);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      if (_visible.isNotEmpty) {
        _highlight.value = (_highlight.value - 1).clamp(0, _visible.length - 1);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      final i = _highlight.value;
      if (i >= 0 && i < _visible.length) {
        final item = _visible[i];
        _dropKey.currentState?.closeDropDownSearch();
        widget.onSelected(item);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  int _indexOf(T item) => _visible.indexWhere((e) => widget.compareFn(e, item));

  @override
  Widget build(BuildContext context) {
    return DropdownSearch<T>(
      key: _dropKey,
      items: (f, _) {
        final result = widget.filter(f);
        _visible = result;
        if (f != _lastFilter) {
          _lastFilter = f;
          // List badli (naya search) — highlight phir se pehli row par.
          Future.microtask(() {
            if (mounted) _highlight.value = 0;
          });
        }
        return result;
      },
      selectedItem: widget.selectedItem,
      itemAsString: widget.itemAsString,
      compareFn: widget.compareFn,
      onSelected: widget.onSelected,
      onFocusChange: (focused) {
        if (focused) {
          _lastFilter = null;
          _highlight.value = 0;
        }
      },
      decoratorProps: DropDownDecoratorProps(decoration: widget.decoration),
      popupProps: PopupProps.menu(
        fit: FlexFit.loose,
        showSearchBox: true,
        constraints: BoxConstraints(maxHeight: widget.maxHeight),
        searchFieldProps: TextFieldProps(
          autofocus: true,
          focusNode: _searchFocus,
          decoration: InputDecoration(
            hintText: widget.searchHint ?? 'Search...',
            prefixIcon: const TextFieldIcon(AppIcons.search, size: 18),
            isDense: true,
          ),
        ),
        itemBuilder: (context, item, isSelected, isFocused) {
          return ValueListenableBuilder<int>(
            valueListenable: _highlight,
            builder: (context, hi, _) {
              final highlighted = _indexOf(item) == hi;
              final child =
                  widget.itemBuilder?.call(context, item, isSelected) ??
                  ListTile(
                    dense: true,
                    selected: isSelected,
                    title: Text(widget.itemAsString(item)),
                  );
              return _HighlightRow(highlighted: highlighted, child: child);
            },
          );
        },
      ),
    );
  }
}

/// Keyboard se chuni row ka background + ↑/↓ par list scroll karke dikhana.
class _HighlightRow extends StatefulWidget {
  final bool highlighted;
  final Widget child;
  const _HighlightRow({required this.highlighted, required this.child});

  @override
  State<_HighlightRow> createState() => _HighlightRowState();
}

class _HighlightRowState extends State<_HighlightRow> {
  @override
  void didUpdateWidget(_HighlightRow old) {
    super.didUpdateWidget(old);
    if (widget.highlighted && !old.highlighted) _reveal();
  }

  @override
  void initState() {
    super.initState();
    if (widget.highlighted) _reveal();
  }

  void _reveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 80),
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.highlighted
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
          : null,
      child: widget.child,
    );
  }
}
