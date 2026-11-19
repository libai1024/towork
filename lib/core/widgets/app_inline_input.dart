import 'package:flutter/material.dart';

/// For editors whose parent already draws the surface (search, composer, title).
InputDecoration appInlineInput({
  required String hintText,
  required TextStyle hintStyle,
  EdgeInsetsGeometry padding = EdgeInsets.zero,
  BoxConstraints? constraints,
}) => InputDecoration(
  hintText: hintText,
  hintStyle: hintStyle,
  isDense: true,
  filled: false,
  constraints: constraints,
  contentPadding: padding,
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
  disabledBorder: InputBorder.none,
);
