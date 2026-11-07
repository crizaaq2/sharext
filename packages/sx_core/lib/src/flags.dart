/// Typed local feature flags (SX-008).
///
/// Flags change behaviour without a rebuild. They are overridable from
/// Diagnostics; nothing here talks to a server.
library;

enum FeatureFlag { l2cap, rfcomm, turbo, showOtherDevices }

/// Values for every flag, with the 1.0 defaults from the plan.
class FeatureFlags {
  FeatureFlags({Map<FeatureFlag, bool>? overrides})
    : _overrides = <FeatureFlag, bool>{...?overrides};

  /// Defaults: L2CAP on (it falls back to GATT by itself), the accelerators off.
  static const Map<FeatureFlag, bool> defaults = <FeatureFlag, bool>{
    FeatureFlag.l2cap: true,
    FeatureFlag.rfcomm: false,
    FeatureFlag.turbo: false,
    FeatureFlag.showOtherDevices: false,
  };

  final Map<FeatureFlag, bool> _overrides;

  bool isEnabled(FeatureFlag flag) => _overrides[flag] ?? defaults[flag] ?? false;

  /// Returns a new set with [flag] overridden; never mutates a shared instance.
  FeatureFlags withFlag(FeatureFlag flag, {required bool enabled}) =>
      FeatureFlags(overrides: <FeatureFlag, bool>{..._overrides, flag: enabled});

  Map<String, bool> toJson() => <String, bool>{
    for (final FeatureFlag flag in FeatureFlag.values)
      flag.name: isEnabled(flag),
  };
}
