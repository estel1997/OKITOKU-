import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy/dummy_data.dart';
import '../../domain/entities/receipt_parse_result.dart';

class ReceiptReviewScreen extends StatefulWidget {
  const ReceiptReviewScreen({super.key, this.parseResult});

  final ReceiptParseResult? parseResult;

  @override
  State<ReceiptReviewScreen> createState() => _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends State<ReceiptReviewScreen> {
  late List<ReceiptLineItem> _editableLines;

  @override
  void initState() {
    super.initState();
    _editableLines = [...?widget.parseResult?.lines];
  }

  void _applyCandidate(int index, String candidate) {
    final cur = _editableLines[index];
    final updated = ReceiptLineItem(
      productName: candidate,
      priceYen: cur.priceYen,
      categoryHint: cur.categoryHint,
      originalProductName: cur.originalProductName ?? cur.productName,
      normalizationNote: '候補確定: ${cur.productName} → $candidate',
      normalizationCandidates: const [],
    );
    setState(() {
      _editableLines[index] = updated;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('「${cur.productName}」を「$candidate」に更新しました')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.parseResult;
    final storeName = r?.inferredStoreName ?? kDummyStores.first.name;
    final dateLabel = r?.purchaseDate != null
        ? '${r!.purchaseDate!.year}-${r.purchaseDate!.month.toString().padLeft(2, '0')}-${r.purchaseDate!.day.toString().padLeft(2, '0')}'
        : '2026-04-02（ダミー）';

    final useParsed = r != null && _editableLines.isNotEmpty;
    final hasResultButNoLines =
        r != null && _editableLines.isEmpty && !r.usedDummyFallback;

    return Scaffold(
      appBar: AppBar(title: const Text('内容を確認')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('店舗（推定）', style: Theme.of(context).textTheme.labelMedium),
                  Text(
                    storeName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('購入日: $dateLabel'),
                  if (r?.usedDummyFallback == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '※ ダミーまたはプレースホルダー解析です',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (r?.ocrRawPreview != null && r!.ocrRawPreview!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              title: const Text('OCR 抜粋'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    r.ocrRawPreview!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text('明細', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (useParsed)
            ..._editableLines.asMap().entries.map(
              (entry) {
                final index = entry.key;
                final item = entry.value;
                return Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.productName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Text(item.priceYen != null ? '¥${item.priceYen}' : '—'),
                        ],
                      ),
                      if (item.categoryHint != null || item.normalizationNote != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            [
                              if (item.categoryHint != null) item.categoryHint!,
                              if (item.normalizationNote != null) item.normalizationNote!,
                            ].join('  /  '),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      if (item.normalizationCandidates.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final c in item.normalizationCandidates.take(3))
                                ActionChip(
                                  label: Text(c),
                                  onPressed: () => _applyCandidate(index, c),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
              },
            )
          else if (hasResultButNoLines)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'OCR テキストはありますが、商品名と金額の行として認識できませんでした。'
                  '「OCR 抜粋」を確認するか、明るさ・ピントを調整して撮り直してください。',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          else
            ...kDummyProducts.map(
              (p) => Card(
                child: ListTile(
                  title: Text(p.name),
                  subtitle: Text(p.category.jaLabel),
                  trailing: const Text('¥198'),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: () {
              context.go('/home');
            },
            child: const Text('保存してホームへ'),
          ),
        ),
      ),
    );
  }
}
