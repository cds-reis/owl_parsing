import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';

class DetailsService {
  final List<Map<String, dynamic>> _details;

  const DetailsService._(this._details);

  static const _defaultInputPath = 'csvs/match_map_stats.csv';
  static const _defaultOutputPath = 'output/stats/match_map_stats.json';

  factory DetailsService.load([String path = _defaultOutputPath]) {
    final content = File(path).readAsStringSync();

    final details = List<Map<String, dynamic>>.from(jsonDecode(content));

    return DetailsService._(details);
  }

  void detailMatch(Map<String, dynamic> match) {
    final matchId = match['match_id'] as int;
    final matchDetails = _details.firstWhere(
      (match) => match['match_id'] == matchId,
    );

    match['match_winner'] = matchDetails['match_winner'];
    match['match_loser'] = matchDetails['match_loser'];

    final maps = match['maps'] as List<dynamic>;

    for (var i = 0; i < maps.length; i++) {
      final matchMap = maps[i];
      final mapDetails = matchDetails['maps'][i];

      matchMap['map_winner'] = mapDetails['map_winner'];
      matchMap['map_loser'] = mapDetails['map_loser'];
      matchMap['winning_team_final_map_score'] =
          mapDetails['winning_team_final_map_score'];
      matchMap['losing_team_final_map_score'] =
          mapDetails['losing_team_final_map_score'];

      matchMap['rounds'] = mapDetails['rounds'];
    }
  }

  void detailStage(Map<String, dynamic> match) {
    final matchId = match['match_id'] as int;
    final matchDetails = _details.firstWhere(
      (match) => match['match_id'] == matchId,
    );

    match['stage'] = matchDetails['stage'];
  }

