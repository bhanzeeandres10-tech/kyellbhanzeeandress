import 'dart:convert';

enum QrRecordKind { created, scanned }

class QrRecord {
  const QrRecord({
    required this.id,
    required this.title,
    required this.value,
    required this.type,
    required this.kind,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String value;
  final String type;
  final QrRecordKind kind;
  final DateTime createdAt;

  Map<String, Object> toJson() => {
        'id': id,
        'title': title,
        'value': value,
        'type': type,
        'kind': kind.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory QrRecord.fromJson(Map<String, dynamic> json) => QrRecord(
        id: json['id'] as String,
        title: json['title'] as String,
        value: json['value'] as String,
        type: json['type'] as String,
        kind: QrRecordKind.values.byName(json['kind'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  static String encodeAll(List<QrRecord> records) =>
      jsonEncode(records.map((record) => record.toJson()).toList());

  static List<QrRecord> decodeAll(String source) {
    final items = jsonDecode(source) as List<dynamic>;
    return items
        .map((item) => QrRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

