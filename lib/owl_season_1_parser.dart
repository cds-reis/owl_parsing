import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:owl_parsing/utils.dart';

String parseSeason1StageToJson(String fileName) {
  final inputFile = File('csvs/$fileName.csv');
  final lines = inputFile.readAsLinesSync();

  // Extract the header
  final header = lines[0].split(',');

  // Parse the CSV and build the JSON
  final jsonOutput = <Map<String, dynamic>>[];

  for (final line in lines.skip(1)) {
    final row = line.split(',');

    final row2 = row[header.indexOf('match_id')];
    final int matchId;
    try {
      matchId = int.parse(row2);
    } catch (e) {
      print(row2);
      print(line);
      rethrow;
    }
    final teamName = row[header.indexOf('team')];
    final stage = row[header.indexOf('stage')];
    final startTime = row[header.indexOf('start_time')];
    final mapName = row[header.indexOf('map_name')];
    final mapType = row[header.indexOf('map_type')];
    final playerName = row[header.indexOf('player')];
    final hero = row[header.indexOf('hero')];
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

  return jsonEncode(jsonOutput);
}

String groupSeason1StageByRegularSeasonAndPlayoffs(int year, String fileName) {
  final jsonFile = File(outputFile(year, fileName)).readAsStringSync();
  final json = List<Map<String, dynamic>>.from(jsonDecode(jsonFile));

  final jsonOutput = <String, List<Map<String, dynamic>>>{
    regularSeasonMatchesKey: [],
    stagePlayoffsMatchesKey: [],
  };

  for (final match in json) {
    final stage = match['stage'] as String;
    final key = stage.contains('Title Matches')
        ? stagePlayoffsMatchesKey
        : regularSeasonMatchesKey;

    jsonOutput[key]!.add(match);
  }

  return jsonEncode(jsonOutput);
}

const regularSeasonMatchesKey = 'regular_season_matches';
const stagePlayoffsMatchesKey = 'stage_playoffs_matches';

String groupByWeeks(int year, String fileName) {
  final jsonFile =
      File(groupedByRegularSeasonAndPlayoffsOutputFile(year, fileName))
          .readAsStringSync();
  final json = Map<String, List<dynamic>>.from(jsonDecode(jsonFile));

  final jsonOutput = <Map<String, dynamic>>[];

  final regularSeasonMatches = json[regularSeasonMatchesKey]!;
  final stagePlayoffMatches = json[stagePlayoffsMatchesKey]!;

  for (final match in regularSeasonMatches) {
    final matchStartRaw = match['maps'][0]['start_time'] as String;
    final matchStart = parseDate(matchStartRaw);
    final startOfWeek = getStartOfWeek(matchStart);

    final week = jsonOutput.firstWhereOrNull((week) {
      final weekDate = parseDate(week['start_of_week']);

      var startOfWeek2 = getStartOfWeek(weekDate);
      return startOfWeek == startOfWeek2;
    });
    if (week == null) {
      jsonOutput.add(
        {
          'name': 'Week ${jsonOutput.length + 1}',
          'start_of_week': startOfWeek.formatted,
          'matches': [match],
        },
      );
    } else {
      (week['matches'] as List<dynamic>).add(match);
    }
  }

  jsonOutput.add(
    {
      'name': 'Stage Playoffs',
      'start_of_week': getStartOfWeek(
        parseDate(stagePlayoffMatches.first['maps'][0]['start_time']),
      ).formatted,
      'matches': stagePlayoffMatches,
    },
  );

  for (final week in jsonOutput) {
    print('${week['name']}: ${week['matches'].length}');
  }

  return jsonEncode(jsonOutput);
}

DateTime parseDate(String value) {
  final [date, time] = value.split(' ');
  final [month, day, year] = date.split('/').map(int.parse).toList();
  final [hour, minute] = time.split(':').map(int.parse).toList();

  return DateTime(year, month, day, hour, minute);
}

DateTime getStartOfWeek(DateTime date) {
  // Assuming weeks start on Monday
  int dayOfWeek = date.weekday;
  return date
      .subtract(Duration(days: dayOfWeek - 1))
      .copyWith(hour: 0, minute: 0, second: 0);
}
