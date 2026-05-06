import 'package:flutter/material.dart';

import '../../../domain/shopping/shopping_transport.dart';
import '../../../domain/shopping/shopping_trip_estimate.dart';

/// 見積もり内容のカード（今日の買い物・登録済みルートで共通）
class ShoppingEstimateCard extends StatelessWidget {
  const ShoppingEstimateCard({super.key, required this.estimate});

  final ShoppingTripEstimate estimate;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              estimate.homeLocationNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(
              'チラシ商品の合計',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            Text(
              '¥${estimate.flyerSubtotalYen}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (estimate.catalogQtyUnits > 0) ...[
              const SizedBox(height: 8),
              Text(
                'カタログ: ${estimate.catalogItemCount} 品目・合計 ${estimate.catalogQtyUnits} 個（金額は未連携）',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (estimate.freeformLineCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                'メモ行: ${estimate.freeformLineCount} 行（金額に含みません）',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const Divider(height: 24),
            Text(
              '移動: ${estimate.transport.label}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Text(
              estimate.transportNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '+ ¥${estimate.transportYen}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(height: 24),
            Text(
              '合計（チラシ合計 + 移動費の案）',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            Text(
              '¥${estimate.grandTotalYen}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}
