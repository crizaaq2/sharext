import 'package:flutter/material.dart';

/// Sonar (2027) design tokens — PLAN section 6.
///
/// Nothing outside this file may hard-code a colour, a radius or a duration.
@immutable
class SonarTokens extends ThemeExtension<SonarTokens> {
  const SonarTokens({
    required this.base,
    required this.raised,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.text,
    required this.secondaryText,
    required this.danger,
  });

  /// Deep sea teal, not neutral black.
  final Color base;

  /// Raised surface and incoming bubble.
  final Color raised;

  /// Lagoon: primary action and outgoing bubble.
  final Color primary;

  /// Text that sits on [primary] (tideInk on lagoon in dark).
  final Color onPrimary;

  /// Sun: peer ring, unread badge, attention.
  final Color accent;

  /// Foam: main text.
  final Color text;

  /// Mist: secondary text.
  final Color secondaryText;

  /// Coral: danger only.
  final Color danger;

  static const SonarTokens dark = SonarTokens(
    base: Color(0xFF06222B),
    raised: Color(0xFF0D3441),
    primary: Color(0xFF22D1C6),
    onPrimary: Color(0xFF06222B),
    accent: Color(0xFFFFB43A),
    text: Color(0xFFEAF7F6),
    secondaryText: Color(0xFF8FB4B8),
    danger: Color(0xFFFF6B5B),
  );

  static const SonarTokens light = SonarTokens(
    base: Color(0xFFF2FAF9),
    raised: Color(0xFFFFFFFF),
    primary: Color(0xFF087A77),
    onPrimary: Color(0xFFFFFFFF),
    accent: Color(0xFF9A5B00),
    text: Color(0xFF072229),
    secondaryText: Color(0xFF4F7176),
    danger: Color(0xFFC2352A),
  );

  /// The tokens for the current theme.
  static SonarTokens of(BuildContext context) =>
      Theme.of(context).extension<SonarTokens>() ?? dark;

  @override
  SonarTokens copyWith({
    Color? base,
    Color? raised,
    Color? primary,
    Color? onPrimary,
    Color? accent,
    Color? text,
    Color? secondaryText,
    Color? danger,
  }) => SonarTokens(
    base: base ?? this.base,
    raised: raised ?? this.raised,
    primary: primary ?? this.primary,
    onPrimary: onPrimary ?? this.onPrimary,
    accent: accent ?? this.accent,
    text: text ?? this.text,
    secondaryText: secondaryText ?? this.secondaryText,
    danger: danger ?? this.danger,
  );

  @override
  SonarTokens lerp(ThemeExtension<SonarTokens>? other, double t) {
    if (other is! SonarTokens) return this;
    return SonarTokens(
      base: Color.lerp(base, other.base, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      text: Color.lerp(text, other.text, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

/// Type scale in logical pixels (§6). Both families are bundled assets.
abstract final class SxType {
  static const List<FontVariation> _displayWeight = <FontVariation>[
    FontVariation('wght', 760),
  ];
  static const List<FontVariation> _titleWeight = <FontVariation>[
    FontVariation('wght', 620),
  ];
  static const List<FontVariation> _bodyWeight = <FontVariation>[
    FontVariation('wght', 400),
  ];
  static const List<FontVariation> _labelWeight = <FontVariation>[
    FontVariation('wght', 520),
  ];

  /// display 34/38, Bricolage 600–800.
  static const TextStyle display = TextStyle(
    fontFamily: 'Bricolage',
    fontSize: 34,
    height: 38 / 34,
    letterSpacing: -0.6,
    fontWeight: FontWeight.w700,
    fontVariations: _displayWeight,
  );

  /// title 22/28.
  static const TextStyle title = TextStyle(
    fontFamily: 'Bricolage',
    fontSize: 22,
    height: 28 / 22,
    letterSpacing: -0.2,
    fontWeight: FontWeight.w600,
    fontVariations: _titleWeight,
  );

  /// body 16/24.
  static const TextStyle body = TextStyle(
    fontFamily: 'Readex',
    fontSize: 16,
    height: 24 / 16,
    fontVariations: _bodyWeight,
  );

  /// chat 16/22.
  static const TextStyle chat = TextStyle(
    fontFamily: 'Readex',
    fontSize: 16,
    height: 22 / 16,
    fontVariations: _bodyWeight,
  );

  /// label 14/20, weight 500.
  static const TextStyle label = TextStyle(
    fontFamily: 'Readex',
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    fontVariations: _labelWeight,
  );

  /// caption 12/16.
  static const TextStyle caption = TextStyle(
    fontFamily: 'Readex',
    fontSize: 12,
    height: 16 / 12,
    fontVariations: _bodyWeight,
  );
}

/// Shape by role (§6).
abstract final class SxRadius {
  static const double bubble = 20;
  static const double bubbleTail = 6;
  static const double tile = 16;
  static const double input = 24;
  static const double sheet = 28;
  static const Radius pill = Radius.circular(999);
}

/// 4 dp grid.
abstract final class SxSpace {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x12 = 48;
}

/// Motion (§6): answers an action, never decoration.
abstract final class SxMotion {
  static const Duration micro = Duration(milliseconds: 120);
  static const Duration standard = Duration(milliseconds: 240);
  static const Duration emphasized = Duration(milliseconds: 420);
  static const Duration pingLoop = Duration(milliseconds: 2400);

  static const Curve snappy = Cubic(0.2, 0, 0, 1);
  static const Curve smooth = Cubic(0.35, 0, 0.25, 1);
  static const Curve lens = Cubic(0.16, 1, 0.3, 1);
}

/// Layout breakpoints (§6).
abstract final class SxBreakpoint {
  static const double rail = 840;
  static const double threePane = 1200;
  static const double bubbleMaxPhone = 0.78;
  static const double bubbleMaxDesktop = 560;
}
