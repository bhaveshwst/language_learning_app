import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.hint,
    this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.errorText,
    this.maxLines = 1,
    /// Tighter vertical padding (e.g. login / signup) without affecting other screens.
    this.dense = false,
  });

  final String hint;
  final TextEditingController? controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? errorText;
  final int maxLines;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: dense ? 15 : 16,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: suffixIcon,
        errorText: errorText,
        isDense: dense ? true : null,
        contentPadding: dense
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12)
            : null,
      ),
    );
  }
}
