/// Formats a volume in millilitres with thousands separators, e.g. `1,250 ml`.
String formatMl(int millilitres) => '${formatThousands(millilitres)} ml';

String formatThousands(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
