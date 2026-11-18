import 'package:flutter/material.dart';

abstract final class SharedTextStyles {
  static const input = TextStyle(fontSize: 16);

  static const inputHint = TextStyle(color: Color(0xFF8A8A8A), fontSize: 14);

  static const formSupporting = TextStyle(
    fontSize: 13,
    color: Color(0xFF6B6B6B),
    fontWeight: FontWeight.w500,
    height: 1.3,
  );
}
