import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/ingestion/receipt_ingestion_facade.dart';
import '../../domain/entities/receipt_parse_result.dart';
import 'providers/receipt_ingestion_providers.dart';

class ReceiptProcessingScreen extends ConsumerStatefulWidget {
  const ReceiptProcessingScreen({super.key, this.imageBytes});

  /// ギャラリー等から渡す。null のときは従来どおりダミー解析のみ。
  final Uint8List? imageBytes;

  @override
  ConsumerState<ReceiptProcessingScreen> createState() =>
      _ReceiptProcessingScreenState();
}

class _ReceiptProcessingScreenState extends ConsumerState<ReceiptProcessingScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    try {
      final ReceiptParseResult result;
      if (widget.imageBytes == null) {
        result = await const DummyReceiptIngestionFacade().fromImageBytes(
          Uint8List(0),
        );
      } else {
        final ocr = ref.read(ocrEngineProvider);
        final facade = CompositeReceiptIngestionFacade(ocr: ocr);
        result = await facade.fromImageBytes(widget.imageBytes!);
      }
      if (!mounted) {
        return;
      }
      context.go('/receipt/review', extra: result);
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('解析中')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _error == null
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 24),
                    Text('OCR を実行しています…'),
                  ],
                )
              : Text(_error!, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
