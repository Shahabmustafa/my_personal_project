import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/model/product_model.dart';
import '../providers/product_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
class ProductFormDialog extends ConsumerStatefulWidget {
  final ProductModel? product;
  final VoidCallback? onSaved;

  const ProductFormDialog({
    super.key,
    this.product,
    this.onSaved,
  });

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _salePriceCtrl;
  late final TextEditingController _purchasePriceCtrl;

  Uint8List? _imageBytes;
  String? _imageMime;
  String? _imageFileName;
  String? _existingImageUrl;
  bool _isLoading = false;

  /// Server-side "article already exists" message, shown inline under the
  /// Article Name field. Cleared as soon as the name is edited.
  String? _duplicateNameError;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.articleName ?? '');
    _salePriceCtrl = TextEditingController(
        text: (p != null && p.salePrice != 0)
            ? p.salePrice.toStringAsFixed(2)
            : '');
    _purchasePriceCtrl = TextEditingController(
        text: (p != null && p.purchasePrice != 0)
            ? p.purchasePrice.toStringAsFixed(2)
            : '');
    _existingImageUrl =
        (p?.imageUrl.isNotEmpty == true) ? p!.imageUrl : null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _salePriceCtrl.dispose();
    _purchasePriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final ext = picked.name.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    final safeName = picked.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _imageBytes = bytes;
      _imageMime = mime;
      _imageFileName = '${timestamp}_$safeName';
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    // Check for a duplicate article name up front, before uploading any image,
    // so a rejected save never leaves an orphaned file in storage.
    final duplicate = await ref.read(productProvider.notifier).articleNameExists(
          _nameCtrl.text.trim(),
          excludeId: widget.product?.id,
        );
    if (!mounted) return;
    if (duplicate) {
      setState(() {
        _isLoading = false;
        _duplicateNameError = widget.product == null
            ? 'A product with this article already exists'
            : 'Another product with this article already exists';
      });
      _formKey.currentState?.validate();
      return;
    }

    String imageUrl = _existingImageUrl ?? '';

    if (_imageBytes != null && _imageFileName != null) {
      final url = await ref.read(productProvider.notifier).uploadImage(
            fileName: _imageFileName!,
            bytes: _imageBytes!,
            mimeType: _imageMime ?? 'image/jpeg',
          );
      if (url == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Image upload failed'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }
      imageUrl = url;
    }

    final model = ProductModel(
      id: widget.product?.id ?? '',
      articleName: _nameCtrl.text.trim(),
      salePrice: double.tryParse(_salePriceCtrl.text.trim()) ?? 0,
      purchasePrice: double.tryParse(_purchasePriceCtrl.text.trim()) ?? 0,
      imageUrl: imageUrl,
    );

    final error = widget.product == null
        ? await ref.read(productProvider.notifier).create(model)
        : await ref.read(productProvider.notifier).update(model);

    if (!mounted) return;
    if (error != null) {
      final isDuplicate = error.toLowerCase().contains('already exists');
      setState(() {
        _isLoading = false;
        if (isDuplicate) _duplicateNameError = error;
      });
      if (isDuplicate) {
        _formKey.currentState?.validate();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }
    Navigator.pop(context);
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const AppIcon(AppIcons.inventory2Outlined,
              color: Color(0xFF3E63DD), size: 20),
          const SizedBox(width: 8),
          Text(isEdit ? 'Edit Product' : 'Add Product',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 17)),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 4),
                // Image picker
                GestureDetector(
                  onTap: _isLoading ? null : _pickImage,
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFE7E9F0), width: 1.5),
                    ),
                    child: _imageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: Image.memory(_imageBytes!,
                                fit: BoxFit.cover,
                                width: double.infinity),
                          )
                        : _existingImageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: Image.network(
                                  _existingImageUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (_, __, ___) =>
                                      _uploadPlaceholder(),
                                ),
                              )
                            : _uploadPlaceholder(),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _imageBytes != null
                      ? 'Image selected — tap to change'
                      : 'Tap to select image',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF8A8FA3)),
                ),
                const SizedBox(height: 14),
                _Field(
                  controller: _nameCtrl,
                  label: 'Article Name *',
                  hint: 'e.g. Sports Shoe 001',
                  icon: AppIcons.inventory2Outlined,
                  onChanged: (_) {
                    if (_duplicateNameError != null) {
                      setState(() => _duplicateNameError = null);
                    }
                  },
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Article name is required';
                    }
                    if (_duplicateNameError != null) return _duplicateNameError;
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _Field(
                  controller: _salePriceCtrl,
                  label: 'Sale Price *',
                  hint: '0.00',
                  icon: AppIcons.sellOutlined,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Sale price is required';
                    if (double.tryParse(v.trim()) == null)
                      return 'Enter a valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _Field(
                  controller: _purchasePriceCtrl,
                  label: 'Purchase Price *',
                  hint: '0.00',
                  icon: AppIcons.shoppingCartOutlined,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Purchase price is required';
                    if (double.tryParse(v.trim()) == null)
                      return 'Enter a valid amount';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3E63DD),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text(isEdit ? 'Update' : 'Save'),
        ),
      ],
    );
  }

  Widget _uploadPlaceholder() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          AppIcon(AppIcons.addPhotoAlternateOutlined,
              size: 36, color: Color(0xFF8A8FA3)),
          SizedBox(height: 8),
          Text('Tap to upload image',
              style: TextStyle(fontSize: 12, color: Color(0xFF8A8FA3))),
        ],
      );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(fontSize: 13),
        prefixIcon: AppIcon(icon, size: 18, color: const Color(0xFF8A8FA3)),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: Color(0xFF3E63DD), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.redAccent)),
      ),
    );
  }
}
