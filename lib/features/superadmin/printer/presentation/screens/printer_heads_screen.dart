import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/printer_head_model.dart';
import '../providers/printer_providers.dart';
import '../widgets/printer_head_card.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
class PrinterHeadsScreen extends ConsumerStatefulWidget {
  const PrinterHeadsScreen({super.key});

  @override
  ConsumerState<PrinterHeadsScreen> createState() => _PrinterHeadsScreenState();
}

class _PrinterHeadsScreenState extends ConsumerState<PrinterHeadsScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(printerHeadsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final printersAsync = ref.watch(printerHeadsProvider);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Printer Head',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D3A),
          ),
        ),
      ),
      body: printersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(printerHeadsProvider),
        ),
        data: (printers) {
          final filtered = printers
              .where((p) =>
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.address
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              p.phoneNumber
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Printer Heads',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        Text('${printers.length} total printers',
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF8A8FA3))),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _showAddDialog(context),
                      icon: const AppIcon(AppIcons.add, size: 18),
                      label: const Text('Add Printer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3E63DD),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Search ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: _searchDecor('Search printers...'),
                ),
              ),

              // ── Content ───────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? const _EmptyView()
                    : isMobile
                    ? _MobileList(
                  printers: filtered,
                  onDelete: (p) => _confirmDelete(context, p),
                )
                    : _DesktopTable(
                  printers: filtered,
                  onDelete: (p) => _confirmDelete(context, p),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Add Dialog ────────────────────────────────────────────────────────────

  void _showAddDialog(BuildContext context) {
    final nameCtrl    = TextEditingController();
    final addressCtrl = TextEditingController();
    final phoneCtrl   = TextEditingController();
    final formKey     = GlobalKey<FormState>();

    Uint8List? imageBytes;
    String? imageMime;
    String? imageFileName;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          Future<void> pickImage() async {
            final picked = await ImagePicker().pickImage(
              source: ImageSource.gallery,
              maxWidth: 800,
              maxHeight: 800,
              imageQuality: 85,
            );
            if (picked == null) return;
            final bytes = await picked.readAsBytes();
            final ext = picked.name.split('.').last.toLowerCase();
            final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
            final safeName =
                picked.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            setDialogState(() {
              imageBytes = bytes;
              imageMime = mime;
              imageFileName = '${timestamp}_$safeName';
            });
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Add Printer Head',
                style: TextStyle(fontWeight: FontWeight.w600)),
            content: SizedBox(
              width: 420,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: isSaving ? null : pickImage,
                        child: Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFFE7E9F0), width: 1.5),
                          ),
                          child: imageBytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(9),
                                  child: Image.memory(imageBytes!,
                                      fit: BoxFit.cover,
                                      width: double.infinity),
                                )
                              : Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: const [
                                    AppIcon(AppIcons.addPhotoAlternateOutlined,
                                        size: 36, color: Color(0xFF8A8FA3)),
                                    SizedBox(height: 8),
                                    Text('Tap to select image',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF8A8FA3))),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        imageBytes != null
                            ? 'Image selected — tap to change'
                            : 'Optional',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF8A8FA3)),
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        controller: nameCtrl,
                        label: 'Printer Name *',
                        icon: AppIcons.printOutlined,
                        required: true,
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: addressCtrl,
                        label: 'Address *',
                        icon: AppIcons.locationOnOutlined,
                        required: true,
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: phoneCtrl,
                        label: 'Phone Number *',
                        icon: AppIcons.phoneOutlined,
                        keyboardType: TextInputType.phone,
                        required: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3E63DD),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isSaving = true);
                        try {
                          String imageUrl = '';
                          if (imageBytes != null && imageFileName != null) {
                            imageUrl = await ref
                                .read(printerRepositoryProvider)
                                .uploadImage(
                                  fileName: imageFileName!,
                                  bytes: imageBytes!,
                                  mimeType: imageMime ?? 'image/jpeg',
                                );
                          }
                          await ref
                              .read(printerRepositoryProvider)
                              .addPrinterHead(
                                name:        nameCtrl.text.trim(),
                                imageUrl:    imageUrl,
                                address:     addressCtrl.text.trim(),
                                phoneNumber: phoneCtrl.text.trim(),
                              );
                          ref.invalidate(printerHeadsProvider);
                          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                          if (context.mounted) {
                            _snack(context, 'Printer added successfully!', Colors.green);
                          }
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          if (dialogCtx.mounted) {
                            _snack(dialogCtx, 'Error: $e', Colors.red);
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Confirm Delete ─────────────────────────────────────────────────────────

  void _confirmDelete(BuildContext context, PrinterHeadModel printer) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Printer?'),
        content: Text(
            'Delete "${printer.name}"? Assigned records will also be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(printerRepositoryProvider)
                    .removePrinterHead(printer.id);
                ref.invalidate(printerHeadsProvider);
                ref.invalidate(assignedPrintersProvider);
                if (context.mounted) {
                  _snack(context, 'Printer deleted successfully!', Colors.orange);
                }
              } catch (e) {
                if (context.mounted) {
                  _snack(context, 'Error: $e', Colors.red);
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String icon,
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        prefixIcon: Center(child: AppIcon(icon, size: 16, color: const Color(0xFF8A8FA3))),
        isDense: true,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
            const BorderSide(color: Color(0xFF3E63DD), width: 1.5)),
      ),
      validator: (v) {
        if (required && (v == null || v.trim().isEmpty)) {
          return '$label is required';
        }
        return null;
      },
    );
  }

  void _snack(BuildContext ctx, String msg, Color color) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }
}

