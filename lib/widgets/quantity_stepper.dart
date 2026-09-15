import 'dart:async';

import 'package:flutter/material.dart';

import '../models/grocery_item.dart';
import '../providers/inventory_provider.dart';

/// Stock quantity stepper (-/+, with a tap-to-type number field) shared by
/// the home item list and the order details screen, so both look and behave
/// identically. Debounces +/- taps into a single write after the user
/// pauses, instead of one write per tap.
class QuantityStepper extends StatefulWidget {
  final GroceryItem item;
  final InventoryProvider inventory;
  const QuantityStepper({super.key, required this.item, required this.inventory});

  @override
  State<QuantityStepper> createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<QuantityStepper> {
  late TextEditingController _controller;

  // Non-null while a +/- edit hasn't been written (and re-fetched) yet, so
  // rapid taps only trigger one debounced write instead of one per tap, and
  // so a stale provider echo of our own pending edit doesn't clobber it.
  double? _pendingQuantity;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _formatQty(widget.item.currentQuantity),
    );
  }

  String _formatQty(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toString();
  }

  @override
  void didUpdateWidget(QuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.currentQuantity != widget.item.currentQuantity) {
      if (_pendingQuantity == null ||
          widget.item.currentQuantity == _pendingQuantity) {
        _pendingQuantity = null;
        final textVal = double.tryParse(_controller.text) ?? 0;
        if (textVal != widget.item.currentQuantity) {
          _controller.text = _formatQty(widget.item.currentQuantity);
        }
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (_pendingQuantity != null) {
      // Flush immediately so a rapid tap-then-navigate-away isn't lost.
      widget.inventory.updateItemQuantity(widget.item.id, _pendingQuantity!);
    }
    _controller.dispose();
    super.dispose();
  }

  void _stepBy(double delta) {
    final base = _pendingQuantity ?? widget.item.currentQuantity;
    final next = base + delta;
    if (next < 0) return;

    setState(() {
      _pendingQuantity = next;
      _controller.text = _formatQty(next);
    });

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      widget.inventory.updateItemQuantity(widget.item.id, next);
    });
  }

  void _submit(String value) {
    // Unfocus to hide keyboard/cursor
    FocusScope.of(context).unfocus();

    _debounce?.cancel();
    final newQty = double.tryParse(value);
    if (newQty != null && newQty >= 0) {
      _pendingQuantity = null;
      widget.inventory.updateItemQuantity(widget.item.id, newQty);
    } else {
      // Revert if invalid
      _controller.text = _formatQty(
        _pendingQuantity ?? widget.item.currentQuantity,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStepButton(icon: Icons.remove, onPressed: () => _stepBy(-1)),
          Container(
            width: 50,
            alignment: Alignment.center,
            child: TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: _submit,
              onTapOutside: (_) => _submit(_controller.text),
            ),
          ),
          _buildStepButton(
            icon: Icons.add,
            onPressed: () => _stepBy(1),
            isAdd: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStepButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isAdd = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: isAdd ? Colors.orangeAccent : Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
            boxShadow: isAdd
                ? [
                    BoxShadow(
                      color: Colors.orangeAccent.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Icon(icon, color: isAdd ? Colors.black : Colors.white, size: 14),
        ),
      ),
    );
  }
}
