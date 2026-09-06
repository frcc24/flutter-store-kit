import 'dart:io';

import 'package:image/image.dart' as img;

/// Writes the placeholder launcher icon: a sudoku grid on the theme
/// background. Deterministic, so re-running never changes the file.
/// Run from app/: `dart run tool/make_icon.dart`
void main() {
  const size = 1024;
  const margin = 176;
  const cell = (size - 2 * margin) ~/ 9;
  final background = img.ColorRgb8(0x0B, 0x1A, 0x3D);
  final line = img.ColorRgb8(0x18, 0xE4, 0xFF);

  final icon = img.Image(width: size, height: size);
  img.fill(icon, color: background);
  for (var i = 0; i <= 9; i++) {
    final half = i % 3 == 0 ? 10 : 3;
    final position = margin + i * cell;
    img.fillRect(
      icon,
      x1: position - half,
      y1: margin,
      x2: position + half,
      y2: margin + 9 * cell,
      color: line,
    );
    img.fillRect(
      icon,
      x1: margin,
      y1: position - half,
      x2: margin + 9 * cell,
      y2: position + half,
      color: line,
    );
  }

  File('assets/icon/icon.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(img.encodePng(icon));
  stdout.writeln('wrote assets/icon/icon.png (${size}x$size)');
}