// ── Desktop Table ──────────────────────────────────────────────────────────────

class _DesktopTable extends StatelessWidget {
  final List<PrinterHeadModel> printers;
  final Function(PrinterHeadModel) onDelete;

  const _DesktopTable({required this.printers, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7E9F0)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              // Header
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F8FC),
                  border:
                  Border(bottom: BorderSide(color: Color(0xFFE7E9F0))),
                ),
                child: Row(children: [
                  _TH('#',             flex: 1),
                  _TH('Image',         flex: 2),
                  _TH('Printer Name',  flex: 4),
                  _TH('Address',       flex: 4),
                  _TH('Phone',         flex: 3),
                  _TH('Created At',    flex: 2),
                  _TH('Action',        flex: 2),
                ]),
              ),
              // Rows
              Expanded(
                child: ListView.builder(
                  itemCount: printers.length,
                  itemBuilder: (_, i) {
                    final p      = printers[i];
                    final isLast = i == printers.length - 1;
                    return Container(
                      decoration: BoxDecoration(
                        color: i.isEven
                            ? Colors.white
                            : const Color(0xFFF7F8FC),
                        border: isLast
                            ? null
                            : const Border(
                            bottom: BorderSide(
                                color: Color(0xFFE7E9F0))),
                      ),
                      child: Row(children: [
                        // #
                        Expanded(
                          flex: 1,
                          child: _TD(
                            child: Text('${i + 1}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF8A8FA3))),
                          ),
                        ),
                        // Image
                        Expanded(
                          flex: 2,
                          child: _TD(
                            child: p.imageUrl.isNotEmpty
                                ? ClipRRect(
                              borderRadius:
                              BorderRadius.circular(8),
                              child: Image.network(
                                p.imageUrl,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _TableIcon(),
                              ),
                            )
                                : _TableIcon(),
                          ),
                        ),
                        // Name
                        Expanded(
                          flex: 4,
                          child: _TD(
                            child: Text(
                              p.name.isEmpty ? '—' : p.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        // Address
                        Expanded(
                          flex: 4,
                          child: _TD(
                            child: Text(
                              p.address.isEmpty ? '—' : p.address,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8A8FA3)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        // Phone
                        Expanded(
                          flex: 3,
                          child: _TD(
                            child: Row(children: [
                              if (p.phoneNumber.isNotEmpty) ...[
                                const AppIcon(AppIcons.phoneOutlined,
                                    size: 13,
                                    color: Color(0xFF8A8FA3)),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(
                                  p.phoneNumber.isEmpty
                                      ? '—'
                                      : p.phoneNumber,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ]),
                          ),
                        ),
                        // Date
                        Expanded(
                          flex: 2,
                          child: _TD(
                            child: Text(
                              _fmt(p.createdAt),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8A8FA3)),
                            ),
                          ),
                        ),
                        // Delete
                        Expanded(
                          flex: 2,
                          child: _TD(
                            child: _IconBtn(
                              icon: AppIcons.deleteOutline,
                              color: Colors.redAccent,
                              tooltip: 'Delete',
                              onTap: () => onDelete(p),
                            ),
                          ),
                        ),
                      ]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
}

// ── Mobile List ───────────────────────────────────────────────────────────────

class _MobileList extends StatelessWidget {
  final List<PrinterHeadModel> printers;
  final Function(PrinterHeadModel) onDelete;

  const _MobileList({required this.printers, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: printers.length,
      itemBuilder: (_, i) => PrinterHeadCard(
        printer: printers[i],
        onDelete: () => onDelete(printers[i]),
      ),
    );
  }
}

// ── Shared Helpers ────────────────────────────────────────────────────────────

class _TableIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFEAEFFD),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const AppIcon(AppIcons.printOutlined,
          size: 18, color: Color(0xFF3E63DD)),
    );
  }
}

class _TH extends StatelessWidget {
  final String text;
  final int flex;
  const _TH(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8A8FA3),
              letterSpacing: 0.3)),
    ),
  );
}

class _TD extends StatelessWidget {
  final Widget child;
  const _TD({required this.child});

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: child);
}

class _IconBtn extends StatelessWidget {
  final String icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _IconBtn(
      {required this.icon,
        required this.color,
        required this.tooltip,
        required this.onTap});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6)),
        child: AppIcon(icon, size: 16, color: color),
      ),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child:
    Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const AppIcon(AppIcons.errorOutline,
          size: 48, color: Colors.redAccent),
      const SizedBox(height: 12),
      Text(message,
          style: const TextStyle(color: Color(0xFF8A8FA3))),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
    ]),
  );
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) => Center(
    child:
    Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      AppIcon(AppIcons.printOutlined, size: 48, color: Colors.grey[300]),
      const SizedBox(height: 12),
      const Text('No printers found',
          style: TextStyle(color: Color(0xFF8A8FA3))),
    ]),
  );
}

InputDecoration _searchDecor(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)),
  prefixIcon: const Center(child: AppIcon(AppIcons.search, size: 16, color: Color(0xFF8A8FA3))),
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(vertical: 12),
  border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
  enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
  focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide:
      const BorderSide(color: Color(0xFF3E63DD), width: 1.5)),
);