// lib/models/file_item.dart
// ---------------------------------------------------------------------------
// Data model representing a single file returned by the Spring Boot API.
// ---------------------------------------------------------------------------

class FileItem {
  final String name;
  final int sizeBytes;
  final DateTime lastModified;

  const FileItem({
    required this.name,
    required this.sizeBytes,
    required this.lastModified,
  });

  // ── Deserialize from JSON ──────────────────────────────────────────────────
  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      name: json['name'] as String? ?? 'unknown',
      // The API may return the size as int or String — handle both
      sizeBytes: _parseInt(json['size']),
      // The API may return an ISO-8601 string or epoch milliseconds
      lastModified: _parseDate(json['lastModified']),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  // ── Human-readable size (e.g. "2.4 MB") ──────────────────────────────────
  String get readableSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  // ── File extension (lowercase, without dot) ───────────────────────────────
  String get extension {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  @override
  String toString() => 'FileItem(name: $name, size: $readableSize)';
}