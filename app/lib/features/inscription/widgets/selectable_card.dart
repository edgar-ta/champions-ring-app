import 'package:flutter/material.dart';

import 'personal_data_form.dart' show kRojo;

class SelectableCard extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;

  const SelectableCard({
    super.key,
    required this.isSelected,
    required this.onTap,
    required this.child,
  });

  @override
  State<SelectableCard> createState() => _SelectableCardState();
}

class _SelectableCardState extends State<SelectableCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFFF1F1)
                : _isHovered
                ? const Color(0xFFF8F8F8)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? kRojo
                  : _isHovered
                  ? const Color(0xFFBDBDBD)
                  : const Color(0xFFE3E3E3),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class SelectionRadioIndicator extends StatelessWidget {
  final bool isSelected;

  const SelectionRadioIndicator({super.key, required this.isSelected});

  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 22,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white,
      border: Border.all(
        color: isSelected ? kRojo : const Color(0xFFBDBDBD),
        width: 2,
      ),
    ),
    child: isSelected
        ? Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: kRojo,
                shape: BoxShape.circle,
              ),
            ),
          )
        : null,
  );
}
