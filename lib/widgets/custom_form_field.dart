import 'package:flutter/material.dart';
import 'package:matajer/constants/colors.dart';

class CustomFormField extends StatelessWidget {
  const CustomFormField({
    super.key,
    this.title = 'title',
    required this.hint,
    required this.onTap,
    required this.controller,
    this.textColor,
    this.color,
    this.errorStyle,
    this.keyboardType,
    this.contentPadding,
    this.validator,
    this.onChanged,
    this.onSubmit,
    this.prefix,
    this.hintStyle,
    this.fieldTextStyle,
    this.maxLines,
    this.suffix,
    this.obscure = false,
    this.readOnly = false,
    this.hasTitle = false,
    this.outlineInputBorder,
    this.cursorColor,
  });

  final String title;
  final String hint;
  final int? maxLines;
  final void Function(String?)? onSubmit, onChanged;
  final String? Function(String?)? validator;
  final void Function() onTap;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextStyle? errorStyle, fieldTextStyle, hintStyle;
  final EdgeInsets? contentPadding;
  final Widget? prefix, suffix;
  final bool obscure, readOnly, hasTitle;
  final Color? textColor, color, cursorColor;
  final OutlineInputBorder? outlineInputBorder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          hasTitle == true
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
      children: [
        if (hasTitle == true)
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor ?? primaryColor.withOpacity(0.75),
            ),
          ),
        if (hasTitle == true) SizedBox(height: 8),
        TextFormField(
          readOnly: readOnly,
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          onTap: onTap,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmit,
          onTapOutside: (val) {
            FocusScope.of(context).unfocus();
          },
          maxLines: maxLines,
          cursorColor: cursorColor,
          style: fieldTextStyle,
          decoration: InputDecoration(
            fillColor: color,
            contentPadding: contentPadding,
            hintStyle: hintStyle,
            errorStyle: errorStyle,
            suffixIcon: suffix,
            prefixIcon: prefix,
            hintText: hint,
            border: outlineInputBorder,
            focusedBorder: outlineInputBorder,
            enabledBorder: outlineInputBorder,
          ),
        ),
      ],
    );
  }
}
