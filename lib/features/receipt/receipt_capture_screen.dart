import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ReceiptCaptureScreen extends StatelessWidget {
  const ReceiptCaptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('レシート登録')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long_outlined, size: 64),
              const SizedBox(height: 16),
              Text(
                'ギャラリーから既存のレシート画像を選ぶか、カメラで撮影できます（解析は OCR スタブ経由）。',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _pickAndGo(context, ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('ギャラリーから選ぶ'),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () => _pickAndGo(context, ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('カメラで撮影'),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => context.push('/receipt/processing'),
                child: const Text('画像なしで解析へ（従来のダミー）'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndGo(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: source, imageQuality: 85);
    if (!context.mounted) {
      return;
    }
    if (xfile == null) {
      return;
    }
    final bytes = await xfile.readAsBytes();
    if (!context.mounted) {
      return;
    }
    context.push('/receipt/processing', extra: Uint8List.fromList(bytes));
  }
}
