String outputFile(int year, String fileName) => 'output/$year/$fileName.json';
String groupedByRegularSeasonAndPlayoffsOutputFile(int year, String fileName) =>
    'output/$year/grouped/$fileName.json';
String groupedByWeekOutputFile(int year, String fileName) =>
    'output/$year/weeks/$fileName.json';

extension DateExt on DateTime {
  String get formatted =>
      '$month/$day/$year ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
