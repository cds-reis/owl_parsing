import 'dart:convert';
import 'dart:io';

class OwlSeason3StageParser {
  final Season3StagesFile file;

  const OwlSeason3StageParser._(this.file);

  factory OwlSeason3StageParser.loadSingle({
    String filePath = 'output/2020/no_stats/phs_2020.json',
  }) {
    final singleFile = SingleFile(_parseJson(filePath));

    return OwlSeason3StageParser._(singleFile);
  }

  factory OwlSeason3StageParser.loadTwo({
    String firstPath = 'output/2020/no_stats/phs_2020_1.json',
    String secondPath = 'output/2020/no_stats/phs_2020_2.json',
  }) {
    final twoFiles = TwoFiles(
      firstJson: _parseJson(firstPath),
      secondJson: _parseJson(secondPath),
    );

    return OwlSeason3StageParser._(twoFiles);
  }

  void groupWeeksInRegularSeason() {
    const regularSeasonKey = '2020: Regular Season';

    int matchIndexToWeek(int index) => switch (index) {
          < 0 => throw UnimplementedError(
              'index $index foi passado por algum motivo',
            ),
          < 8 => 1,
          < 12 => 2,
          < 18 => 3,
          < 25 => 4,
          < 31 => 5,
          < 41 => 8,
          < 51 => 9,
          < 61 => 10,
          < 70 => 11,
          < 80 => 12,
          < 90 => 13,
          < 102 => 14,
          < 114 => 15,
          < 122 => 19,
          < 135 => 20,
          < 148 => 21,
          < 160 => 24,
          < 174 => 25,
          < 185 => 26,
          < 198 => 28,
          < 210 => 29,
          _ => throw UnimplementedError(
              'index $index foi passado por algum motivo',
            )
        };

    Map<String, dynamic> groupWeeks(
      List<Map<String, dynamic>> regularSeasonMatches,
    ) {
      final output = <String, List<Map<String, dynamic>>>{};
      for (var i = 0; i < regularSeasonMatches.length; i++) {
        final match = regularSeasonMatches[i];
        final weekIndex = matchIndexToWeek(i);
        final weekKey = 'Week $weekIndex';
        output.putIfAbsent(weekKey, () => []);
        output[weekKey]!.add(match);
      }

      return output;
    }

    void groupAndSave(
      Map<String, List<Map<String, dynamic>>> json,
      String outputFile,
    ) {
      final regularSeasonMatches = json[regularSeasonKey]!;
      final weeks = groupWeeks(regularSeasonMatches);
      final copiedJson = Map<String, dynamic>.from(json);
      copiedJson[regularSeasonKey] = weeks;
      File(outputFile).writeAsStringSync(jsonEncode(copiedJson));
    }

    switch (file) {
      case SingleFile(:final json):
        groupAndSave(json, 'output/2020/weeks/phs_2020.json');
      case TwoFiles(:final firstJson, :final secondJson):
        groupAndSave(firstJson, 'output/2020/weeks/phs_2020_1.json');
        groupAndSave(secondJson, 'output/2020/weeks/phs_2020_2.json');
    }
  }

  static Map<String, List<Map<String, dynamic>>> _parseJson(String path) {
    final json = Map<String, dynamic>.from(
      jsonDecode(File(path).readAsStringSync()),
    );

    return json.map(
      (key, value) => MapEntry(key, List<Map<String, dynamic>>.from(value)),
    );
  }
}

sealed class Season3StagesFile {}

class SingleFile extends Season3StagesFile {
  final Map<String, List<Map<String, dynamic>>> json;

  SingleFile(this.json);
}

class TwoFiles extends Season3StagesFile {
  final Map<String, List<Map<String, dynamic>>> firstJson;
  final Map<String, List<Map<String, dynamic>>> secondJson;

  TwoFiles({required this.firstJson, required this.secondJson});
}
