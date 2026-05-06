/// 外部交換・ギフトコード連携などはこの境界に置く。
///
/// 初期 MVP ではルート・UI・API クライアントを追加しない。
/// コアの [PointLedgerRepository] を読むアダプタはここから依存させる。
abstract final class ExchangeModuleBoundary {
  const ExchangeModuleBoundary._();
}
