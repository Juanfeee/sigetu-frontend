import 'package:flutter/material.dart';

class AppGradients {
  static LinearGradient primary(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    if (brightness == Brightness.dark) {
      return const LinearGradient(
        colors: [Color(0xFF1E5BEF), Color(0xFF3A7BFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    return const LinearGradient(
      colors: [
        Color(0xFF1E5BEF),
        Color(0xFF3A7BFF), 
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
