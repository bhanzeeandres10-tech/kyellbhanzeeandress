import 'package:flutter_test/flutter_test.dart';
import 'package:qrly/models/qr_record.dart';

void main() {
  test('QR history survives JSON serialization', () {
    final original = QrRecord(
      id: '1',
      title: 'Example',
      value: 'https://example.com',
      type: 'Website',
      kind: QrRecordKind.created,
      createdAt: DateTime.utc(2026, 9, 15),
    );

    final restored = QrRecord.decodeAll(QrRecord.encodeAll([original])).single;

    expect(restored.id, original.id);
    expect(restored.value, original.value);
    expect(restored.kind, QrRecordKind.created);
    expect(restored.createdAt, original.createdAt);
  });
}

