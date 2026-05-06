import '../../../domain/entities/receipt_parse_result.dart';

/// OCR の商品名ゆらぎを補正する軽量ノーマライザ。
/// 優先度: 1) 明示置換 2) 辞書との近似一致
class ReceiptItemNormalizer {
  static const _canonicalNames = <String>[
    'ニンジン',
    'ダイコン',
    'ジャガイモ',
    'ピーマン',
    'タマネギ',
    '牛乳 1L',
    '卵 10個入',
    '食パン 6枚',
  ];

  static const _directWordMap = <String, String>{
    'ﾆﾝｼﾞﾝ': 'ニンジン',
    'ﾀﾞｲｺﾝ': 'ダイコン',
    'ﾀﾞｺﾝ': 'ダイコン',
    'ダコン': 'ダイコン',
    'ｼﾞｬｶﾞｲﾓ': 'ジャガイモ',
    'ｼﾞｬｶﾞ任': 'ジャガイモ',
    'E-ﾏﾝ': 'ピーマン',
    'E-マン': 'ピーマン',
    'ﾋﾟｰﾏﾝ': 'ピーマン',
    'ﾀﾏﾈｷﾞ': 'タマネギ',
  };

  ReceiptLineItem normalize(ReceiptLineItem item) {
    final raw = item.productName.trim();
    if (raw.isEmpty) {
      return item;
    }
    final direct = _directFix(raw);
    final fuzzy = direct == null ? _fuzzyCandidates(raw) : const [];
    final mapped = direct ?? (fuzzy.isNotEmpty ? fuzzy.first : raw);
    final changed = mapped != raw;
    final candidates = <String>{
      if (direct != null) direct,
      ...fuzzy,
    }.toList(growable: false);
    return ReceiptLineItem(
      productName: mapped,
      priceYen: item.priceYen,
      categoryHint: item.categoryHint ?? _inferCategoryHint(mapped),
      originalProductName: changed ? raw : null,
      normalizationNote: changed ? 'OCR補正: $raw → $mapped' : null,
      normalizationCandidates: changed ? candidates : const [],
    );
  }

  String? _directFix(String raw) {
    final direct = _directWordMap[raw];
    if (direct != null) {
      return direct;
    }
    // 典型誤読を優先補正
    if (raw.contains('ｼﾞｬｶﾞ') && (raw.contains('任') || raw.endsWith('ｲ'))) {
      return 'ジャガイモ';
    }
    if ((raw.startsWith('E-') || raw.startsWith('E')) &&
        (raw.contains('ﾏﾝ') || raw.contains('マン'))) {
      return 'ピーマン';
    }
    if (raw.contains('ダコ') && !raw.contains('ダイコ')) {
      return 'ダイコン';
    }
    return null;
  }

  List<String> _fuzzyCandidates(String raw) {
    final key = _normalizeForMatch(raw);
    if (key.isEmpty) {
      return const [];
    }
    final scored = <_CandidateScore>[];
    for (final cand in _canonicalNames) {
      final d = _levenshtein(key, _normalizeForMatch(cand));
      scored.add(_CandidateScore(name: cand, distance: d));
    }
    scored.sort((a, b) => a.distance.compareTo(b.distance));
    // 4-6文字程度の食材名を想定した緩め閾値
    return scored.where((e) => e.distance <= 2).take(3).map((e) => e.name).toList();
  }

  String _normalizeForMatch(String s) {
    var x = s;
    // このアプリで頻出する半角カナだけを最小対応
    const replacements = <String, String>{
      'ﾆ': 'ニ',
      'ﾝ': 'ン',
      'ｼﾞ': 'ジ',
      'ｬ': 'ャ',
      'ｶﾞ': 'ガ',
      'ｶ': 'カ',
      'ｲ': 'イ',
      'ﾀﾞ': 'ダ',
      'ﾀ': 'タ',
      'ｺ': 'コ',
      'ﾋﾟ': 'ピ',
      'ｰ': 'ー',
      'ﾏ': 'マ',
      'ﾈ': 'ネ',
      'ｷﾞ': 'ギ',
      'ｷ': 'キ',
      'E': 'ピ',
    };
    replacements.forEach((k, v) {
      x = x.replaceAll(k, v);
    });
    x = x
        .replaceAll(RegExp(r'[\s\-‐－_¥￥]'), '')
        .replaceAll(RegExp(r'[0-9０-９]+'), '')
        .toUpperCase();
    return x;
  }

  String? _inferCategoryHint(String name) {
    if (name.contains('ニンジン') ||
        name.contains('ダイコン') ||
        name.contains('ジャガイモ') ||
        name.contains('ピーマン') ||
        name.contains('タマネギ')) {
      return '野菜';
    }
    if (name.contains('牛乳')) {
      return '乳製品';
    }
    if (name.contains('卵')) {
      return '卵';
    }
    if (name.contains('パン')) {
      return 'パン';
    }
    return null;
  }

  int _levenshtein(String a, String b) {
    if (a == b) {
      return 0;
    }
    if (a.isEmpty) {
      return b.length;
    }
    if (b.isEmpty) {
      return a.length;
    }
    final prev = List<int>.generate(b.length + 1, (i) => i);
    final curr = List<int>.filled(b.length + 1, 0);
    for (var i = 1; i <= a.length; i++) {
      curr[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        curr[j] = _min3(
          curr[j - 1] + 1,
          prev[j] + 1,
          prev[j - 1] + cost,
        );
      }
      for (var j = 0; j <= b.length; j++) {
        prev[j] = curr[j];
      }
    }
    return prev[b.length];
  }

  int _min3(int a, int b, int c) {
    var m = a;
    if (b < m) {
      m = b;
    }
    if (c < m) {
      m = c;
    }
    return m;
  }
}

class _CandidateScore {
  const _CandidateScore({required this.name, required this.distance});
  final String name;
  final int distance;
}
