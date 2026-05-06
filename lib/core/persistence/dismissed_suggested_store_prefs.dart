import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const _kDismissedSuggestedStoreIds = 'dismissed_suggested_store_ids_v1';

/// 候補店「非表示」。端末ローカル（将来はアカウントと同期可）。
abstract final class DismissedSuggestedStorePrefs {
  static Future<Set<String>> readIds() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kDismissedSuggestedStoreIds);
    if (raw == null || raw.isEmpty) {
      return {};
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => e as String).toSet();
  }

  static Future<void> addId(String storeId) async {
    final p = await SharedPreferences.getInstance();
    final next = await readIds()..add(storeId);
    await p.setString(_kDismissedSuggestedStoreIds, jsonEncode(next.toList()));
  }
}
