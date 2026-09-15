import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/qr_record.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key, required this.state});
  final AppState state;

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final manualController = TextEditingController();
  String? result;
  bool cameraActive = true;

  @override
  void dispose() {
    controller.dispose();
    manualController.dispose();
    super.dispose();
  }

  Future<void> _capture(String value) async {
    final clean = value.trim();
    if (clean.isEmpty || clean == result) return;
    setState(() => result = clean);
    await widget.state.addRecord(QrRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: _resultTitle(clean),
      value: clean,
      type: _resultType(clean),
      kind: QrRecordKind.scanned,
      createdAt: DateTime.now(),
    ));
  }

  String _resultType(String value) {
    final lower = value.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) return 'Website';
    if (lower.startsWith('wifi:')) return 'Wi-Fi';
    if (lower.startsWith('mailto:')) return 'Email';
    if (lower.startsWith('tel:')) return 'Phone';
    return 'Text';
  }

  String _resultTitle(String value) {
    if (_resultType(value) == 'Website') {
      return Uri.tryParse(value)?.host.replaceFirst('www.', '') ?? 'Website';
    }
    return value.length > 42 ? '${value.substring(0, 42)}â€¦' : value;
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 20 : 36),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const PageHeading('Scan a QR code',
                  'Allow camera access, then place a code inside the frame.'),
              const SizedBox(height: 26),
              LayoutBuilder(builder: (context, constraints) {
                final stacked = constraints.maxWidth < 760;
                final camera = _cameraCard();
                final detail = _detailCard();
                return stacked
                    ? Column(children: [camera, const SizedBox(height: 18), detail])
                    : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(flex: 6, child: camera),
                        const SizedBox(width: 22),
                        Expanded(flex: 4, child: detail),
                      ]);
              }),
            ]),
          ),
        ),
      );

  Widget _cameraCard() => SectionCard(
        child: Column(children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(fit: StackFit.expand, children: [
                MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    final value = capture.barcodes.isEmpty
                        ? null
                        : capture.barcodes.first.rawValue;
                    if (value != null) _capture(value);
                  },
                  errorBuilder: (context, error) => const _CameraError(),
                ),
                if (!cameraActive)
                  Container(
                    color: const Color(0xFF181721),
                    child: const Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.videocam_off_outlined, color: Colors.white70, size: 42),
                        SizedBox(height: 10),
                        Text('Camera paused', style: TextStyle(color: Colors.white)),
                      ]),
                    ),
                  ),
                IgnorePointer(
                  child: Center(
                    child: Container(
                      width: 210,
                      height: 210,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 16, spreadRadius: 3),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            OutlinedButton.icon(
              onPressed: () async {
                if (cameraActive) {
                  await controller.stop();
                } else {
                  await controller.start();
                }
                if (mounted) setState(() => cameraActive = !cameraActive);
              },
              icon: Icon(cameraActive ? Icons.pause_rounded : Icons.play_arrow_rounded),
              label: Text(cameraActive ? 'Pause camera' : 'Resume camera'),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: 'Switch camera',
              onPressed: controller.switchCamera,
              icon: const Icon(Icons.cameraswitch_outlined),
            ),
          ]),
        ]),
      );

  Widget _detailCard() => Column(children: [
        SectionCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(result == null ? Icons.radar_rounded : Icons.check_circle_rounded,
                  color: result == null ? AppColors.violet : AppColors.mint),
              const SizedBox(width: 10),
              Text(result == null ? 'Waiting for a code' : 'Code captured',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(result ?? 'The scanned content will appear here.',
                  maxLines: 6, overflow: TextOverflow.ellipsis),
            ),
            if (result != null) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: result!));
                    if (mounted) showAppSnackBar(context, 'Result copied.');
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copy result'),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => result = null),
                  child: const Text('Scan another'),
                ),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('No camera?',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Paste QR content manually and keep it in the same history.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 14),
            TextField(
              controller: manualController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Paste text or a URLâ€¦'),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _capture(manualController.text),
                child: const Text('Add manually'),
              ),
            ),
          ]),
        ),
      ]);
}

class _CameraError extends StatelessWidget {
  const _CameraError();

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: const Color(0xFF181721),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.no_photography_outlined, color: Colors.white, size: 44),
              const SizedBox(height: 12),
              const Text('Camera unavailable',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('Check your browser camera permission and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70)),
            ]),
          ),
        ),
      );
}

