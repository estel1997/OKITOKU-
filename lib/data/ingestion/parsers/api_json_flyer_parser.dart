import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../domain/entities/flyer_offer.dart';

/// JSON 文字列または [Map] から [FlyerOffer] を組み立てる。
///
/// 想定スキーマ例:
/// `{ "offers": [ { "product_name": "...", "price_yen": 198, "chain_id": "san_a" } ] }`
/// またはトップレベルが配列。
class ApiJsonFlyerParser {
  ApiJsonFlyerParser({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  List<FlyerOffer> parseString(String jsonText) {
    try {
      final decoded = jsonDecode(jsonText);
      return parseJson(decoded);
    } on FormatException {
      return [];
    }
  }

  List<FlyerOffer> parseJson(Object? decoded) {
    if (decoded is List) {
      return decoded.map(_one).whereType<FlyerOffer>().toList();
    }
    if (decoded is Map<String, dynamic>) {
      final list = decoded['offers'] ?? decoded['items'] ?? decoded['data'];
      if (list is List) {
        return list.map(_one).whereType<FlyerOffer>().toList();
      }
    }
    return [];
  }

  FlyerOffer? _one(dynamic raw) {
    if (raw is! Map) {
      return null;
    }
    final m = Map<String, dynamic>.from(raw);
    final name = (m['product_name'] ?? m['name'] ?? m['product'])?.toString().trim();
    if (name == null || name.isEmpty) {
      return null;
    }
    final priceRaw = m['price_yen'] ?? m['price'];
    final price = priceRaw is int
        ? priceRaw
        : int.tryParse(priceRaw?.toString() ?? '');

    return FlyerOffer(
      id: _uuid.v4(),
      productNameOrSku: name,
      chainId: m['chain_id']?.toString(),
      storeId: m['store_id']?.toString(),
      priceYen: price,
      validFrom: _parseDate(m['valid_from'] ?? m['validFrom']),
      validTo: _parseDate(m['valid_to'] ?? m['validTo']),
      ingestionSource: FlyerIngestionSource.apiJson,
    );
  }

  DateTime? _parseDate(Object? v) {
    if (v == null) {
      return null;
    }
    return DateTime.tryParse(v.toString());
  }
}
