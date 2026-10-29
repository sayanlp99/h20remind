import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h20remind/data/firestore/water_entry_codec.dart';

void main() {
  group('DayKey', () {
    test('formats as dd-MM-yyyy', () {
      expect(DayKey.format(DateTime(2026, 3, 7)), '07-03-2026');
    });

    test('round-trips', () {
      final day = DateTime(2026, 12, 31);
      expect(DayKey.parse(DayKey.format(day)), day);
    });

    test('rejects malformed or impossible dates', () {
      expect(DayKey.parse('2026-03-07'), isNull);
      expect(DayKey.parse('31-02-2026'), isNull);
      expect(DayKey.parse(''), isNull);
    });
  });

  group('LegacyTime', () {
    test('formats like intl jm', () {
      expect(LegacyTime.format(DateTime(2026, 1, 1, 0, 5)), '12:05 AM');
      expect(LegacyTime.format(DateTime(2026, 1, 1, 12)), '12:00 PM');
      expect(LegacyTime.format(DateTime(2026, 1, 1, 15, 45)), '3:45 PM');
    });

    test('parses, including CLDR narrow no-break spaces', () {
      expect(
        LegacyTime.parse('3:45 PM'),
        const Duration(hours: 15, minutes: 45),
      );
      expect(LegacyTime.parse('12:05 AM'), const Duration(minutes: 5));
      expect(LegacyTime.parse('12:00 pm'), const Duration(hours: 12));
      expect(LegacyTime.parse('13:00 PM'), isNull);
      expect(LegacyTime.parse('noon'), isNull);
    });
  });

  group('WaterEntryCodec', () {
    test('decodes a v1 document using date + time', () {
      final entry = WaterEntryCodec.decode('a', {
        'drank': '250',
        'date': '28-09-2026',
        'time': '3:45 PM',
      });
      expect(entry, isNotNull);
      expect(entry!.amountMl, 250);
      expect(entry.day, DateTime(2026, 9, 28));
      expect(entry.loggedAt, DateTime(2026, 9, 28, 15, 45));
    });

    test('prefers createdAt when present', () {
      final at = DateTime(2026, 9, 28, 8, 30, 12);
      final entry = WaterEntryCodec.decode('a', {
        'drank': 300,
        'date': '28-09-2026',
        'time': 'garbage',
        'createdAt': Timestamp.fromDate(at),
      });
      expect(entry!.loggedAt, at);
    });

    test('ignores the goal document and malformed entries', () {
      expect(WaterEntryCodec.decode('goal', {'goal': '3000'}), isNull);
      expect(
        WaterEntryCodec.decode('x', {'drank': 'lots', 'date': '28-09-2026'}),
        isNull,
      );
      expect(
        WaterEntryCodec.decode('x', {'drank': '-5', 'date': '28-09-2026'}),
        isNull,
      );
    });

    test('encode stays readable by v1 and round-trips', () {
      final original = WaterEntryCodec.decode('a', {
        'drank': '500',
        'date': '01-10-2026',
        'createdAt': Timestamp.fromDate(DateTime(2026, 10, 1, 9, 15)),
      })!;
      final encoded = WaterEntryCodec.encode(original);
      expect(encoded['drank'], '500');
      expect(encoded['date'], '01-10-2026');
      expect(encoded['time'], '9:15 AM');
      expect(WaterEntryCodec.decode('a', encoded), original);
    });

    test('parseMillilitres accepts numbers and numeric strings', () {
      expect(WaterEntryCodec.parseMillilitres('250.0'), 250);
      expect(WaterEntryCodec.parseMillilitres(' 3000 '), 3000);
      expect(WaterEntryCodec.parseMillilitres(1.6), 2);
      expect(WaterEntryCodec.parseMillilitres(null), isNull);
      expect(WaterEntryCodec.parseMillilitres(0), isNull);
    });
  });
}