  static void formatCsvToJson({
    String csvPath = _defaultInputPath,
    String outputPath = _defaultOutputPath,
  }) {
    final csv = File(csvPath).readAsLinesSync();

    final header = csv[0].split(',');

    final jsonOutput = <Map<String, dynamic>>[];

    // skips header
    for (final line in csv.skip(1)) {
      final row = line.split(',');

      final roundStartTime = row[header.indexOf('round_start_time')];
      final roundEndTime = row[header.indexOf('round_end_time')];
      final stage = row[header.indexOf('stage')];
      final matchId = int.parse(row[header.indexOf('match_id')]);
      final gameNumber = int.parse(row[header.indexOf('game_number')]);
      final matchWinner = row[header.indexOf('match_winner')];
      final mapWinner = row[header.indexOf('map_winner')];
      final mapLoser = row[header.indexOf('map_loser')];
      final mapName = row[header.indexOf('map_name')];
      final mapRound = int.parse(row[header.indexOf('map_round')]);
      final winningTeamFinalMapScore =
          int.parse(row[header.indexOf('winning_team_final_map_score')]);
      final losingTeamFinalMapScore =
          int.parse(row[header.indexOf('losing_team_final_map_score')]);
      final controlRoundName = row[header.indexOf('control_round_name')];
      final attacker = row[header.indexOf('Attacker')];
      final defender = row[header.indexOf('Defender')];
      final teamOneName = row[header.indexOf('team_one_name')];
      final teamTwoName = row[header.indexOf('team_two_name')];
      final attackerPayloadDistance =
          double.tryParse(row[header.indexOf('attacker_payload_distance')]);
      final defenderPayloadDistance =
          double.tryParse(row[header.indexOf('defender_payload_distance')]);
      final attackerTimeBanked =
          double.tryParse(row[header.indexOf('attacker_time_banked')]);
      final defenderTimeBanked =
          double.tryParse(row[header.indexOf('defender_time_banked')]);
      final attackerControlPercent =
          int.tryParse(row[header.indexOf('attacker_control_percent')]);
      final defenderControlPercent =
          int.tryParse(row[header.indexOf('defender_control_percent')]);
      final attackerRoundEndScore =
          int.parse(row[header.indexOf('attacker_round_end_score')]);
      final defenderRoundEndScore =
          int.parse(row[header.indexOf('defender_round_end_score')]);
      final mapType = MapType.fromString(mapName);

      final matchLoser = _decideMatchLoser(
        matchWinner: matchWinner,
        team1Name: teamOneName,
        team2Name: teamTwoName,
      );

      final match = jsonOutput.firstWhereOrNull(
        (match) => match['match_id'] == matchId,
      );

      if (match == null) {
        jsonOutput.add(
          {
            'match_id': matchId,
            'stage': stage,
            'team_one': teamOneName,
            'team_two': teamTwoName,
            'match_winner': matchWinner,
            'match_loser': matchLoser,
            'maps': [
              {
                'name': mapName,
                'map_winner': mapWinner,
                'map_loser': mapLoser,
                'game_number': gameNumber,
                "winning_team_final_map_score": winningTeamFinalMapScore,
                "losing_team_final_map_score": losingTeamFinalMapScore,
                "map_type": mapType.name.toUpperCase(),
                'rounds': [
                  {
                    "start_time": roundStartTime,
                    "end_time": roundEndTime,
                    'map_round': mapRound,
                    "attacker": attacker,
                    "defender": defender,
                    "details": switch (mapType) {
                      MapType.control => {
                          'control_round_name': controlRoundName,
                          'attacker_control_percent': attackerControlPercent!,
                          'defender_control_percent': defenderControlPercent!,
                          'attacker_round_end_score': attackerRoundEndScore,
                          'defender_round_end_score': defenderRoundEndScore,
                        },
                      MapType.payload || MapType.hybrid => {
                          'attacker_payload_distance': attackerPayloadDistance!,
                          'defender_payload_distance': defenderPayloadDistance!,
                          'attacker_time_banked': attackerTimeBanked!,
                          'defender_time_banked': defenderTimeBanked!,
                          'attacker_round_end_score': attackerRoundEndScore,
                          'defender_round_end_score': defenderRoundEndScore,
                        },
                      MapType.assault => {
                          'attacker_time_banked': attackerTimeBanked!,
                          'defender_time_banked': defenderTimeBanked!,
                          'attacker_round_end_score': attackerRoundEndScore,
                          'defender_round_end_score': defenderRoundEndScore,
                        },
                      MapType.push => {
                          'attacker_payload_distance': attackerPayloadDistance!,
                          'defender_payload_distance': defenderPayloadDistance!,
                          'attacker_round_end_score': attackerRoundEndScore,
                          'defender_round_end_score': defenderRoundEndScore,
                        },
                    }
                  }
                ]
              }
            ]
          },
        );

        continue;
      }

      final matchMaps = match['maps'] as List<dynamic>;

      final map = matchMaps.firstWhereOrNull(
        (map) => map['game_number'] == gameNumber,
      );

      if (map == null) {
        match['maps'].add(
          {
            'name': mapName,
            'map_winner': mapWinner,
            'map_loser': mapLoser,
            'game_number': gameNumber,
            "winning_team_final_map_score": winningTeamFinalMapScore,
            "losing_team_final_map_score": losingTeamFinalMapScore,
            "map_type": mapType.name.toUpperCase(),
            'rounds': <Map<String, dynamic>>[
              {
                "start_time": roundStartTime,
                "end_time": roundEndTime,
                'map_round': mapRound,
                "attacker": attacker,
                "defender": defender,
                "details": switch (mapType) {
                  MapType.control => {
                      'control_round_name': controlRoundName,
                      'attacker_control_percent': attackerControlPercent!,
                      'defender_control_percent': defenderControlPercent!,
                      'attacker_round_end_score': attackerRoundEndScore,
                      'defender_round_end_score': defenderRoundEndScore,
                    },
                  MapType.payload || MapType.hybrid => {
                      'attacker_payload_distance': attackerPayloadDistance!,
                      'defender_payload_distance': defenderPayloadDistance!,
                      'attacker_time_banked': attackerTimeBanked!,
                      'defender_time_banked': defenderTimeBanked!,
                      'attacker_round_end_score': attackerRoundEndScore,
                      'defender_round_end_score': defenderRoundEndScore,
                    },
                  MapType.assault => {
                      'attacker_time_banked': attackerTimeBanked!,
                      'defender_time_banked': defenderTimeBanked!,
                      'attacker_round_end_score': attackerRoundEndScore,
                      'defender_round_end_score': defenderRoundEndScore,
                    },
                  MapType.push => {
                      'attacker_payload_distance': attackerPayloadDistance!,
                      'defender_payload_distance': defenderPayloadDistance!,
                      'attacker_round_end_score': attackerRoundEndScore,
                      'defender_round_end_score': defenderRoundEndScore,
                    },
                }
              }
            ]
          },
        );

        continue;
      }

      final mapRounds = map['rounds'] as List<dynamic>;

      mapRounds.add(
        {
          "start_time": roundStartTime,
          "end_time": roundEndTime,
          'map_round': mapRound,
          "attacker": attacker,
          "defender": defender,
          "details": switch (mapType) {
            MapType.control => {
                'control_round_name': controlRoundName,
                'attacker_control_percent': attackerControlPercent!,
                'defender_control_percent': defenderControlPercent!,
                'attacker_round_end_score': attackerRoundEndScore,
                'defender_round_end_score': defenderRoundEndScore,
              },
            MapType.payload || MapType.hybrid => {
                'attacker_payload_distance': attackerPayloadDistance!,
                'defender_payload_distance': defenderPayloadDistance!,
                'attacker_time_banked': attackerTimeBanked!,
                'defender_time_banked': defenderTimeBanked!,
                'attacker_round_end_score': attackerRoundEndScore,
                'defender_round_end_score': defenderRoundEndScore,
              },
            MapType.assault => {
                'attacker_time_banked': attackerTimeBanked!,
                'defender_time_banked': defenderTimeBanked!,
                'attacker_round_end_score': attackerRoundEndScore,
                'defender_round_end_score': defenderRoundEndScore,
              },
            MapType.push => {
                'attacker_payload_distance': attackerPayloadDistance!,
                'defender_payload_distance': defenderPayloadDistance!,
                'attacker_round_end_score': attackerRoundEndScore,
                'defender_round_end_score': defenderRoundEndScore,
              },
          }
        },
      );
    }

    File(outputPath).writeAsStringSync(jsonEncode(jsonOutput));
  }

