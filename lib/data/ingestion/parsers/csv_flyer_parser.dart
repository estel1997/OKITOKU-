import 'package:uuid/uuid.dart';

import '../../../domain/entities/flyer_offer.dart';

/// CSV 文字列 → [FlyerOffer]。列名はデフォルト想定、実運用では [CsvFlyerColumnMapping] で上書き。
class CsvFlyerParser {
  CsvFlyerParser({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  static const _kDefaultProduct = 'product_name';
  static const _kDefaultPrice = 'price_yen';
  static const _kDefaultChain = 'chain_id';
  static const _kDefaultStore = 'store_id';
  static const _kDefaultValidFrom = 'valid_from';
  static const _kDefaultValidTo = 'valid_to';

  /// [csvText] はヘッダ行付き想定。区切りはカンマ、改行は \n。
  List<FlyerOffer> parse(
    String csvText, {
    CsvFlyerColumnMapping? mapping,
  }) {
    final lines = csvText.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) {
      return [];
    }

    final header = _splitCsvLine(lines.first);
    final m = mapping ?? const CsvFlyerColumnMapping();

    int col(String key, String fallback) {
      final name = _resolveHeaderName(key, fallback, m);
      final i = header.indexWhere((h) => h.trim().toLowerCase() == name.toLowerCase());
      return i >= 0 ? i : -1;
    }

    final iProduct = col('product', _kDefaultProduct);
    final iPrice = col('price', _kDefaultPrice);
    final iChain = col('chain', _kDefaultChain);
    final iStore = col('store', _kDefaultStore);
    final iFrom = col('validFrom', _kDefaultValidFrom);
    final iTo = col('validTo', _kDefaultValidTo);

    if (iProduct < 0) {
      return [];
    }

    final out = <FlyerOffer>[];
    for (var r = 1; r < lines.length; r++) {
      final cells = _splitCsvLine(lines[r]);
      String cell(int? idx) {
        if (idx == null || idx < 0 || idx >= cells.length) {
          return '';
        }
        return cells[idx].trim();
      }

      final name = cell(iProduct);
      if (name.isEmpty) {
        continue;
      }

      final priceRaw = cell(iPrice.isNegative ? null : iPrice);
      final price = int.tryParse(priceRaw.replaceAll(RegExp(r'[^0-9]'), ''));

      out.add(
        FlyerOffer(
          id: _uuid.v4(),
          productNameOrSku: name,
          chainId: _emptyToNull(cell(iChain.isNegative ? null : iChain)),
          storeId: _emptyToNull(cell(iStore.isNegative ? null : iStore)),
          priceYen: price,
          validFrom: _parseDate(cell(iFrom.isNegative ? null : iFrom)),
          validTo: _parseDate(cell(iTo.isNegative ? null : iTo)),
          ingestionSource: FlyerIngestionSource.csv,
        ),
      );
    }
    return out;
  }

  String _resolveHeaderName(String key, String fallback, CsvFlyerColumnMapping m) {
    switch (key) {
      case 'product':
        return m.productNameColumn ?? fallback;
      case 'price':
        return m.priceYenColumn ?? fallback;
      case 'chain':
        return m.chainIdColumn ?? fallback;
      case 'store':
        return m.storeIdColumn ?? fallback;
      case 'validFrom':
        return m.validFromColumn ?? fallback;
      case 'validTo':
        return m.validToColumn ?? fallback;
      default:
        return fallback;
    }
  }

  DateTime? _parseDate(String raw) {
    if (raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  String? _emptyToNull(String s) => s.isEmpty ? null : s;

  /// 簡易 CSV 行分割（ダブルクォート対応の最小版）
  List<String> _splitCsvLine(String line) {
    final out = <String>[];
    final buf = StringBuffer();
    var inQuote = false;
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        inQuote = !inQuote;
        continue;
      }
      if (!inQuote && c == ',') {
        out.add(buf.toString());
        buf.clear();
      } else {
        buf.write(c);
      }
    }
    out.add(buf.toString());
    return out;
  }
}

/// 企業ごとに列名が違う場合に指定
class CsvFlyerColumnMapping {
  const CsvFlyerColumnMapping({
    this.productNameColumn,
    this.priceYenColumn,
    this.chainIdColumn,
    this.storeIdColumn,
    this.validFromColumn,
    this.validToColumn,
  });

  final String? productNameColumn;
  final String? priceYenColumn;
  final String? chainIdColumn;
  final String? storeIdColumn;
  final String? validFromColumn;
  final String? validToColumn;
}
