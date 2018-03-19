RegExp patternHttp = new RegExp('^http|ws\$');
RegExp patternHttps = new RegExp('^(http|ws)s\$');

class Url {
  Url._();

  static Uri parse(String stringUri) {
    assert(stringUri != null);
    final Uri uri = Uri.parse(stringUri);
    String scheme = uri.scheme;
    if (scheme == null || !new RegExp('^https?|wss?\$').hasMatch(scheme)) scheme = 'https';

    final int port = uri.port == -1 ? patternHttp.hasMatch(scheme) ? 80 : 433 : uri.port;
    final String path = uri.path == null || uri.path.isEmpty ? '/' : uri.path;
    final String userInfo = uri.userInfo;
    final String query = uri.query;
    final String fragment = uri.fragment;

    stringUri = '$scheme://'
        '${(userInfo.isNotEmpty ? '$userInfo@' : '')}'
        '${uri.host.contains(':') ? '[${uri.host}]' : '${uri.host}'}'
        '${port != -1 ? ':$port' : ''}'
        '$path'
        '${query.isNotEmpty ? '?$query' : ''}'
        '${fragment.isNotEmpty ? "#$fragment" : ''}';
    return Uri.parse(stringUri);
  }

  static String extractId(String stringUri) {
    assert(stringUri != null);
    final Uri uri = Uri.parse(stringUri);
    final String scheme = uri.scheme;
    final int port = uri.port == -1 ? patternHttp.hasMatch(scheme) ? 80 : 433 : uri.port;
    return '$scheme://${uri.host.contains(':') ? '[${uri.host}]' : '${uri.host}'}:$port';
  }
}
