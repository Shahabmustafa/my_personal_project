import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/widget/app_icon.dart';

// ─────────────────────────────────────────────────────────────────────────────
// QtyStepperField — compact "−  n  +" box around a caller-owned controller.
// Product selectors use this (value is read from the controller on Add).
//
//   QtyStepperField(controller: _qtyCtrl, enabled: stock != null,
//       color: primary, onSubmitted: (_) => _addToCart())
// ─────────────────────────────────────────────────────────────────────────────
class QtyStepperField extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final Color color;

  /// Upper limit for the + button; null or <= 0 means no limit.
  final int? max;
  final bool error;
  final double height;
  final double fontSize;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTapOutside;

  /// When set, − / + report the new value here instead of only editing text
  /// (cart rows push it straight to their notifier).
  final ValueChanged<int>? onStep;

  const QtyStepperField({
    super.key,
    required this.controller,
    required this.color,
    this.enabled = true,
    this.max,
    this.error = false,
    this.height = 40,
    this.fontSize = 15,
    this.onSubmitted,
    this.onTapOutside,
    this.onStep,
  });

  @override
  State<QtyStepperField> createState() => _QtyStepperFieldState();
}

class _QtyStepperFieldState extends State<QtyStepperField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(QtyStepperField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_rebuild);
      widget.controller.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  int get _value => int.tryParse(widget.controller.text) ?? 0;
  bool get _hasMax => widget.max != null && widget.max! > 0;

  void _step(int delta) {
    final next = _value + delta;
    widget.controller.text = '$next';
    widget.controller.selection =
        TextSelection.collapsed(offset: widget.controller.text.length);
    widget.onStep?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    final color = widget.color;
    final canDec = enabled && _value > 1;
    final canInc = enabled && (!_hasMax || _value < widget.max!);

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: !enabled
              ? Colors.grey.shade200
              : widget.error
                  ? Colors.red
                  : Colors.grey.shade300,
        ),
        color: enabled ? Colors.white : Colors.grey.shade50,
      ),
      child: Row(
        children: [
          _StepButton(
            icon: AppIcons.remove,
            color: color,
            onTap: canDec ? () => _step(-1) : null,
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              enabled: enabled,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w700,
                color: !enabled
                    ? Colors.grey.shade400
                    : widget.error
                        ? Colors.red
                        : Colors.black87,
              ),
              // Saare borders none — warna theme ka border/fill andar dikhta hai.
              decoration: const InputDecoration(
                isDense: true,
                filled: false,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
              ),
              onSubmitted: widget.onSubmitted,
              onTapOutside: widget.onTapOutside == null
                  ? null
                  : (_) => widget.onTapOutside!(),
            ),
          ),
          _StepButton(
            icon: AppIcons.add,
            color: color,
            onTap: canInc ? () => _step(1) : null,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QtyStepper — value-based version for cart table rows. Typed values are
// clamped to 1..max when committed (submit / tap outside).
// ─────────────────────────────────────────────────────────────────────────────
class QtyStepper extends StatefulWidget {
  final int value;
  final Color color;

  /// null or <= 0 means no upper limit (e.g. purchase).
  final int? max;
  final ValueChanged<int> onChanged;

  const QtyStepper({
    super.key,
    required this.value,
    required this.color,
    required this.onChanged,
    this.max,
  });

  @override
  State<QtyStepper> createState() => _QtyStepperState();
}

class _QtyStepperState extends State<QtyStepper> {
  late final TextEditingController _ctrl =
      TextEditingController(text: '${widget.value}');

  @override
  void didUpdateWidget(QtyStepper old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && _ctrl.text != '${widget.value}') {
      _ctrl.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _commit() {
    final v = int.tryParse(_ctrl.text) ?? widget.value;
    final max = widget.max;
    final safe = (max != null && max > 0) ? v.clamp(1, max) : (v < 1 ? 1 : v);
    _ctrl.text = '$safe';
    if (safe != widget.value) widget.onChanged(safe);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 116,
        child: QtyStepperField(
          controller: _ctrl,
          color: widget.color,
          max: widget.max,
          height: 32,
          fontSize: 13,
          onStep: widget.onChanged,
          onSubmitted: (_) => _commit(),
          onTapOutside: _commit,
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final String icon;
  final Color color;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 30,
        height: double.infinity,
        child: Center(
          child: AppIcon(icon,
              size: 15, color: onTap == null ? Colors.grey.shade300 : color),
        ),
      ),
    );
  }
}
