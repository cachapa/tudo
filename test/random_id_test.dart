import 'package:flutter_test/flutter_test.dart';
import 'package:tudo_client/util/random_id.dart';

void testLength(int length) {
  final id = generateRandomId(length);
  expect(id.length, length);
}

void main() {
  test('Generate id', () {
    final id = generateRandomId();
    expect(id.length, 128);
  });

  test('Length = -1', () {
    expect(() => generateRandomId(-1), throwsA(isA<Exception>()));
  });

  test('Length = 0', () {
    expect(() => generateRandomId(0), throwsA(isA<Exception>()));
  });

  test('Length = 1', () {
    expect(() => generateRandomId(1), throwsA(isA<Exception>()));
  });

  test('Length = 2', () {
    testLength(2);
  });

  test('Length = 3', () {
    testLength(3);
  });

  test('Length = 10', () {
    testLength(10);
  });

  test('Length = 32', () {
    testLength(32);
  });

  test('Length = 1024', () {
    testLength(1024);
  });

  test('Replace illegal characters', () {
    final id = generateRandomId(1000);
    print(id);
    expect(id.contains('='), isFalse);
    expect(id.contains('/'), isFalse);
    expect(id.contains('+'), isFalse);
  });
}
