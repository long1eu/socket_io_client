class HasBinary {
  static bool hasBinary(Object obj) {
    if (obj == null) return false;
    if (obj is List && isBinaryList(obj)) return true;

    if (obj is List<dynamic>) {
      for (int i = 0; i < obj.length; i++) if (hasBinary(obj[i])) return true;
    } else if (obj is Map<String, dynamic>) {
      for (String key in obj.keys) {
        final dynamic value = obj[key];
        if (hasBinary(value)) return true;
      }
    }

    return false;
  }

  static bool isBinaryList(List<dynamic> list) =>
      list.fold(null, (dynamic prev, dynamic item) => prev == null ? item is int : prev && item is int) ?? false;
}
