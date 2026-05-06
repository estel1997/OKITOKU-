import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_env.dart';
import '../../core/notifications/push_token_registration_service.dart';
import '../../core/persistence/app_settings_prefs.dart';
import '../products/providers/product_providers.dart';
import 'implementation_roadmap_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _showSuggestedStores = true;
  bool _loaded = false;
  int? _retentionDays;
  bool _retentionLoading = false;
  bool _pushEnabled = false;
  bool _pushToggleLoading = false;
  bool _pushRegistering = false;
  String? _pushStatus;
  bool _catalogSyncing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await AppSettingsPrefs.getShowSuggestedStores();
    final push = await AppSettingsPrefs.getPushEnabled();
    int? retention;
    if (AppEnv.hasSupabase) {
      retention = await _fetchRetentionDays();
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _showSuggestedStores = v;
      _pushEnabled = push;
      _retentionDays = retention;
      _loaded = true;
    });
  }

  Future<int?> _fetchRetentionDays() async {
    try {
      final res = await Supabase.instance.client.rpc('get_price_watch_retention_days');
      if (res is int) {
        return res;
      }
      if (res is num) {
        return res.toInt();
      }
      if (res is String) {
        return int.tryParse(res);
      }
    } catch (_) {
      // Keep null and show fallback text in UI.
    }
    return null;
  }

  Future<void> _setShowSuggested(bool value) async {
    await AppSettingsPrefs.setShowSuggestedStores(value);
    if (!mounted) {
      return;
    }
    setState(() => _showSuggestedStores = value);
    ref.invalidate(suggestedStoresProvider);
  }

  /// ダッシュボード URL を誤って渡すと PostgREST が HTML を返す
  static String _connectionFailureHint(Object e, String configuredUrl) {
    final msg = e.toString();
    final looksLikeHtml =
        msg.contains('<!DOCTYPE') || msg.contains('<html') || msg.contains('<title');
    final urlLooksWrong = configuredUrl.contains('supabase.com/dashboard') ||
        !configuredUrl.contains('.supabase.co');

    if (looksLikeHtml || urlLooksWrong) {
      return 'API が HTML を返しています。SUPABASE_URL は次の形式である必要があります。\n'
          'https://（project-ref）.supabase.co\n'
          'ダッシュボードの https://supabase.com/dashboard/project/... は使えません。\n'
          'Supabase → Project Settings → API の「Project URL」をコピーしてください。';
    }
    if (msg.contains('PGRST205') ||
        msg.contains("Could not find the table") ||
        msg.contains('schema cache')) {
      return 'テーブルがまだありません（新規プロジェクトのときよくある状態です）。\n\n'
          'リポジトリの supabase/migrations/ を、日付の古い順に '
          'Supabase の SQL Editor で実行するか、CLI で supabase db push してください。\n'
          '例: 20260403120000 → 20260409120000 → 20260409140000\n\n'
          '詳細は supabase/README.md です。\n\n'
          '技術メッセージ: ${msg.length > 200 ? '${msg.substring(0, 200)}…' : msg}';
    }
    return '接続テスト失敗（マイグレーション未適用・RLS・キー誤りの可能性）:\n'
        '${msg.length > 280 ? '${msg.substring(0, 280)}…' : msg}';
  }

  Future<void> _testSupabase(BuildContext context) async {
    if (!AppEnv.hasSupabase) {
      return;
    }
    try {
      await Supabase.instance.client.from('stores').select('id').limit(1);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('接続成功: stores にアクセスできました（URL・キー・RLS が妥当）'),
        ),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      final hint = _connectionFailureHint(e, AppEnv.supabaseUrl);
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('接続テスト失敗'),
          content: SingleChildScrollView(child: Text(hint)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('閉じる'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _editRetentionDays(BuildContext context) async {
    final current = _retentionDays ?? 90;
    final controller = TextEditingController(text: current.toString());
    final value = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('履歴の保持日数'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '日数（1〜180）',
            hintText: '例: 90',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop(int.tryParse(controller.text.trim()));
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (value == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    await _saveRetentionDays(context, value);
  }

  Future<void> _saveRetentionDays(BuildContext context, int days) async {
    if (_retentionLoading) {
      return;
    }
    setState(() => _retentionLoading = true);
    try {
      final res = await Supabase.instance.client.rpc(
        'set_price_watch_retention_days',
        params: {'p_days': days},
      );
      final applied = res is int
          ? res
          : (res is num ? res.toInt() : int.tryParse(res.toString()) ?? 90);
      if (!context.mounted) {
        return;
      }
      setState(() => _retentionDays = applied);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保持日数を $applied 日に更新しました')),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新に失敗しました: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _retentionLoading = false);
      }
    }
  }

  Future<void> _registerPushToken(BuildContext context) async {
    if (_pushRegistering) {
      return;
    }
    setState(() => _pushRegistering = true);
    try {
      final token = await PushTokenRegistrationService.registerCurrentDeviceToken();
      if (!context.mounted) {
        return;
      }
      final suffix = token.length > 10 ? token.substring(token.length - 10) : token;
      setState(() => _pushStatus = '登録済み（末尾: $suffix）');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Push トークンを登録しました')),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      final msg = e.toString();
      setState(() => _pushStatus = '登録失敗');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Push トークン登録に失敗: $msg')),
      );
    } finally {
      if (mounted) {
        setState(() => _pushRegistering = false);
      }
    }
  }

  bool get _pushSupportedPlatform {
    if (kIsWeb) {
      return false;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => true,
      TargetPlatform.iOS => true,
      _ => false,
    };
  }

  Future<void> _togglePushEnabled(BuildContext context, bool next) async {
    if (_pushToggleLoading) {
      return;
    }
    setState(() {
      _pushToggleLoading = true;
      _pushEnabled = next;
    });
    try {
      final token =
          await PushTokenRegistrationService.setEnabled(enabled: next);
      await AppSettingsPrefs.setPushEnabled(next);
      if (!context.mounted) {
        return;
      }
      final suffix = token.length > 10 ? token.substring(token.length - 10) : token;
      setState(() => _pushStatus = next ? '有効（末尾: $suffix）' : '無効（末尾: $suffix）');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(next ? 'プッシュ通知を有効にしました' : 'プッシュ通知を無効にしました')),
      );
    } catch (e) {
      // 失敗したら元に戻す
      await AppSettingsPrefs.setPushEnabled(!next);
      if (!context.mounted) {
        return;
      }
      setState(() => _pushEnabled = !next);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新に失敗しました: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _pushToggleLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String formatDt(DateTime t) {
      final local = t.toLocal();
      return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
          '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }

    return Scaffold(
      primary: false,
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          const _SettingsSectionHeader(title: '接続・データ'),
          ListTile(
            title: const Text('データソース'),
            subtitle: Text(
              AppEnv.hasSupabase
                  ? 'Supabase（dart-define 済み）\n'
                      '接続 URL: ${AppEnv.supabaseUrl}\n'
                      '※ URL は必ず … .supabase.co で終わる Project URL を使ってください。'
                  : 'ローカルダミー（dart-define 未指定のビルド）\n'
                    '※ IDE の「実行」だけだと dart-define が付かないことがあります。'
                    'PowerShell で flutter run に --dart-define を付けるか、'
                    '.vscode/launch.json の「Flutter + Supabase」を使い、'
                    '事前に環境変数 SUPABASE_URL / SUPABASE_ANON_KEY を設定してください。',
            ),
            isThreeLine: true,
          ),
          if (AppEnv.hasSupabase) ...[
            ListTile(
              leading: const Icon(Icons.wifi_tethering_outlined),
              title: const Text('Supabase 接続を確認'),
              subtitle: const Text('stores を1件だけ試し読み（通信・認証・RLS）'),
              onTap: () => _testSupabase(context),
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('商品カタログを同期'),
              subtitle: ref.watch(catalogLastSyncedAtProvider).when(
                    data: (t) => Text(
                      t == null ? '未同期（タップで同期）' : '最終同期: ${formatDt(t)}',
                    ),
                    loading: () => const Text('読み込み中…'),
                    error: (_, __) => const Text('状態を読み込めません'),
                  ),
              trailing: _catalogSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _catalogSyncing
                  ? null
                  : () async {
                      setState(() => _catalogSyncing = true);
                      try {
                        final n = await ref.read(catalogSyncNowProvider.future);
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('同期しました（$n 件）')),
                        );
                      } catch (e) {
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('同期に失敗しました: $e')),
                        );
                      } finally {
                        if (mounted) {
                          setState(() => _catalogSyncing = false);
                        }
                      }
                    },
            ),
            ListTile(
              leading: const Icon(Icons.history_outlined),
              title: const Text('価格履歴の保持日数'),
              subtitle: Text(
                _retentionDays == null
                    ? '読み込み失敗（タップで再設定可）'
                    : '現在: $_retentionDays 日（最大180日）',
              ),
              trailing: _retentionLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _retentionLoading ? null : () => _editRetentionDays(context),
            ),
          ],
          const Divider(height: 1),
          const _SettingsSectionHeader(title: '通知'),
          if (!AppEnv.hasSupabase)
            const SwitchListTile(
              title: Text('プッシュ通知'),
              subtitle: Text('Supabase 未設定のため無効です'),
              value: false,
              onChanged: null,
            )
          else if (!_pushSupportedPlatform)
            const SwitchListTile(
              title: Text('プッシュ通知'),
              subtitle: Text('このプラットフォームでは未対応です（Android / iOS 対応）'),
              value: false,
              onChanged: null,
            )
          else
            SwitchListTile(
              title: const Text('プッシュ通知'),
              subtitle: Text(
                _pushStatus ?? 'オンにすると、この端末のトークンを登録して通知対象にします。',
              ),
              value: _pushEnabled,
              onChanged: _pushToggleLoading
                  ? null
                  : (v) => _togglePushEnabled(context, v),
            ),
          if (AppEnv.hasSupabase && _pushSupportedPlatform)
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text('Push トークンを再登録'),
              subtitle: Text(
                _pushStatus == null
                    ? '通知ON/OFFに関わらず、現在のトークンを再送信します'
                    : _pushStatus!,
              ),
              trailing: _pushRegistering
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _pushRegistering ? null : () => _registerPushToken(context),
            ),
          const Divider(height: 1),
          const _SettingsSectionHeader(title: '表示'),
          SwitchListTile(
            title: const Text('周辺候補店の表示'),
            subtitle: const Text('オフにすると「行動圏を広げる」の候補店一覧を非表示にします'),
            value: _loaded ? _showSuggestedStores : true,
            onChanged: !_loaded
                ? null
                : (v) {
                    _setShowSuggested(v);
                  },
          ),
          const Divider(height: 1),
          const _SettingsSectionHeader(title: '開発・ドキュメント'),
          ListTile(
            leading: const Icon(Icons.timeline_outlined),
            title: const Text('実装の優先順位'),
            subtitle: const Text('未実装の整理とフェーズ別の着手順（アプリ内表示）'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const ImplementationRoadmapScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  const _SettingsSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