  static String _decideMatchLoser({
    required String matchWinner,
    required String team1Name,
    required String team2Name,
  }) {
    if (matchWinner == team1Name) {
      return team2Name;
    }

    if (matchWinner == team2Name) {
      return team1Name;
    }

    if (matchWinner == 'Seoul Infernal') {
      return team1Name == 'Philadelphia Fusion' ? team2Name : team1Name;
    }

    if (matchWinner == 'Vegas Eternal') {
      return team1Name == 'Paris Eternal' ? team2Name : team1Name;
    }

    throw UnimplementedError();
  }
}

enum MapType {
  payload(
    [
      'Dorado',
      'Junkertown',
      'Route 66',
      'Watchpoint: Gibraltar',
      'Rialto',
      'Havana',
      'Circuit royal',
      'Shambali Monastery',
    ],
  ),
  assault([
    'Horizon Lunar Colony',
    'Temple of Anubis',
    'Hanamura',
    'Volskaya Industries',
    'Paris',
  ]),
  control([
    'Ilios',
    'Oasis',
    'Lijiang Tower',
    'Nepal',
    'Busan',
    'Antarctic Peninsula',
  ]),
  hybrid(
    [
      'Eichenwalde',
      'Numbani',
      'Hollywood',
      "King's Row",
      'Blizzard World',
      'Midtown',
      'Paraíso',
    ],
  ),
  push(['New Queen Street', 'Colosseo', 'Esperança']);

  final List<String> names;

  const MapType(this.names);

  factory MapType.fromString(String mapName) => MapType.values.firstWhere(
        (mapType) => mapType.names.contains(mapName),
      );
}
