import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharext/design/tokens.dart';

/// WCAG contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double hi = la > lb ? la : lb;
  final double lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('dark tokens meet 4.5:1 wherever text sits', () {
    const SonarTokens t = SonarTokens.dark;
    expect(contrast(t.text, t.base), greaterThanOrEqualTo(4.5));
    expect(contrast(t.text, t.raised), greaterThanOrEqualTo(4.5));
    expect(contrast(t.onPrimary, t.primary), greaterThanOrEqualTo(4.5));
    expect(contrast(t.primary, t.base), greaterThanOrEqualTo(4.5));
    expect(contrast(t.secondaryText, t.base), greaterThanOrEqualTo(4.5));
    expect(contrast(t.accent, t.base), greaterThanOrEqualTo(4.5));
    expect(contrast(t.danger, t.base), greaterThanOrEqualTo(4.5));
  });

  test('light tokens meet 4.5:1 wherever text sits', () {
    const SonarTokens t = SonarTokens.light;
    expect(contrast(t.text, t.base), greaterThanOrEqualTo(4.5));
    expect(contrast(t.text, t.raised), greaterThanOrEqualTo(4.5));
    expect(contrast(t.onPrimary, t.primary), greaterThanOrEqualTo(4.5));
    expect(contrast(t.primary, t.base), greaterThanOrEqualTo(4.5));
    expect(contrast(t.secondaryText, t.base), greaterThanOrEqualTo(4.5));
    expect(contrast(t.accent, t.base), greaterThanOrEqualTo(4.5));
    expect(contrast(t.danger, t.base), greaterThanOrEqualTo(4.5));
  });

  test('every token is defined in both themes', () {
    expect(SonarTokens.dark.base, isNot(SonarTokens.light.base));
    expect(SonarTokens.dark.text, const Color(0xFFEAF7F6));
    expect(SonarTokens.dark.primary, const Color(0xFF22D1C6));
    expect(SonarTokens.light.primary, const Color(0xFF087A77));
  });
}
