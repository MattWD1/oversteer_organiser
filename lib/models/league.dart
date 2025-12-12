import 'package:flutter/material.dart';

class League {
  final String id;
  final String name;
  final String organiserName;
  final DateTime createdAt;
  final String joinCode; // simple invite/join code, e.g. 6 chars
  final int? themeColorValue; // Store color as int (0xFFRRGGBB format)

  const League({
    required this.id,
    required this.name,
    required this.organiserName,
    required this.createdAt,
    required this.joinCode,
    this.themeColorValue,
  });

  // Helper getter to convert int to Color
  Color get themeColor => themeColorValue != null
      ? Color(themeColorValue!)
      : const Color(0xFFD32F2F); // Default red color
}
