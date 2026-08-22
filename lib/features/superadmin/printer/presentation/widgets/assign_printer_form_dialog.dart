import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/widget/app_dropdown.dart';
import '../../data/models/printer_head_model.dart';
import '../providers/printer_providers.dart';

class AssignPrinterFormDialog extends ConsumerStatefulWidget {
  final void Function({
    required String branchId,
    required String printerHeadId,
  }) onSave;

  const AssignPrinterFormDialog({super.key, required this.onSave});

  @override
  ConsumerState<AssignPrinterFormDialog> createState() =>
      _AssignPrinterFormDialogState();
}

class _AssignPrinterFormDialogState
    extends ConsumerState<AssignPrinterFormDialog> {
  String? _selectedPrinterHeadId;
  String? _selectedBranchId;
  String? _printerError;
  String? _branchError;

  // Replace with branchProvider if dynamic branches needed
  static const List<Map<String, String>> _branches = [
    {
      'id':   '53743001-b131-4de8-8d1f-8613a88b1729',
      'name': 'Safi Shoes Branch 2',
    },
    {
      'id':   '6d597ef9-91ec-4003-a87b-7a0f63fb174d',
      'name': 'Safi Shoe',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedBranchId = _branches.first['id'];
  }

  @override
  Widget build(BuildContext context) {
    final printersAsync = ref.watch(printerHeadsProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Assign Printer to Branch',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: 420,
        child: printersAsync.when(
          loading: () => const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text(
            'Failed to load printers: $e',
            style: const TextStyle(color: Colors.red),
          ),
          data: (printers) {
            if (_selectedPrinterHeadId == null && printers.isNotEmpty) {
              _selectedPrinterHeadId = printers.first.id;
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Printer Head dropdown
                _buildPrinterDropdown(printers),
                const SizedBox(height: 12),

                // Branch dropdown
                _buildBranchDropdown(),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3E63DD),
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _submit,
          child: const Text('Assign'),
        ),
      ],
    );
  }

  void _submit() {
    setState(() {
      _printerError =
          _selectedPrinterHeadId == null ? 'Select a printer' : null;
      _branchError = _selectedBranchId == null ? 'Select a branch' : null;
    });
    if (_printerError != null || _branchError != null) return;
    widget.onSave(
      branchId:      _selectedBranchId!,
      printerHeadId: _selectedPrinterHeadId!,
    );
    Navigator.pop(context);
  }

  Widget _buildPrinterDropdown(List<PrinterHeadModel> printers) {
    final selected = printers
            .where((p) => p.id == _selectedPrinterHeadId)
            .isNotEmpty
        ? printers.firstWhere((p) => p.id == _selectedPrinterHeadId)
        : null;

    return AppSearchDropdown<PrinterHeadModel>(
      label: 'Printer Head',
      isRequired: true,
      items: printers,
      selectedItem: selected,
      itemLabel: (p) => p.name,
      prefixIcon: const Icon(Icons.print_outlined, size: 18),
      errorText: _printerError,
      onChanged: (p) => setState(() {
        _selectedPrinterHeadId = p?.id;
        _printerError = null;
      }),
    );
  }

  Widget _buildBranchDropdown() {
    final selected = _branches
        .where((b) => b['id'] == _selectedBranchId)
        .isNotEmpty
        ? _branches.firstWhere((b) => b['id'] == _selectedBranchId)
        : null;

    return AppSearchDropdown<Map<String, String>>(
      label: 'Branch',
      isRequired: true,
      items: _branches,
      selectedItem: selected,
      itemLabel: (b) => b['name']!,
      prefixIcon: const Icon(Icons.store_outlined, size: 18),
      errorText: _branchError,
      onChanged: (b) => setState(() {
        _selectedBranchId = b?['id'];
        _branchError = null;
      }),
    );
  }
}
