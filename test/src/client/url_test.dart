import 'package:socket_io_client/src/client/url.dart';
import 'package:test/test.dart';

void main() {
  test('parse', () {
    expect(Url.parse('http://username:password@host:8080/directory/file?query#ref').toString(),
        'http://username:password@host:8080/directory/file?query#ref');
  });

  test('parseRelativePath', () {
    final Uri url = Url.parse('https://woot.com/test');
    expect(url.scheme, 'https');
    expect(url.host, 'woot.com');
    expect(url.path, '/test');
  });

  test('parseNoProtocol', () {
    final Uri url = Url.parse('//localhost:3000');
    expect(url.scheme, 'https');
    expect(url.host, 'localhost');
    expect(url.port, 3000);
  });

  test('parseNamespace', () {
    expect(Url.parse('http://woot.com/woot').path, '/woot');
    expect(Url.parse('http://google.com').path, '/');
    expect(Url.parse('http://google.com/').path, '/');
  });

  test('parseDefaultPort', () {
    expect(Url.parse('http://google.com/').port, 80);
    expect(Url.parse('https://google.com/').port, 443);
  });

  test('extractId', () {
    final String id1 = Url.extractId('http://google.com:80/');
    final String id2 = Url.extractId('http://google.com/');
    final String id3 = Url.extractId('https://google.com/');

    expect(id1, id2);
    expect(id1 == id3, false);
    expect(id2 == id3, false);
  });

  test('ipv6', () {
    const String url = 'http://[::1]';
    final Uri uri = Url.parse(url);

    expect(uri.scheme, 'http');
    expect(uri.host, '::1');
    expect(Url.extractId(url), 'http://[::1]:80');
  });
}
