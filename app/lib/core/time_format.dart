/// `mm:ss`; minutes keep growing past 59 instead of rolling over to hours.
String formatElapsed(int ms) {
  final totalSeconds = ms ~/ 1000;
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
