import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/customer_model.dart';
import '../providers/customer_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/widget/text_field_icon.dart';
class LoyaltyDialog extends ConsumerStatefulWidget {
  final CustomerModel customer;
  const LoyaltyDialog({super.key, required this.customer});

  @override
  ConsumerState<LoyaltyDialog> createState() => _LoyaltyDialogState();
}

class _LoyaltyDialogState extends ConsumerState<LoyaltyDialog> {
  final _ctrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isAdd = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    final points = int.parse(_ctrl.text.trim());
    try {
      if (_isAdd) {
        await ref.read(customerProvider.notifier).addLoyaltyPoints(
              customerId: widget.customer.id,
              points: points,
            );
      } else {
        await ref.read(customerProvider.notifier).redeemLoyaltyPoints(
              customerId: widget.customer.id,
              points: points,
            );
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isAdd
                ? '$points points added successfully'
                : '$points points redeemed successfully'),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const AppIcon(AppIcons.starOutline, color: Color(0xFFD4A017), size: 22),
          const SizedBox(width: 8),
          Text('Loyalty Points — ${widget.customer.name}',
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Current points info
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFD4A017).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const AppIcon(AppIcons.star, color: Color(0xFFD4A017), size: 28),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.customer.loyaltyPoints} Points',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B6914)),
                        ),
                        Text(
                          widget.customer.loyaltyTier,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFFD4A017)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Add / Redeem toggle
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isAdd = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _isAdd
                              ? const Color(0xFF3E63DD)
                              : const Color(0xFFF7F8FC),
                          borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(8)),
                          border: Border.all(color: const Color(0xFFE7E9F0)),
                        ),
                        alignment: Alignment.center,
                        child: Text('Add Points',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _isAdd
                                    ? Colors.white
                                    : const Color(0xFF8A8FA3))),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isAdd = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_isAdd
                              ? Colors.redAccent
                              : const Color(0xFFF7F8FC),
                          borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(8)),
                          border: Border.all(color: const Color(0xFFE7E9F0)),
                        ),
                        alignment: Alignment.center,
                        child: Text('Redeem Points',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: !_isAdd
                                    ? Colors.white
                                    : const Color(0xFF8A8FA3))),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Points input
              TextFormField(
                controller: _ctrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _isAdd ? 'Points to Add' : 'Points to Redeem',
                  hintText: 'e.g. 50',
                  prefixIcon: const TextFieldIcon(AppIcons.starOutline,
                      size: 12, color: Color(0xFF8A8FA3)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Color(0xFF3E63DD), width: 1.5)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter points';
                  final val = int.tryParse(v.trim());
                  if (val == null || val <= 0) return 'Enter a valid number';
                  if (!_isAdd && val > widget.customer.loyaltyPoints) {
                    return 'Not enough points (max ${widget.customer.loyaltyPoints})';
                  }
                  return null;
                },
              ),
            ],
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
            backgroundColor:
                _isAdd ? const Color(0xFF3E63DD) : Colors.redAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text(_isAdd ? 'Add' : 'Redeem'),
        ),
      ],
    );
  }
}
