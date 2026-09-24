import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';

void main() {
  const androidTv = TvPinPairingRequest(
    expectedLength: 6,
    alphabet: TvPinAlphabet.hex,
  );

  group('Android TV hex pairing code validation', () {
    test('A4F29C is accepted', () {
      expect(androidTv.validate('A4F29C'), 'A4F29C');
    });

    test('a4f29c is normalized to A4F29C', () {
      expect(androidTv.validate('a4f29c'), 'A4F29C');
    });

    test('an all-digit code 123456 is accepted', () {
      expect(androidTv.validate('123456'), '123456');
    });

    test('other documented examples are accepted', () {
      expect(androidTv.validate('7B13E9'), '7B13E9');
      expect(androidTv.validate('00D8AF'), '00D8AF');
    });

    test('G12345 is rejected (G is not hex)', () {
      expect(androidTv.validate('G12345'), isNull);
    });

    test('special characters are rejected', () {
      for (final code in ['A4F-9C', 'A4F29!', '#4F29C', 'A4F.9C', 'Ä4F29C']) {
        expect(androidTv.validate(code), isNull, reason: code);
      }
    });

    test('fewer or more than 6 characters are rejected', () {
      expect(androidTv.validate(''), isNull);
      expect(androidTv.validate('A4F29'), isNull);
      expect(androidTv.validate('A4F29C1'), isNull);
    });

    test('whitespace from a pasted code is ignored', () {
      expect(androidTv.validate(' A4F 29C\n'), 'A4F29C');
    });
  });

  test('digit-only codes still reject letters', () {
    const digits = TvPinPairingRequest(expectedLength: 4);
    expect(digits.validate('1234'), '1234');
    expect(digits.validate('12AB'), isNull);
  });
}
