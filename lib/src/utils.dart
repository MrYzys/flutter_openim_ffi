import 'dart:convert';
import 'dart:math';

class Utils {
  static List<T> toList<T>(
    dynamic value,
    T Function(Map<String, dynamic>) factory,
  ) {
    if (value == null) return <T>[];
    final list =
        value is String ? (jsonDecode(value) as List) : (value as List);
    return list
        .map((e) => factory(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static T toObj<T>(dynamic value, T Function(Map<String, dynamic>) factory) {
    if (value == null) {
      throw ArgumentError('value is null');
    }
    if (value is String) {
      return factory(Map<String, dynamic>.from(jsonDecode(value) as Map));
    }
    if (value is Map<String, dynamic>) {
      return factory(value);
    }
    return factory(Map<String, dynamic>.from(value as Map));
  }

  static List<dynamic> toListMap(dynamic value) {
    if (value == null) return const [];
    if (value is String) return (jsonDecode(value) as List).toList();
    return List<dynamic>.from(value as List);
  }

  static dynamic formatJson(String value) => jsonDecode(value);

  static String checkOperationID(String? obj) =>
      obj ??
      'op_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1 << 20)}';

  static Map<String, dynamic> cleanMap(Map<String, dynamic> map) {
    final cleaned = <String, dynamic>{};
    map.forEach((key, value) {
      if (value == null) return;
      if (value is String && value.isEmpty) return;
      if (value is Map<String, dynamic>) {
        final nested = cleanMap(value);
        if (nested.isEmpty) return;
        cleaned[key] = nested;
      } else {
        cleaned[key] = value;
      }
    });
    return cleaned;
  }

  static String toJson(Map<String, dynamic> map) => jsonEncode(cleanMap(map));

  static String? toJsonString(dynamic value) {
    if (value == null) return null;
    try {
      return jsonEncode(value);
    } catch (_) {
      return jsonEncode(value.toString());
    }
  }

  static String? stringValue(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static int toInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static double toDouble(dynamic value, [double defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static bool toBool(dynamic value, [bool defaultValue = false]) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return defaultValue;
  }
}
