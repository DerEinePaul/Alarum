import 'package:flutter/material.dart';

class AppConstants {
  static const double defaultBorderRadius = 16.0;
  static const double defaultPadding = 24.0;
  static const double defaultElevation = 4.0;

  static ButtonStyle filledButtonStyle(BuildContext context) {
    return FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(defaultBorderRadius),
      ),
    );
  }

  static ButtonStyle outlinedButtonStyle(BuildContext context) {
    return OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(defaultBorderRadius),
      ),
    );
  }

  static ButtonStyle filledTonalButtonStyle(BuildContext context) {
    return FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(defaultBorderRadius),
      ),
    );
  }

  static ShapeBorder cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(defaultBorderRadius),
  );

  static TextStyle displayTextStyle(BuildContext context, {FontWeight? fontWeight}) {
    return Theme.of(context).textTheme.displayMedium?.copyWith(
          fontWeight: fontWeight ?? FontWeight.w300,
          fontFeatures: [const FontFeature.tabularFigures()],
        ) ?? const TextStyle();
  }

  static TextStyle bodyTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontFeatures: [const FontFeature.tabularFigures()],
        ) ?? const TextStyle();
  }
}