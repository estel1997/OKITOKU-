import 'dart:convert';

import 'package:crypto/crypto.dart';

/// 同一ユーザー・レシート・イベント種別に対する冪等キー（Supabase `rewardable_events.idempotency_key` と一致させる）。
String rewardableEventIdempotencyKey({
  required String userId,
  required String receiptId,
  required String eventType,
}) {
  final payload = '$userId|$receiptId|$eventType';
  final bytes = utf8.encode(payload);
  return sha256.convert(bytes).toString();
}

/// 台帳行の二重記帳防止用（イベント由来の付与と突合）。
String ledgerIdempotencyKeyFromEvent({
  required String rewardableEventId,
  required String reasonCode,
}) {
  final payload = '$rewardableEventId|$reasonCode';
  final bytes = utf8.encode(payload);
  return sha256.convert(bytes).toString();
}
