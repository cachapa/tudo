import 'dart:convert';
import 'dart:math';

final _random = Random.secure();

String generateRandomId([int length = 128]) {
  if (length < 2) throw Exception('Length needs to be at least 2');

  // Calculate how many bytes we need to end up with a Base64 string of [length]
  final byteLength = (length * 3 / 4).floor();

  // Generate random bytes
  var values = List<int>.generate(byteLength, (_) => _random.nextInt(256));

  // Replace '+' and '/' to make the string URL-friendly
  // Trim '=' padding to match [length]
  return base64Encode(values).replaceAllMapped(
      RegExp(r'[+/=]'),
      (m) => m[0] == '+'
          ? '.'
          : m[0] == '/'
              ? '_'
              : '');
}
