import 'package:flutter_test/flutter_test.dart';
import 'package:poketibia_platform_frontend/services/sanitize.dart';

void main() {
  group('Sanitize', () {
    test('accepts http/https urls', () {
      expect(Sanitize.isSafeUrl('http://example.com/img.png'), true);
      expect(Sanitize.isSafeUrl('https://example.com/img.png'), true);
    });
    test('rejects javascript/data urls', () {
      expect(Sanitize.isSafeUrl('javascript:alert(1)'), false);
      expect(Sanitize.isSafeUrl('data:text/html;base64,abcd'), false);
    });
    test('sanitizeImageUrl returns empty for unsafe', () {
      expect(Sanitize.sanitizeImageUrl('javascript:alert(1)'), '');
      expect(Sanitize.sanitizeImageUrl(''), '');
    });
    test('sanitizeImageUrl keeps safe', () {
      final u = 'https://example.com/a.png';
      expect(Sanitize.sanitizeImageUrl(u), u);
    });
  });
}
