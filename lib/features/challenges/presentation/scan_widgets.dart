import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/l10n.dart';
import '../domain/challenge_type.dart';

const _barcodeFormats = [
  BarcodeFormat.ean13,
  BarcodeFormat.ean8,
  BarcodeFormat.upcA,
  BarcodeFormat.upcE,
  BarcodeFormat.code128,
  BarcodeFormat.code39,
  BarcodeFormat.code93,
  BarcodeFormat.codabar,
  BarcodeFormat.itf14,
];

/// Camera view that reports the first code of the right kind.
class CodeScanner extends ConsumerStatefulWidget {
  const CodeScanner({
    super.key,
    required this.type,
    required this.onCode,
    this.height = 300,
  });

  final ChallengeType type; // qr or barcode
  final void Function(String value) onCode;
  final double height;

  @override
  ConsumerState<CodeScanner> createState() => _CodeScannerState();
}

class _CodeScannerState extends ConsumerState<CodeScanner> {
  late final MobileScannerController _controller = MobileScannerController(
    formats: widget.type == ChallengeType.qr
        ? const [BarcodeFormat.qrCode]
        : _barcodeFormats,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(l10nProvider);
    final size = widget.height.isFinite ? widget.height : 320.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                for (final b in capture.barcodes) {
                  final v = b.rawValue;
                  if (v != null && v.isNotEmpty) {
                    widget.onCode(v);
                    return;
                  }
                }
              },
              errorBuilder: (_, error) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(t('cameraError'), textAlign: TextAlign.center),
                ),
              ),
            ),
            Center(
              child: Container(
                width: size * 0.6,
                height: size * 0.6,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white70, width: 3),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ring-time challenge: scan the code that was registered in the editor.
class ScanChallenge extends ConsumerStatefulWidget {
  const ScanChallenge({
    super.key,
    required this.type,
    required this.expected,
    required this.onSolved,
  });

  final ChallengeType type;
  final String expected;
  final VoidCallback onSolved;

  @override
  ConsumerState<ScanChallenge> createState() => _ScanChallengeState();
}

class _ScanChallengeState extends ConsumerState<ScanChallenge> {
  bool _wrong = false;
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(l10nProvider);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          t(widget.type == ChallengeType.qr ? 'scanQrNow' : 'scanBarcodeNow'),
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        CodeScanner(
          type: widget.type,
          onCode: (v) {
            if (_done) return;
            if (v == widget.expected) {
              _done = true;
              widget.onSolved();
            } else {
              setState(() => _wrong = true);
            }
          },
        ),
        const SizedBox(height: 12),
        AnimatedOpacity(
          opacity: _wrong ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Text(t('wrongCode'), style: TextStyle(color: scheme.error)),
        ),
      ],
    );
  }
}
