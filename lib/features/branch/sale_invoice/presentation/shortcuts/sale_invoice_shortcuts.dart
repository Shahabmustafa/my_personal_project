import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Sale Invoice screen ke keyboard shortcuts:
///   Ctrl+C customer · Ctrl+M salesman · Ctrl+P printer · Ctrl+B barcode · Ctrl+F article ·
///   Ctrl+S invoice save   (Mac par Cmd bhi chalta hai)
enum SaleShortcut { customer, salesman, printer, barcode, article, save }

class SaleShortcutEvent {
  final SaleShortcut action;

  /// Har dabav naya event bane (same key do baar dabane par bhi).
  final int n;
  const SaleShortcutEvent(this.action, this.n);
}

/// Screen ke widgets ([ref.listen]) isko sunte hain aur apna kaam karte hain.
final saleShortcutProvider = StateProvider<SaleShortcutEvent?>((_) => null);

class SaleInvoiceShortcuts extends ConsumerStatefulWidget {
  final Widget child;
  const SaleInvoiceShortcuts({super.key, required this.child});

  @override
  ConsumerState<SaleInvoiceShortcuts> createState() =>
      _SaleInvoiceShortcutsState();
}

class _SaleInvoiceShortcutsState extends ConsumerState<SaleInvoiceShortcuts> {
  int _n = 0;

  /// Page ke andar apna focus node — sidebar shell ka focus page ke upar
  /// hota hai, uske rehte page ke shortcuts tak key events nahi pahunchte.
  final _focus = FocusNode(debugLabel: 'saleInvoiceShortcuts');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _fire(SaleShortcut action) {
    ref.read(saleShortcutProvider.notifier).state = SaleShortcutEvent(
      action,
      ++_n,
    );
  }

  /// Ctrl+C ab "customer" hai — lekin text select ho to normal copy chale.
  void _customerOrCopy() {
    final ctx = FocusManager.instance.primaryFocus?.context;
    final editable = ctx?.findAncestorStateOfType<EditableTextState>();
    if (editable != null && !editable.widget.controller.selection.isCollapsed) {
      editable.copySelection(SelectionChangedCause.keyboard);
      return;
    }
    _fire(SaleShortcut.customer);
  }

  @override
  Widget build(BuildContext context) {
    Map<ShortcutActivator, VoidCallback> both(
      LogicalKeyboardKey key,
      VoidCallback cb,
    ) => {
      SingleActivator(key, control: true): cb,
      SingleActivator(key, meta: true): cb,
    };

    return CallbackShortcuts(
      bindings: {
        ...both(LogicalKeyboardKey.keyC, _customerOrCopy),
        ...both(LogicalKeyboardKey.keyM, () => _fire(SaleShortcut.salesman)),
        ...both(LogicalKeyboardKey.keyP, () => _fire(SaleShortcut.printer)),
        ...both(LogicalKeyboardKey.keyB, () => _fire(SaleShortcut.barcode)),
        ...both(LogicalKeyboardKey.keyF, () => _fire(SaleShortcut.article)),
        ...both(LogicalKeyboardKey.keyS, () => _fire(SaleShortcut.save)),
      },
      child: Focus(focusNode: _focus, child: widget.child),
    );
  }
}
