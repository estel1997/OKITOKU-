/// 買い物までの移動手段（ガソリン・モノレール料金の切り替えに使用）
enum ShoppingTransport {
  /// 自家用車（那覇市周辺レギュラー単価 × 仮の往復距離）
  car,

  /// ゆいレール等（定額の目安）
  monorail,

  /// 徒歩・自転車（移動費 0）
  walkOrBike,
}

extension ShoppingTransportJa on ShoppingTransport {
  String get label => switch (this) {
        ShoppingTransport.car => '自動車',
        ShoppingTransport.monorail => 'モノレール（ゆいレール等）',
        ShoppingTransport.walkOrBike => '徒歩・自転車',
      };

  /// セグメント UI 用の短いラベル
  String get shortLabel => switch (this) {
        ShoppingTransport.car => '自動車',
        ShoppingTransport.monorail => 'モノレール',
        ShoppingTransport.walkOrBike => '徒歩・自転車',
      };
}
