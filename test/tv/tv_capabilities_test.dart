import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';

void main() {
  group('TvCapabilities', () {
    test('none has every flag disabled', () {
      const caps = TvCapabilities.none;
      expect(caps.power, isFalse);
      expect(caps.volume, isFalse);
      expect(caps.dpad, isFalse);
      expect(caps.launchApps, isFalse);
    });

    test('copyWith overrides only the given fields', () {
      const caps = TvCapabilities.none;
      final updated = caps.copyWith(power: true, volume: true);

      expect(updated.power, isTrue);
      expect(updated.volume, isTrue);
      expect(updated.dpad, isFalse);
    });

    test('equality is value-based', () {
      const a = TvCapabilities(power: true, volume: true);
      const b = TvCapabilities(power: true, volume: true);
      const c = TvCapabilities(power: true);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });
}
