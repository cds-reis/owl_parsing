import 'dart:convert';
import 'dart:io';

import 'package:owl_parsing/owl_season_1_parser.dart';
import 'package:owl_parsing/utils.dart';

String parseSeason2StageToJson(String fileName) {
  return parseSeason1StageToJson(fileName);
}

typedef IndexToWeekParser = int Function(int index);

class OwlSeason2Parser {
  static void groupByWeeksStage1() {
    _groupByWeeksStage(
      stage: 1,
      parser: (index) => switch (index) {
        < 16 => 0,
        < 32 => 1,
        < 48 => 2,
        < 62 => 3,
        _ => 4,
      },
    );
  }

  static void groupByWeeksStage2() {
    _groupByWeeksStage(
      stage: 2,
      parser: (index) => switch (index) {
        < 16 => 0,
        < 32 => 1,
        < 48 => 2,
        < 56 => 3,
        _ => 4,
      },
    );
  }

  static void groupByWeeksStage3() {
    _groupByWeeksStage(
      stage: 3,
      parser: (index) => switch (index) {
        < 16 => 0,
        < 32 => 1,
        < 48 => 2,
        < 62 => 3,
        _ => 4,
      },
    );
  }

  static void groupByWeeksStage4() {
    _groupByWeeksStage(
      stage: 4,
      parser: (index) => switch (index) {
        < 16 => 0,
        < 32 => 1,
        < 48 => 2,
        < 62 => 3,
        _ => 4,
      },
    );
  }

  static void _groupByWeeksStage({
    required int stage,
    required IndexToWeekParser parser,
  }) {
    final fileName = 'phs_2019_stage_$stage';

    final inputFileName =
        groupedByRegularSeasonAndPlayoffsOutputFile(2019, fileName);

    final file = File(inputFileName).readAsStringSync();

    final fileJson = Map<String, dynamic>.from(jsonDecode(file));

    final regularSeasonMatches =
        List<Map<String, dynamic>>.from(fileJson[regularSeasonMatchesKey]!);

    final stagePlayoffsMatches =
        List<Map<String, dynamic>>.from(fileJson[stagePlayoffsMatchesKey]!);

    final jsonOutput = <Map<String, dynamic>>[
      {
        'name': 'Week 1',
        'matches': <Map<String, dynamic>>[],
      },
      {
        'name': 'Week 2',
        'matches': <Map<String, dynamic>>[],
      },
      {
        'name': 'Week 3',
        'matches': <Map<String, dynamic>>[],
      },
      {
        'name': 'Week 4',
        'matches': <Map<String, dynamic>>[],
      },
      {
        'name': 'Week 5',
        'matches': <Map<String, dynamic>>[],
      },
    ];

    for (int i = 0; i < regularSeasonMatches.length; i++) {
      final match = regularSeasonMatches[i];
      final weekMatches =
          jsonOutput[parser(i)]['matches'] as List<Map<String, dynamic>>;

      weekMatches.add(match);
    }

    jsonOutput.add(
      {
        'name': 'Stage Playoffs',
        'matches': stagePlayoffsMatches,
      },
    );

    final outputFile = File(groupedByWeekOutputFile(2019, fileName));

    outputFile.writeAsStringSync(jsonEncode(jsonOutput));
  }
}
