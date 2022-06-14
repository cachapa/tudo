import 'dart:convert';
import 'dart:math';

// Lazy instantiation
final _random = Random.secure();

/// Generates a (pseudo) random token by creating a byte array and encoding it
/// as a base64 string of the requested [length].
String generateToken([int length = 128]) {
  if (length < 2) throw Exception('Length needs to be at least 2');

  // Calculate how many bytes we need to end up with a Base64 string of [length]
  final byteLength = (length * 3 / 4).floor();

  // Generate pseudo-random byte array
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
