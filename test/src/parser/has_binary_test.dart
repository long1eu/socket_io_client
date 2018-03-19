import 'package:socket_io_client/src/parser/has_binary.dart';
import 'package:test/test.dart';
import 'package:utf/utf.dart';

void main() {
  test('byteArray', () {
    expect(HasBinary.hasBinary(<int>[0]), isTrue);
  });

  test('anArrayThatDoesNotContainByteArray', () {
    final List<dynamic> list = <dynamic>[1, 'cool', 2];
    expect(HasBinary.hasBinary(list), isFalse);
  });

  test('anArrayContainsByteArray', () {
    final List<dynamic> list = <dynamic>[1, null, 2];
    list[1] = encodeUtf8('asdfasdf');
    expect(HasBinary.hasBinary(list), isTrue);
  });

  test('anObjectThatDoesNotContainByteArray', () {
    final Map<String, dynamic> object = <String, dynamic>{'a': 'a', 'b': <dynamic>[], 'c': 1234};
    expect(HasBinary.hasBinary(object), isFalse);
  });

  test('anObjectThatContainsByteArray', () {
    final Map<String, dynamic> object = <String, dynamic>{'a': 'a', 'b': null, 'c': 1234};
    object['b'] = encodeUtf8('abc');
    expect(HasBinary.hasBinary(object), isTrue);
  });

  test('testNull', () {
    expect(HasBinary.hasBinary(null), isFalse);
  });

  test('aComplexObjectThatContainsNoBinary', () {
    final Map<String, dynamic> object = <String, dynamic>{};
    object['x'] = <dynamic>['a', 'b', 123];
    object['y'] = null;
    object['z'] = <String, dynamic>{'a': 'x', 'b': 'y', 'c': 3, 'd': null};
    object['w'] = <dynamic>[];

    expect(HasBinary.hasBinary(object), isFalse);
  });

  test('aComplexObjectThatContainsBinary', () {
    final Map<String, dynamic> object = <String, dynamic>{};
    object['x'] = <dynamic>['a', 'b', 123];
    object['y'] = null;
    object['z'] = <String, dynamic>{'a': 'x', 'b': 'y', 'c': 3, 'd': null};
    object['w'] = <dynamic>[];
    object['bin'] = encodeUtf8('aaa');

    expect(HasBinary.hasBinary(object), isTrue);
  });
}
