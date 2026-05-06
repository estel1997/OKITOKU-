import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/okinawa/okinawa_municipalities.dart';

/// 手動で選択した行動圏（市区町村名の集合）。
class SelectedMunicipalitiesNotifier extends AsyncNotifier<Set<String>> {
  static const _key = 'selected_okinawa_municipalities_v1';

  @override
  Future<Set<String>> build() async {
    final known = kAllOkinawaMunicipalityNames.toSet();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return {};
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    final fromDisk = decoded.map((e) => e as String).toSet();
    return fromDisk.intersection(known);
  }

  Future<void> toggle(String municipalityName) async {
    if (!kAllOkinawaMunicipalityNames.contains(municipalityName)) {
      return;
    }
    final current = await future;
    final next = Set<String>.from(current);
    if (next.contains(municipalityName)) {
      next.remove(municipalityName);
    } else {
      next.add(municipalityName);
    }
    state = AsyncData(next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(next.toList()..sort()));
  }

  Future<void> clearAll() async {
    state = AsyncData(<String>{});
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final selectedMunicipalitiesProvider =
    AsyncNotifierProvider<SelectedMunicipalitiesNotifier, Set<String>>(
  SelectedMunicipalitiesNotifier.new,
);
