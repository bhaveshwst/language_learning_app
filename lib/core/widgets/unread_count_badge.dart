import 'package:flutter/material.dart';
import 'package:language_learning_app/core/constants/const_color.dart';

class UnreadCountBadge extends StatelessWidget {
  const UnreadCountBadge({
    super.key,
    required this.count,
    this.size = 22,
  });

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final label = count > 99 ? '99+' : '$count';

    return Container(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}
