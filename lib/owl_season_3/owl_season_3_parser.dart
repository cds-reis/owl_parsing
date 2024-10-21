import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:owl_parsing/details_service.dart';

class OwlSeason3Parser {
  final Season3File files;

  const OwlSeason3Parser._(this.files);

  factory OwlSeason3Parser.loadSingle({
    String filePath = 'output/2020/matches/phs_2020.json',
  }) {
    return OwlSeason3Parser._(
      SingleFile(
        List<Map<String, dynamic>>.from(
          jsonDecode(File(filePath).readAsStringSync()),
        ),
      ),
    );
  }

  factory OwlSeason3Parser.loadTwo({
    String firstPath = 'output/2020/matches/phs_2020_1.json',
    String secondPath = 'output/2020/matches/phs_2020_2.json',
  }) {
    return OwlSeason3Parser._(
      TwoFiles(
        firstMatches: List<Map<String, dynamic>>.from(
          jsonDecode(File(firstPath).readAsStringSync()),
        ),
        secondMatches: List<Map<String, dynamic>>.from(
          jsonDecode(File(secondPath).readAsStringSync()),
        ),
      ),
    );
  }

  void groupByStage() {
    void group(List<Map<String, dynamic>> matches, String outputPath) {
      String stageKey(Map<String, dynamic> match) => match['stage'];

      final groupedMatches = matches.groupListsBy(stageKey);

      File(outputPath).writeAsStringSync(jsonEncode(groupedMatches));
    }

    switch (files) {
      case SingleFile(:final matches):
        group(matches, 'output/2020/stages/phs_2020.json');
      case TwoFiles(:final firstMatches, :final secondMatches):
        group(firstMatches, 'output/2020/stages/phs_2020_1.json');
        group(secondMatches, 'output/2020/stages/phs_2020_2.json');
    }
  }

  void detailMatches(DetailsService detailsSerivce) {
    void detail(List<Map<String, dynamic>> matches, String outputPath) {
      final seasonMatches = matches.whereNot(
        (match) => match['stage'].contains('All-Stars'),
      );
      for (final match in seasonMatches) {
        detailsSerivce.detailMatch(match);
        detailsSerivce.detailStage(match);
      }

      File(outputPath).writeAsStringSync(jsonEncode(matches));
    }

    switch (files) {
      case SingleFile(:final matches):
        detail(matches, 'output/2020/detailed_matches/phs_2020.json');
      case TwoFiles(:final firstMatches, :final secondMatches):
        detail(firstMatches, 'output/2020/detailed_matches/phs_2020_1.json');
        detail(secondMatches, 'output/2020/detailed_matches/phs_2020_2.json');
    }
  }

  static void parseCsvsToJson({
    String firstCsvPath = 'csvs/phs_2020_1.csv',
    String secondCsvPath = 'csvs/phs_2020_2.csv',
    String combinedOutputPath = 'output/2020/matches/phs_2020.json',
    String firstOutputPath = 'output/2020/matches/phs_2020_1.json',
    String secondOutputPath = 'output/2020/matches/phs_2020_2.json',
  }) {
    final part1 = _parseJson(firstCsvPath);
    final part2 = _parseJson(secondCsvPath);

    final output = [...part1, ...part2];

    File(firstOutputPath).writeAsStringSync(jsonEncode(part1));
    File(secondOutputPath).writeAsStringSync(jsonEncode(part2));
    File(combinedOutputPath).writeAsStringSync(jsonEncode(output));
  }
}

sealed class Season3File {}

class SingleFile extends Season3File {
  final List<Map<String, dynamic>> matches;

  SingleFile(this.matches);
}

class TwoFiles extends Season3File {
  final List<Map<String, dynamic>> firstMatches;
  final List<Map<String, dynamic>> secondMatches;

  TwoFiles({required this.firstMatches, required this.secondMatches});
}

List<Map<String, dynamic>> _parseJson(String path) {
  final lines = File(path).readAsLinesSync();

  final header = lines[0].split(',');

  // Parse the CSV and build the JSON
  final jsonOutput = <Map<String, dynamic>>[];

  for (final line in lines.skip(1)) {
    final row = line.split(',');

    final row2 = row[header.indexOf('esports_match_id')];
    final matchId = int.parse(row2);
    final teamName = row[header.indexOf('team_name')];
    final stage = row[header.indexOf('tournament_title')];
    final startTime = row[header.indexOf('start_time')];
    final mapName = row[header.indexOf('map_name')];
    final mapType = row[header.indexOf('map_type')];
    final playerName = row[header.indexOf('player_name')];
    final hero = row[header.indexOf('hero_name')];
    final statName = row[header.indexOf('stat_name')];
    final amount = double.parse(row[header.indexOf('stat_amount')]);

    final existingMatch = jsonOutput.firstWhereOrNull(
      (match) => match['match_id'] == matchId,
    );

    if (existingMatch == null) {
      jsonOutput.add(
        {
          "match_id": matchId,
          'stage': stage,
          "team_1_name": teamName,
          "team_2_name": null,
          "maps": [
            {
              "start_time": startTime,
              "map_name": mapName,
              "map_type": mapType,
              "team_1_players": [
                {
                  "player_name": playerName,
                  "stats_per_hero": [
                    {
                      "hero": hero,
                      "stats": [
                        {
                          "stat_name": statName,
                          "amount": amount,
                        },
                      ]
                    }
                  ]
                }
              ],
              "team_2_players": [],
            }
          ]
        },
      );

      continue;
    }

    final team2Name = existingMatch['team_2_name'];
    if (team2Name == null && existingMatch['team_1_name'] != teamName) {
      existingMatch['team_2_name'] = teamName;
    }
    final map =
        List<Map<String, dynamic>>.from(existingMatch['maps']).firstWhereOrNull(
      (m) => m['map_name'] == mapName,
    );

    if (map == null) {
      existingMatch['maps'].add(
        {
          "start_time": startTime,
          "map_name": mapName,
          "map_type": mapType,
          "team_1_players": [
            {
              "player_name": playerName,
              "stats_per_hero": [
                {
                  "hero": hero,
                  "stats": [
                    {"stat_name": statName, "amount": amount},
                  ]
                }
              ]
            }
          ],
          "team_2_players": [],
        },
      );

      continue;
    }
    final isTeam1 = existingMatch['team_1_name'] == teamName;
    final teamString = isTeam1 ? 'team_1_players' : 'team_2_players';

    final player =
        List<Map<String, dynamic>>.from(map[teamString]).firstWhereOrNull(
      (p) => p['player_name'] == playerName,
    );

    if (player == null) {
      map[teamString].add({
        "player_name": playerName,
        "stats_per_hero": [
          {
            "hero": hero,
            "stats": [
              {"stat_name": statName, "amount": amount},
            ]
          }
        ]
      });

      continue;
    }
    final playerHero = List<Map<String, dynamic>>.from(player['stats_per_hero'])
        .firstWhereOrNull((playerHero) => playerHero['hero'] == hero);
    if (playerHero == null) {
      player['stats_per_hero'].add({
        "hero": hero,
        "stats": [
          {"stat_name": statName, "amount": amount},
        ],
      });
    } else {
      playerHero['stats'].add({
        'stat_name': statName,
        'amount': amount,
      });
    }
  }

  return jsonOutput;
}
