import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_size.dart';

/// A consistently-styled dropdown used across the app.
/// Starts empty (shows [hintText]) until the user selects an item.
enum AppDropdownTheme { theme1, theme2 }

class AppDropdownButton2<T> extends StatefulWidget {
  const AppDropdownButton2({
    super.key,
    required this.hintText,
    required this.items,
    required this.itemLabelBuilder,
    required this.onChanged,
    this.value,
    this.theme = AppDropdownTheme.theme1,
    this.enabled = true,
  });

  final String hintText;
  final List<T> items;
  final String Function(T item) itemLabelBuilder;
  final ValueChanged<T?> onChanged;
  final T? value;
  final AppDropdownTheme theme;
  final bool enabled;

  @override
  State<AppDropdownButton2<T>> createState() => _AppDropdownButton2State<T>();
}

class _AppDropdownButton2State<T> extends State<AppDropdownButton2<T>> {
  late final ValueNotifier<T?> _valueListenable = ValueNotifier<T?>(
    widget.value,
  );

  @override
  void initState() {
    super.initState();
    _valueListenable.value = widget.value;
  }

  @override
  void didUpdateWidget(covariant AppDropdownButton2<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _valueListenable.value = widget.value;
    }
  }

  @override
  void dispose() {
    _valueListenable.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTheme2 = widget.theme == AppDropdownTheme.theme2;
    return DropdownButtonHideUnderline(
      child: SizedBox(
        width: double.infinity,
        height: ConstSize.buttonHeight,
        child: DropdownButton2<T>(
          isExpanded: true,
          hint: Text(
            widget.hintText,
            style: TextStyle(
              color: ConstColor.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          items: widget.items
              .map(
                (item) => DropdownItem<T>(
                  value: item,
                  height: 48,
                  child: Text(
                    widget.itemLabelBuilder(item),
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          valueListenable: _valueListenable,
          onChanged: widget.enabled
              ? (val) {
                  _valueListenable.value = val;
                  widget.onChanged(val);
                }
              : null,
          buttonStyleData: ButtonStyleData(
            height: ConstSize.buttonHeight,
            padding: const EdgeInsets.symmetric(horizontal: 0),
            decoration: BoxDecoration(
              color: isTheme2 ? const Color(0xFFF4F8FF) : Colors.white,
              borderRadius: BorderRadius.circular(ConstSize.radiusM),
              border: Border.all(
                color: isTheme2 ? const Color(0xFFDAE6FF) : ConstColor.border,
                width: 1.2,
              ),
            ),
          ),
          iconStyleData: IconStyleData(
            icon: Icon(Icons.keyboard_arrow_down, color: ConstColor.grey),
            iconSize: 26,
          ),
          dropdownStyleData: DropdownStyleData(
            maxHeight: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(ConstSize.radiusM),
            ),
          ),
          menuItemStyleData: const MenuItemStyleData(
            padding: EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ),
    );
  }
}
