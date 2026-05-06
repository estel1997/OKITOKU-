import 'package:uuid/uuid.dart';

import '../../../domain/entities/flyer_offer.dart';

/// メール本文・件名から特売行を抽出する **スタブ**。
///
/// 実運用では: 専用テンプレート、正規表現、または LLM で構造化。
/// Edge Function で inbound メール → このパーサへ raw を渡す想定。
class EmailFlyerParser {
  EmailFlyerParser({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  /// [rawBody] に「商品名 198円」「商品 ¥198」「￥198」のような行があれば拾う（緩いルール）。
  List<FlyerOffer> parseBody(
    String rawBody, {
    String? subject,
    String? sourceRef,
    FlyerIngestionSource source = FlyerIngestionSource.email,
  }) {
    final lines = rawBody.split(RegExp(r'\r?\n'));
    final out = <FlyerOffer>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.length < 2) {
        continue;
      }
      final parsed = _parsePriceLine(trimmed, subject);
      if (parsed == null) {
        continue;
      }
      final (name, price) = parsed;
      out.add(
        FlyerOffer(
          id: _uuid.v4(),
          productNameOrSku: name,
          priceYen: price,
          ingestionSource: source,
          sourceRef: sourceRef,
        ),
      );
    }
    return out;
  }

  /// 1 行から (商品名, 価格) を返す。該当しなければ null。
  (String, int)? _parsePriceLine(String trimmed, String? subject) {
    final yenSuffix = RegExp(r'([0-9]{2,4})\s*円');
    final yenPrefixFull = RegExp(r'[¥￥]\s*([0-9]{2,4})(?!\d)');

    RegExpMatch? m = yenSuffix.firstMatch(trimmed);
    String matched = '';
    int? price;

    if (m != null) {
      matched = m.group(0)!;
      price = int.tryParse(m.group(1)!);
    } else {
      m = yenPrefixFull.firstMatch(trimmed);
      if (m != null) {
        matched = m.group(0)!;
        price = int.tryParse(m.group(1)!);
      }
    }

    if (price == null) {
      return null;
    }

    var name = trimmed.replaceAll(matched, '').trim();
    if (name.isEmpty && subject != null) {
      name = subject;
    }
    if (name.isEmpty) {
      return null;
    }
    return (name, price);
  }
}
