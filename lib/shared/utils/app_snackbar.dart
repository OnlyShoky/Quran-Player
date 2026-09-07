import 'dart:async';
import 'package:flutter/material.dart';

Timer? _snackBarTimer;

/// Displays a short-lived floating SnackBar with a close button,
/// clearing any previously active SnackBars and guaranteeing auto-dismissal after at most 2.5s.
void showAppSnackBar(
  BuildContext context,
  String message, {
  SnackBarAction? action,
  Duration duration = const Duration(milliseconds: 2500),
}) {
  _snackBarTimer?.cancel();
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();

  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      showCloseIcon: true,
      closeIconColor: Colors.white,
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.horizontal,
      action: action,
    ),
  );

  _snackBarTimer = Timer(duration, () {
    try {
      messenger.hideCurrentSnackBar();
    } catch (_) {}
  });
}
