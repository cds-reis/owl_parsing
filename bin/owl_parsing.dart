import 'dart:convert';
import 'dart:io';

import 'package:owl_parsing/details_service.dart';
import 'package:owl_parsing/owl_season_1_parser.dart';
import 'package:owl_parsing/season_grouping_service.dart';
import 'package:owl_parsing/stat_remover.dart';
import 'package:owl_parsing/teams/team_color.dart';
import 'package:owl_parsing/teams/team_parser.dart';
import 'package:owl_parsing/teams/teams.dart';
import 'package:owl_parsing/utils.dart';

const year = 2018;
const fileName = 'phs_${year}_stage_1';

void main() {
  for (var (name, _) in teams) {
    SeasonGroupingService.groupSeasons(teamName: name);
  }
}

void removeDetailsFromTeams({
  required int year,
}) {
  for (final (team, _) in teams) {
    final formatted = team.toLowerCase().split(' ').join('_');
    final file = File('output/$year/teams/$formatted.json');

    if (!file.existsSync()) continue;

    final json = jsonDecode(file.readAsStringSync());
    for (final stage in json['regular_season_stages']) {
      for (final week in stage['weeks']) {
        for (final match in week['matches']) {
          StatRemover.removeStats(match);
        }
      }

      for (final match in (stage['stage_playoffs'] ?? {})['matches'] ?? []) {
        StatRemover.removeStats(match);
      }
    }

    File('output/$year/teams_no_stats/$formatted.json').writeAsStringSync(
      jsonEncode(json),
    );
  }
}

void removeDetailsFromSeason3() {
  void remove({required String inputPath, required String outputPath}) {
    final file = File(inputPath);
    final json = Map<String, List<dynamic>>.from(
      jsonDecode(file.readAsStringSync()),
    );

    for (final matches in json.values) {
      for (final match in matches) {
        StatRemover.removeStats(match);
      }
    }

    File(outputPath).writeAsStringSync(jsonEncode(json));
  }

  remove(
    inputPath: 'output/2020/stages/phs_2020.json',
    outputPath: 'output/2020/no_stats/phs_2020.json',
  );
}

void parse2018TeamRegularSeason() {
  const teamName = 'Shanghai Dragons';
  const teamColor = TeamColor(
    primaryColor: (r: 171, g: 137, b: 0),
    // secondaryColor: (r: 0, g: 0, b: 0),
  );
  final formattedTeamName = teamName.toLowerCase().split(' ').join('_');

  final teamJson = TeamParser.parseTeamRegularSeason(
    teamName: teamName,
    teamColor: teamColor,
    files: List.generate(
      4,
      (i) => File('output/2018/stats/phs_2018_stage_${i + 1}.json'),
    ),
  );

  File('output/2018/teams/$formattedTeamName.json').writeAsStringSync(
    jsonEncode(teamJson.asMap()),
  );
}

void parse2019TeamRegularSeason({
  required String teamName,
  required TeamColor teamColor,
}) {
  final formattedTeamName = teamName.toLowerCase().split(' ').join('_');

  final teamJson = TeamParser.parseTeamRegularSeason(
    teamName: teamName,
    teamColor: teamColor,
    files: List.generate(
      4,
      (i) => File('output/2019/stats/phs_2019_stage_${i + 1}.json'),
    ),
  );

  File('output/2019/teams/$formattedTeamName.json').writeAsStringSync(
    jsonEncode(teamJson.asMap()),
  );
}

void detailsService({required int year, required int stage}) {
  final inputPath = 'output/$year/weeks/phs_${year}_stage_$stage.json';
  final outputPath = 'output/$year/stats/phs_${year}_stage_$stage.json';
  // DetailsService.formatCsvToJson();
  final service = DetailsService.load();
  final stageJson = List<Map<String, dynamic>>.from(loadJson(inputPath));

  for (final week in stageJson) {
    for (final match in week['matches']) {
      service.detailMatch(match);
    }
  }

  final jsonOutput = jsonEncode(stageJson);

  File(outputPath).writeAsStringSync(jsonOutput);
}

dynamic loadJson(String path) {
  return jsonDecode(File(path).readAsStringSync());
}

void groupWeeks() {
  final jsonString = groupByWeeks(year, fileName);

  File(groupedByWeekOutputFile(year, fileName)).writeAsStringSync(jsonString);
}

void groupMatches() {
  final jsonString =
      groupSeason1StageByRegularSeasonAndPlayoffs(year, fileName);

  File(groupedByRegularSeasonAndPlayoffsOutputFile(year, fileName))
      .writeAsStringSync(jsonString);
}

void parseCsvToJson() {
  final jsonString = parseSeason1StageToJson(fileName);

  File(outputFile(year, fileName)).writeAsStringSync(jsonString);

  print(validateJson(fileName));
}

bool validateJson(String fileName) {
  final file = File(outputFile(year, fileName)).readAsStringSync();
  try {
    final _ = jsonDecode(file);
    return true;
  } catch (e) {
    return false;
  }
}
