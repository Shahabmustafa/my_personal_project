import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widget/app_icon.dart';
import '../../data/model/website_models.dart';
import '../../data/website_data.dart';
import '../provider/website_providers.dart';
import '../theme/website_theme.dart';
import '../widget/shoe_card.dart';
import '../widget/website_widgets.dart';

enum _Fulfilment { pickup, delivery }

/// Cart + checkout. With no backend yet, the order is sent to the chosen
/// branch on WhatsApp as a ready-made message.
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _note = TextEditingController();
  String _branchId = SafiData.branches.first.id;
  _Fulfilment _fulfilment = _Fulfilment.pickup;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  String _message(List<CartLine> lines, double total, ShopBranch branch) {
    final b = StringBuffer()
      ..writeln('*New order — Safi Shoes website*')
      ..writeln('Branch: ${branch.name}')
      ..writeln()
      ..writeln('*Items*');
    for (final l in lines) {
      b.writeln('• ${l.shoe.name} — size ${l.size} × ${l.qty} = ${formatPrice(l.total)}');
    }
    b
      ..writeln()
      ..writeln('*Total: ${formatPrice(total)}*')
      ..writeln()
      ..writeln('Name: ${_name.text.trim()}')
      ..writeln('Phone: ${_phone.text.trim()}')
      ..writeln(_fulfilment == _Fulfilment.pickup ? 'Pick-up from branch' : 'Delivery to: ${_address.text.trim()}');
    if (_note.text.trim().isNotEmpty) b.writeln('Note: ${_note.text.trim()}');
    return b.toString();
  }

  Future<void> _placeOrder(List<CartLine> lines, double total) async {
    if (!_form.currentState!.validate()) return;
    final branch = SafiData.branch(_branchId) ?? SafiData.branches.first;
    await openLink(context, whatsappUrl(branch.whatsapp, _message(lines, total, branch)));
    if (!mounted) return;
    ref.read(cartProvider.notifier).clear();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const IconBadge(AppIcons.checkCircleOutline, size: 56, color: WColors.olive),
        title: Text('Order sent!', style: WText.display(24)),
        content: Text(
          'Your order has been sent to ${branch.name} on WhatsApp. '
          'Our team will confirm it with you shortly.',
          textAlign: TextAlign.center,
          style: WText.body(14, color: WColors.muted, height: 1.6),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          PillButton(
            label: 'Continue shopping',
            small: true,
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(websiteTabProvider.notifier).state = WebsiteTab.shop;
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lines = ref.watch(cartProvider);
    final total = ref.watch(cartSubtotalProvider);
    final wide = MediaQuery.sizeOf(context).width >= 900;

    if (lines.isEmpty) return const _EmptyCart();

    final items = Container(
      decoration: BoxDecoration(
        color: WColors.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WColors.line),
      ),
      child: Column(
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: WColors.line),
            _CartRow(line: lines[i]),
          ],
        ],
      ),
    );

    final checkout = Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: WColors.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WColors.line),
        boxShadow: WShadows.soft,
      ),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Checkout', style: WText.display(22)),
            const SizedBox(height: 16),
            SegmentedButton<_Fulfilment>(
              segments: const [
                ButtonSegment(value: _Fulfilment.pickup, label: Text('Pick-up')),
                ButtonSegment(value: _Fulfilment.delivery, label: Text('Delivery')),
              ],
              selected: {_fulfilment},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _fulfilment = s.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: WColors.ink,
                selectedForegroundColor: Colors.white,
                side: const BorderSide(color: WColors.line),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _branchId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: _fulfilment == _Fulfilment.pickup ? 'Pick-up branch' : 'Nearest branch',
              ),
              items: [
                for (final b in SafiData.branches)
                  DropdownMenuItem(value: b.id, child: Text(b.name, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() => _branchId = v ?? _branchId),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Your name'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number', hintText: '03XX XXXXXXX'),
              validator: (v) =>
                  (v ?? '').replaceAll(RegExp(r'\D'), '').length < 10 ? 'Please enter a valid phone number' : null,
            ),
            if (_fulfilment == _Fulfilment.delivery) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _address,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Delivery address'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Please enter your address' : null,
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 18),
            const Divider(color: WColors.line),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text('Total', style: WText.body(15, color: WColors.muted))),
                Text(formatPrice(total), style: WText.display(24, color: WColors.red)),
              ],
            ),
            if (_fulfilment == _Fulfilment.delivery)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Delivery charges confirmed on WhatsApp', style: WText.body(12, color: WColors.muted)),
              ),
            const SizedBox(height: 18),
            PillButton(
              label: 'Place Order on WhatsApp',
              icon: AppIcons.sendOutlined,
              expand: true,
              onPressed: () => _placeOrder(lines, total),
            ),
          ],
        ),
      ),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: wGutter(context), vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: wMaxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('YOUR ORDER', style: WText.eyebrow()),
              const SizedBox(height: 8),
              Text('Cart (${ref.watch(cartCountProvider)})', style: WText.display(32)),
              const SizedBox(height: 22),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: items),
                    const SizedBox(width: 24),
                    SizedBox(width: 420, child: checkout),
                  ],
                )
              else ...[
                items,
                const SizedBox(height: 20),
                checkout,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CartRow extends ConsumerWidget {
  final CartLine line;

  const _CartRow({required this.line});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.read(cartProvider.notifier);
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(width: 78, height: 78, child: ShoeImage(line.shoe.image)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.shoe.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: WText.body(14, color: WColors.ink, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text('Size ${line.size} · ${formatPrice(line.shoe.price)}', style: WText.body(12.5, color: WColors.muted)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    QtyStepper(qty: line.qty, onChanged: (q) => cart.setQty(line.key, q)),
                    const Spacer(),
                    Text(formatPrice(line.total), style: WText.body(14.5, color: WColors.red, weight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Remove',
            onPressed: () => cart.setQty(line.key, 0),
            icon: const AppIcon(AppIcons.deleteOutline, size: 16, color: WColors.muted),
          ),
        ],
      ),
    );
  }
}

class _EmptyCart extends ConsumerWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const IconBadge(AppIcons.shoppingBagOutlined, size: 76, background: WColors.paper),
            const SizedBox(height: 20),
            Text('Your cart is empty', style: WText.display(26)),
            const SizedBox(height: 8),
            Text(
              'Browse our collection and tap Order Now on a shoe you like.',
              textAlign: TextAlign.center,
              style: WText.body(14.5, color: WColors.muted),
            ),
            const SizedBox(height: 22),
            PillButton(
              label: 'Shop Now',
              icon: AppIcons.chevronRight,
              onPressed: () => ref.read(websiteTabProvider.notifier).state = WebsiteTab.shop,
            ),
          ],
        ),
      ),
    );
  }
}
