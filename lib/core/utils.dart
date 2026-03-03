import 'package:flutter/material.dart';

extension ResponsiveFontSize on double {
  double responsiveFontSize(BuildContext context, {double? minFontSize}) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600 && minFontSize != null) {
      return minFontSize;
    }
    return this;
  }
}
