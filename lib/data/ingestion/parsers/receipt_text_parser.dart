import '../../../domain/entities/receipt_parse_result.dart';

/// OCR テキスト → [ReceiptParseResult]（ルールベースの最小版。本番は学習モデルやテンプレ可）
class ReceiptTextParser {
  ReceiptParseResult parse(String ocrText) {
    final trimmed = ocrText.trim();
    if (trimmed.isEmpty) {
      return const ReceiptParseResult(lines: [], ocrRawPreview: '');
    }

    String? store;
    DateTime? date;
    final lines = <ReceiptLineItem>[];

    final storeRe = RegExp(r'^(.+店|.+センター|.+マート)');
    final dateRe = RegExp(r'(\d{4})[年/-](\d{1,2})[月/-](\d{1,2})');
    final isoDateRe = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$');
    /// 例: `牛乳 1L 198円`
    final lineReYenSuffix = RegExp(r'^(.+?)\s+(\d{2,4})\s*円');
    /// 例: `ニンジン ¥100` / `ダイコン ¥ 95`（チラシ・価格表で多い）
    final lineReYenPrefix = RegExp(r'^(.+?)\s*[¥￥]\s*(\d{1,4})\s*$');
    /// 例: `ﾀﾏﾈｷﾞ : 128` / `玉葱：198円`（POS 風）
    final lineReColonPrice = RegExp(r'^(.+?)\s*[:：]\s*(\d{2,4})\s*円?\s*$');

    final contentBuffer = <String>[];

    for (final raw in trimmed.split(RegExp(r'\r?\n'))) {
      final line = raw.trim();
      if (line.isEmpty) {
        continue;
      }
      final iso = isoDateRe.firstMatch(line);
      if (iso != null) {
        date = DateTime(
          int.parse(iso.group(1)!),
          int.parse(iso.group(2)!),
          int.parse(iso.group(3)!),
        );
        continue;
      }
      final ds = dateRe.firstMatch(line);
      if (ds != null) {
        date = DateTime(
          int.parse(ds.group(1)!),
          int.parse(ds.group(2)!),
          int.parse(ds.group(3)!),
        );
        continue;
      }
      if (store == null) {
        final sm = storeRe.firstMatch(line);
        if (sm != null && !line.contains('円')) {
          store = sm.group(0);
          continue;
        }
      }
      final lmSuffix = lineReYenSuffix.firstMatch(line);
      if (lmSuffix != null) {
        final name = lmSuffix.group(1)!.trim();
        final price = int.tryParse(lmSuffix.group(2)!);
        lines.add(ReceiptLineItem(productName: name, priceYen: price));
        continue;
      }
      final lmColon = lineReColonPrice.firstMatch(line);
      if (lmColon != null) {
        final name = lmColon.group(1)!.trim();
        final price = int.tryParse(lmColon.group(2)!);
        lines.add(ReceiptLineItem(productName: name, priceYen: price));
        continue;
      }
      final lmPrefix = lineReYenPrefix.firstMatch(line);
      if (lmPrefix != null) {
        final name = lmPrefix.group(1)!.trim();
        final price = int.tryParse(lmPrefix.group(2)!);
        lines.add(ReceiptLineItem(productName: name, priceYen: price));
        continue;
      }

      contentBuffer.add(line);
    }

    lines.addAll(_pairNamePriceBlocks(contentBuffer));

    final preview =
        trimmed.length > 280 ? '${trimmed.substring(0, 280)}…' : trimmed;

    return ReceiptParseResult(
      inferredStoreName: store,
      purchaseDate: date,
      lines: lines,
      ocrRawPreview: preview,
    );
  }

  /// 商品名と金額が別行（縦並び・交互）のときにペア化する。
  static List<ReceiptLineItem> _pairNamePriceBlocks(List<String> content) {
    final result = <ReceiptLineItem>[];
    var i = 0;
    while (i < content.length) {
      while (i < content.length && _isPriceOnlyLine(content[i])) {
        i++;
      }
      if (i >= content.length) {
        break;
      }

      final nameBlock = <String>[];
      while (i < content.length && !_isPriceOnlyLine(content[i])) {
        nameBlock.add(content[i]);
        i++;
      }
      final priceBlock = <int>[];
      while (i < content.length && _isPriceOnlyLine(content[i])) {
        final p = _parsePriceYen(content[i]);
        if (p != null) {
          priceBlock.add(p);
        }
        i++;
      }

      for (var k = 0; k < nameBlock.length; k++) {
        result.add(
          ReceiptLineItem(
            productName: nameBlock[k],
            priceYen: k < priceBlock.length ? priceBlock[k] : null,
          ),
        );
      }
    }
    return result;
  }

  /// 金額だけの行（`100` / `¥95` / `￥ 400` など）
  static bool _isPriceOnlyLine(String raw) {
    final line = _normalizeAsciiDigits(raw.trim());
    final m = RegExp(r'^[¥￥]?\s*(\d{1,4})\s*$').firstMatch(line);
    if (m == null) {
      return false;
    }
    final v = int.tryParse(m.group(1)!);
    if (v == null) {
      return false;
    }
    // 単独行の西暦っぽい4桁は除外（日付行がここに混ざるのを防ぐ）
    if (v >= 1900 && v <= 2100 && m.group(1)!.length == 4) {
      return false;
    }
    return true;
  }

  static int? _parsePriceYen(String raw) {
    final line = _normalizeAsciiDigits(raw.trim());
    final m = RegExp(r'^[¥￥]?\s*(\d{1,4})\s*$').firstMatch(line);
    return m != null ? int.tryParse(m.group(1)!) : null;
  }

  /// OCR が全角数字だけ返す場合の最低限の正規化
  static String _normalizeAsciiDigits(String s) {
    const from = '０１２３４５６７８９';
    const to = '0123456789';
    var out = s;
    for (var i = 0; i < from.length; i++) {
      out = out.replaceAll(from[i], to[i]);
    }
    return out;
  }
}
