import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/qr_record.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

enum QrContentType { website, text, wifi, email, phone }

extension on QrContentType {
  String get label => switch (this) {
        QrContentType.website => 'Website',
        QrContentType.text => 'Text',
        QrContentType.wifi => 'Wi-Fi',
        QrContentType.email => 'Email',
        QrContentType.phone => 'Phone',
      };
  IconData get icon => switch (this) {
        QrContentType.website => Icons.language_rounded,
        QrContentType.text => Icons.notes_rounded,
        QrContentType.wifi => Icons.wifi_rounded,
        QrContentType.email => Icons.mail_outline_rounded,
        QrContentType.phone => Icons.phone_outlined,
      };
}

class CreatePage extends StatefulWidget {
  const CreatePage({super.key, required this.state});
  final AppState state;

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  QrContentType type = QrContentType.website;
  final primary = TextEditingController(text: 'https://example.com');
  final secondary = TextEditingController();
  final tertiary = TextEditingController();
  bool hiddenNetwork = false;
  Color qrColor = AppColors.ink;

  @override
  void initState() {
    super.initState();
    primary.addListener(_refresh);
    secondary.addListener(_refresh);
    tertiary.addListener(_refresh);
  }

  @override
  void dispose() {
    primary.dispose();
    secondary.dispose();
    tertiary.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _setType(QrContentType value) {
    setState(() {
      type = value;
      primary.text = value == QrContentType.website ? 'https://' : '';
      secondary.clear();
      tertiary.clear();
    });
  }

  String get payload {
    final value = primary.text.trim();
    return switch (type) {
      QrContentType.website || QrContentType.text => value,
      QrContentType.phone => value.isEmpty ? '' : 'tel:$value',
      QrContentType.email => value.isEmpty
          ? ''
          : 'mailto:$value?subject=${Uri.encodeComponent(secondary.text)}&body=${Uri.encodeComponent(tertiary.text)}',
      QrContentType.wifi => value.isEmpty
          ? ''
          : 'WIFI:T:${tertiary.text};S:${_escape(value)};P:${_escape(secondary.text)};H:$hiddenNetwork;;',
    };
  }

  String _escape(String value) => value.replaceAllMapped(
        RegExp(r'[\\;,:]'),
        (match) => '\\${match.group(0)}',
      );

  Future<void> _save() async {
    if (payload.isEmpty) {
      showAppSnackBar(context, 'Add some content first.');
      return;
    }
    await widget.state.addRecord(QrRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: _recordTitle,
      value: payload,
      type: type.label,
      kind: QrRecordKind.created,
      createdAt: DateTime.now(),
    ));
    if (mounted) showAppSnackBar(context, 'Saved to your history.');
  }

  String get _recordTitle => primary.text.trim().isEmpty
      ? '${type.label} QR code'
      : primary.text.trim();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 20 : 36),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const PageHeading('Create a QR code',
                  'Choose a format, add your details, and preview it instantly.'),
              const SizedBox(height: 26),
              LayoutBuilder(builder: (context, constraints) {
                final stacked = constraints.maxWidth < 800;
                final editor = _buildEditor();
                final preview = _buildPreview();
                return stacked
                    ? Column(children: [editor, const SizedBox(height: 18), preview])
                    : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(flex: 6, child: editor),
                        const SizedBox(width: 22),
                        Expanded(flex: 4, child: preview),
                      ]);
              }),
            ]),
          ),
        ),
      );

  Widget _buildEditor() => SectionCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('What should it contain?',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: QrContentType.values
                .map((item) => ChoiceChip(
                      selected: type == item,
                      onSelected: (_) => _setType(item),
                      avatar: Icon(item.icon, size: 18),
                      label: Text(item.label),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
          ..._fieldsForType(),
          const SizedBox(height: 22),
          Text('QR color',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: [AppColors.ink, AppColors.violet, AppColors.coral, AppColors.mint]
                .map((color) => InkWell(
                      onTap: () => setState(() => qrColor = color),
                      borderRadius: BorderRadius.circular(99),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: qrColor == color
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: qrColor == color
                            ? const Icon(Icons.check, size: 18, color: Colors.white)
                            : null,
                      ),
                    ))
                .toList(),
          ),
        ]),
      );

  List<Widget> _fieldsForType() {
    Widget field(TextEditingController controller, String label,
            {String? hint, int lines = 1, TextInputType? keyboard}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: TextField(
            controller: controller,
            maxLines: lines,
            keyboardType: keyboard,
            decoration: InputDecoration(labelText: label, hintText: hint),
          ),
        );
    return switch (type) {
      QrContentType.website => [
          field(primary, 'Website URL', hint: 'https://yourwebsite.com', keyboard: TextInputType.url)
        ],
      QrContentType.text => [
          field(primary, 'Your text', hint: 'Write somethingâ€¦', lines: 5)
        ],
      QrContentType.phone => [
          field(primary, 'Phone number', hint: '+1 555 0100', keyboard: TextInputType.phone)
        ],
      QrContentType.email => [
          field(primary, 'Email address', hint: 'hello@example.com', keyboard: TextInputType.emailAddress),
          field(secondary, 'Subject', hint: 'Hello!'),
          field(tertiary, 'Message', hint: 'Write a pre-filled messageâ€¦', lines: 3),
        ],
      QrContentType.wifi => [
          field(primary, 'Network name', hint: 'Wi-Fi name'),
          field(secondary, 'Password', hint: 'Network password'),
          DropdownButtonFormField<String>(
            initialValue: tertiary.text.isEmpty ? 'WPA' : tertiary.text,
            decoration: const InputDecoration(labelText: 'Security'),
            items: const [
              DropdownMenuItem(value: 'WPA', child: Text('WPA / WPA2')),
              DropdownMenuItem(value: 'WEP', child: Text('WEP')),
              DropdownMenuItem(value: 'nopass', child: Text('No password')),
            ],
            onChanged: (value) => setState(() => tertiary.text = value ?? 'WPA'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Hidden network'),
            value: hiddenNetwork,
            onChanged: (value) => setState(() => hiddenNetwork = value),
          ),
        ],
    };
  }

  Widget _buildPreview() => SectionCard(
        child: Column(children: [
          Row(children: [
            Text('Live preview',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.mint.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Text('Ready',
                  style: TextStyle(
                      color: AppColors.mint, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: payload.isEmpty
                ? const SizedBox(
                    width: 220,
                    height: 220,
                    child: Center(child: Text('Add content to preview')),
                  )
                : QrImageView(
                    data: payload,
                    size: 220,
                    backgroundColor: Colors.white,
                    eyeStyle: QrEyeStyle(color: qrColor, eyeShape: QrEyeShape.square),
                    dataModuleStyle:
                        QrDataModuleStyle(color: qrColor, dataModuleShape: QrDataModuleShape.square),
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  ),
          ),
          const SizedBox(height: 18),
          Text(type.label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(_recordTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.bookmark_add_outlined),
              label: const Text('Save QR code'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: payload.isEmpty
                  ? null
                  : () async {
                      await Clipboard.setData(ClipboardData(text: payload));
                      if (mounted) showAppSnackBar(context, 'Content copied.');
                    },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy content'),
            ),
          ),
        ]),
      );
}

