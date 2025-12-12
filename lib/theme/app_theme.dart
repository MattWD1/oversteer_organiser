// lib/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme extends InheritedWidget {
  final Color primaryColor;

  const AppTheme({
    super.key,
    required this.primaryColor,
    required super.child,
  });

  static AppTheme? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppTheme>();
  }

  static AppTheme of(BuildContext context) {
    final AppTheme? result = maybeOf(context);
    assert(result != null, 'No AppTheme found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AppTheme oldWidget) {
    return primaryColor != oldWidget.primaryColor;
  }
}
