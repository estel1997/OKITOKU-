/// 自動車の燃費プロファイル（km/L）
enum CarFuelProfile {
  /// ファミリーカー目安 10.5 km/L
  family105,

  /// 軽自動車目安 18 km/L
  kei18,
}

extension CarFuelProfileX on CarFuelProfile {
  double get kmPerLiter => switch (this) {
        CarFuelProfile.family105 => 10.5,
        CarFuelProfile.kei18 => 18,
      };

  String get label => switch (this) {
        CarFuelProfile.family105 => 'ファミリーカー（10.5 km/L）',
        CarFuelProfile.kei18 => '軽自動車（18 km/L）',
      };
}
