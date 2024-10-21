import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:owl_parsing/teams/team_color.dart';

class TeamParser {
  static Team parseTeamRegularSeason({
    required String teamName,
    required TeamColor teamColor,
    required List<File> files,
  }) {
    bool teamIsInMatch(dynamic match) {
      return match['team_1_name'] == teamName ||
          match['team_2_name'] == teamName;
    }

    const regularSeasonStagesKey = 'regular_season_stages';
    const weeksKey = 'weeks';

    final TeamColor(primaryColor: (:r, :g, :b)) = teamColor;
    final secondaryColor = teamColor.secondaryColor;

    final jsonOutput = <String, dynamic>{
      'team_name': teamName,
      'primary_color': {
        'r': r,
        'g': g,
        'b': b,
      },
      if (secondaryColor != null)
        'secondary_color': {
          'r': secondaryColor.r,
          'g': secondaryColor.g,
          'b': secondaryColor.b,
        },
      regularSeasonStagesKey: [],
    };

    var seasonMatchWins = 0;
    var seasonMatchLosses = 0;

    var seasonMapWins = 0;
    var seasonMapLosses = 0;
    var seasonMapDraws = 0;

    for (int i = 0; i < files.length; i++) {
      final stageFile = files[i];
      final stageJson = List<Map<String, dynamic>>.from(
        jsonDecode(stageFile.readAsStringSync()),
      );

      jsonOutput[regularSeasonStagesKey].add(
        {
          'name': 'Stage ${i + 1}',
          weeksKey: [],
        },
      );

      var stageMatchWins = 0;
      var stageMatchLosses = 0;

      var stageMapWins = 0;
      var stageMapLosses = 0;
      var stageMapDraws = 0;

      for (final week in stageJson) {
        if (week['name'] == 'Stage Playoffs') {
          final stagePlayoffMatches = week['matches'] as List<dynamic>;
          final teamMatches = stagePlayoffMatches.where(teamIsInMatch).toList();

          if (teamMatches.isEmpty) continue;

          final matchesWon = teamMatches
              .where(
                (match) => _teamWonMatch(match['match_winner'], teamName),
              )
              .toList();

          final amountOfMatchesLost = teamMatches.length - matchesWon.length;

          jsonOutput[regularSeasonStagesKey][i]['stage_playoffs'] = {
            'name': week['name'],
            'winner': amountOfMatchesLost == 0,
            'wins': matchesWon.length,
            'losses': amountOfMatchesLost,
            'matches': teamMatches,
          };
        } else {
          final weekMatches = week['matches'] as List<dynamic>;
          final teamMatches = weekMatches.where(teamIsInMatch).toList();

          var weekMatchWins = 0;
          var weekMatchLosses = 0;
          var weekMapWins = 0;
          var weekMapLosses = 0;
          var weekMapDraws = 0;
          for (final match in teamMatches) {
            if (_teamWonMatch(match['match_winner'], teamName)) {
              weekMatchWins++;
            } else {
              weekMatchLosses++;
            }

            var matchMapWins = 0;
            var matchMapLosses = 0;
            var matchMapDraws = 0;
            for (final map in match['maps']) {
              if (map['map_winner'] == teamName) {
                matchMapWins++;
              } else if (map['map_loser'] == teamName) {
                matchMapLosses++;
              } else {
                matchMapDraws++;
              }
            }

            match['map_wins'] = matchMapWins;
            match['map_losses'] = matchMapLosses;
            match['map_draws'] = matchMapDraws;
            match['maps_played_amount'] =
                matchMapWins + matchMapLosses + matchMapDraws;

            weekMapWins += matchMapWins;
            weekMapLosses += matchMapLosses;
            weekMapDraws += matchMapDraws;
          }

          stageMapWins += weekMapWins;
          stageMapLosses += weekMapLosses;
          stageMapDraws += weekMapDraws;

          stageMatchWins += weekMatchWins;
          stageMatchLosses += weekMatchLosses;

          jsonOutput[regularSeasonStagesKey][i][weeksKey].add(
            {
              'name': week['name'],
              'wins': weekMatchWins,
              'losses': weekMatchLosses,
              'map_wins': weekMapWins,
              'map_losses': weekMapLosses,
              'map_draws': weekMapDraws,
              'matches': teamMatches,
            },
          );
        }
      }

      seasonMatchWins += stageMatchWins;
      seasonMatchLosses += stageMatchLosses;

      seasonMapWins += stageMapWins;
      seasonMapLosses += stageMapLosses;
      seasonMapDraws += stageMapDraws;

      final stage = jsonOutput[regularSeasonStagesKey][i];
      stage['wins'] = stageMatchWins;
      stage['losses'] = stageMatchLosses;

      stage['map_wins'] = stageMapWins;
      stage['map_losses'] = stageMapLosses;
      stage['map_draws'] = stageMapDraws;
    }

    jsonOutput['wins'] = seasonMatchWins;
    jsonOutput['losses'] = seasonMatchLosses;

    jsonOutput['map_wins'] = seasonMapWins;
    jsonOutput['map_losses'] = seasonMapLosses;
    jsonOutput['map_draws'] = seasonMapDraws;

    return Team(jsonOutput);
  }

  static bool _teamWonMatch(String matchWinner, String teamName) {
    if (matchWinner == teamName) {
      return true;
    }

    if (matchWinner == 'Seoul Infernal' && teamName == 'Philadelphia Fusion') {
      return true;
    }

    if (matchWinner == 'Vegas Eternal' && teamName == 'Paris Eternal') {
      return true;
    }

    return false;
  }
}

class Season3TeamParser {
  static Team parseSeason3({
    required String teamName,
    required TeamColor teamColor,
    String seasonFilePath = 'output/2020/weeks/phs_2020.json',
  }) {
    final TeamColor(primaryColor: (:r, :g, :b)) = teamColor;
    final secondaryColor = teamColor.secondaryColor;
    final seasonJson = Map<String, dynamic>.from(
      jsonDecode(File(seasonFilePath).readAsStringSync()),
    );

    final jsonOutput = <String, dynamic>{
      'team_name': teamName,
      'primary_color': {
        'r': r,
        'g': g,
        'b': b,
      },
      if (secondaryColor != null)
        'secondary_color': {
          'r': secondaryColor.r,
          'g': secondaryColor.g,
          'b': secondaryColor.b,
        },
      regularSeasonKey: {
        'wins': 0,
        'losses': 0,
        'map_wins': 0,
        'map_losses': 0,
        'map_draws': 0,
        'weeks': [],
      },
    };

    _parseRegularSeason(seasonJson, teamName, jsonOutput);
    _parseStage('May Melee', seasonJson, teamName, jsonOutput);
    _parseStage('Summer Showdown', seasonJson, teamName, jsonOutput);
    _parseStage('Countdown Cup', seasonJson, teamName, jsonOutput);
    _parsePlayoffs(seasonJson, teamName, jsonOutput);

    return Team(jsonOutput);
  }

  static const regularSeasonKey = '2020: Regular Season';

  static void _parseRegularSeason(
    Map<String, dynamic> seasonJson,
    String teamName,
    Map<String, dynamic> jsonOutput,
  ) {
    final regularSeason = _transformRegularSeason(seasonJson);
    final weeks = regularSeason.entries;

    var regularSeasonMatchWins = 0;
    var regularSeasonMatchLosses = 0;
    var regularSeasonMapWins = 0;
    var regularSeasonMapLosses = 0;
    var regularSeasonMapDraws = 0;

    for (final MapEntry(key: weekName, value: weekMatches) in weeks) {
      var weekMatchWins = 0;
      var weekMatchLosses = 0;
      var weekMapWins = 0;
      var weekMapLosses = 0;
      var weekMapDraws = 0;

      final teamMatches = weekMatches
          .where((match) => _teamIsInMatch(match, teamName))
          .toList();

      for (final match in teamMatches) {
        var matchMapWins = 0;
        var matchMapLosses = 0;
        var matchMapDraws = 0;

        for (final map in List<Map<String, dynamic>>.from(match['maps'])) {
          if (map['map_winner'] == teamName) {
            matchMapWins++;
          } else if (map['map_loser'] == teamName) {
            matchMapLosses++;
          } else {
            matchMapDraws++;
          }
        }

        if (TeamParser._teamWonMatch(match['match_winner'], teamName)) {
          weekMatchWins++;
        } else {
          weekMatchLosses++;
        }

        match['map_wins'] = matchMapWins;
        match['map_losses'] = matchMapLosses;
        match['map_draws'] = matchMapDraws;
        match['maps_played_amount'] =
            matchMapWins + matchMapLosses + matchMapDraws;

        weekMapWins += matchMapWins;
        weekMapLosses += matchMapLosses;
        weekMapDraws += matchMapDraws;
      }

      regularSeasonMatchWins += weekMatchWins;
      regularSeasonMatchLosses += weekMatchLosses;
      regularSeasonMapWins += weekMapWins;
      regularSeasonMapLosses += weekMapLosses;
      regularSeasonMapDraws += weekMapDraws;

      jsonOutput[regularSeasonKey]['weeks'].add(
        {
          'name': weekName,
          'wins': weekMatchWins,
          'losses': weekMatchLosses,
          'map_wins': weekMapWins,
          'map_losses': weekMapLosses,
          'map_draws': weekMapDraws,
          'matches': teamMatches,
        },
      );
    }

    jsonOutput[regularSeasonKey]['wins'] = regularSeasonMatchWins;
    jsonOutput[regularSeasonKey]['losses'] = regularSeasonMatchLosses;
    jsonOutput[regularSeasonKey]['map_wins'] = regularSeasonMapWins;
    jsonOutput[regularSeasonKey]['map_losses'] = regularSeasonMapLosses;
    jsonOutput[regularSeasonKey]['map_draws'] = regularSeasonMapDraws;
  }

  static void _parseStage(
    String stageName,
    Map<String, dynamic> seasonJson,
    String teamName,
    Map<String, dynamic> jsonOutput,
  ) {
    final stageKey = '2020: $stageName';
    const placeKey = 'place';
    const bonusWinsKey = 'bonus_wins';
    const regionKey = 'region';
    const knockoutMatchesKey = 'knockout_matches';
    const tournamentMatchesKey = 'tournament_matches';

    final knockoutsKey = '2020: $stageName: North America Knockouts';
    final americaKey = '2020: $stageName: North America';

    final knockoutsMatches = List<Map<String, dynamic>>.from(
      seasonJson[knockoutsKey],
    );

    final americaMatches = List<Map<String, dynamic>>.from(
      seasonJson[americaKey],
    );

    final teamKnockoutMatches = knockoutsMatches
        .where((match) => _teamIsInMatch(match, teamName))
        .toList();

    final teamAmericaMatches = americaMatches
        .where((match) => _teamIsInMatch(match, teamName))
        .toList();

    if (teamKnockoutMatches.isNotEmpty || teamAmericaMatches.isNotEmpty) {
      // team is in north america
      final is13thSeed = knockoutsMatches.first['match_loser'] == teamName;
      const region = 'North America';

      if (is13thSeed) {
        jsonOutput[stageKey] = {
          placeKey: '13th',
          bonusWinsKey: 0,
          regionKey: region,
          knockoutMatchesKey: [teamKnockoutMatches.single],
          tournamentMatchesKey: [],
        };

        return;
      }

      final teamLostKnockouts = teamKnockoutMatches.any(
        (match) => !TeamParser._teamWonMatch(match['match_winner'], teamName),
      );

      if (teamLostKnockouts) {
        jsonOutput[stageKey] = {
          placeKey: '9th-12th',
          bonusWinsKey: 0,
          regionKey: region,
          knockoutMatchesKey: teamKnockoutMatches,
          tournamentMatchesKey: [],
        };

        return;
      }

      switch (teamAmericaMatches) {
        case [final quarterFinals]:
          jsonOutput[stageKey] = {
            placeKey: '5th-8th',
            bonusWinsKey: 0,
            regionKey: region,
            knockoutMatchesKey: teamKnockoutMatches,
            tournamentMatchesKey: [quarterFinals],
          };
        case [final quarterFinals, final semiFinals]:
          jsonOutput[stageKey] = {
            placeKey: '3rd-4th',
            bonusWinsKey: 1,
            regionKey: region,
            knockoutMatchesKey: teamKnockoutMatches,
            tournamentMatchesKey: [quarterFinals, semiFinals],
          };
        case [final quarterFinals, final semiFinals, final finals]:
          if (TeamParser._teamWonMatch(finals['match_winner'], teamName)) {
            jsonOutput[stageKey] = {
              placeKey: '1st',
              bonusWinsKey: 3,
              regionKey: region,
              knockoutMatchesKey: teamKnockoutMatches,
              tournamentMatchesKey: [quarterFinals, semiFinals, finals],
            };
          } else {
            jsonOutput[stageKey] = {
              placeKey: '2nd',
              bonusWinsKey: 2,
              regionKey: region,
              knockoutMatchesKey: teamKnockoutMatches,
              tournamentMatchesKey: [quarterFinals, semiFinals, finals],
            };
          }
        default:
          throw UnimplementedError(
            'Esqueceu de alguma coisa aqui. $teamAmericaMatches',
          );
      }

      return;
    }

    // team is in asia
    const region = 'Asia';
    final asiaKey = '2020: $stageName: Asia';
    final asiaMatches = List<Map<String, dynamic>>.from(seasonJson[asiaKey]);
    final teamMatches =
        asiaMatches.where((match) => _teamIsInMatch(match, teamName)).toList();
    final quarterFinals = asiaMatches.take(3).toList();

    final teamGotByeMatch = quarterFinals.none(
      (match) => _teamIsInMatch(match, teamName),
    );

    if (teamGotByeMatch) {
      switch (teamMatches) {
        case [final semiFinals]:
          jsonOutput[stageKey] = {
            placeKey: '3rd-4th',
            bonusWinsKey: 1,
            regionKey: region,
            tournamentMatchesKey: [semiFinals],
          };
        case [final semiFinals, final finals]:
          if (TeamParser._teamWonMatch(finals['match_winner'], teamName)) {
            jsonOutput[stageKey] = {
              placeKey: '1st',
              bonusWinsKey: 3,
              regionKey: region,
              tournamentMatchesKey: [semiFinals, finals],
            };
          }

        default:
          throw UnimplementedError(
            'Esqueceu de alguma coisa aqui. $teamMatches',
          );
      }

      return;
    }

    switch (teamMatches) {
      case [final quarterFinals]:
        jsonOutput[stageKey] = {
          placeKey: '5th-7th',
          bonusWinsKey: 0,
          regionKey: region,
          tournamentMatchesKey: [quarterFinals],
        };
      case [final quarterFinals, final semiFinals]:
        jsonOutput[stageKey] = {
          placeKey: '3rd-4th',
          bonusWinsKey: 1,
          regionKey: region,
          tournamentMatchesKey: [quarterFinals, semiFinals],
        };
      case [final quarterFinals, final semiFinals, final finals]:
        final teamWonFinals = TeamParser._teamWonMatch(
          finals['match_winner'],
          teamName,
        );
        jsonOutput[stageKey] = {
          placeKey: teamWonFinals ? '1st' : '2nd',
          bonusWinsKey: teamWonFinals ? 3 : 2,
          regionKey: region,
          tournamentMatchesKey: [quarterFinals, semiFinals, finals],
        };
      default:
        throw UnimplementedError(
          'Esqueceu de alguma coisa aqui. $teamMatches',
        );
    }
  }

  static void _parsePlayoffs(
    Map<String, dynamic> seasonJson,
    String teamName,
    Map<String, dynamic> jsonOutput,
  ) {
    final asianPlayoffMatches =
        List<Map<String, dynamic>>.from(seasonJson['2020: Asia Playoffs']);

    final isAsianTeam =
        asianPlayoffMatches.any((match) => _teamIsInMatch(match, teamName));

    if (isAsianTeam) {
      _parseAsiaPlayoffs(asianPlayoffMatches, teamName, jsonOutput);
    }
  }

  static void _parseAsiaPlayoffs(
    List<Map<String, dynamic>> asiaPlayoffMatches,
    String teamName,
    Map<String, dynamic> jsonOutput,
  ) {
    const playoffsKey = '2020: Asia Playoffs';
    final playins = asiaPlayoffMatches.take(3).toList();
    final int position;

    final teamPlayinMatches =
        playins.where((match) => _teamIsInMatch(match, teamName)).toList();

    jsonOutput[playoffsKey] = {
      'playins': teamPlayinMatches,
    };
  }

  static bool _teamIsInMatch(Map<String, dynamic> match, String teamName) {
    return match['team_1_name'] == teamName || match['team_2_name'] == teamName;
  }

  static Map<String, List<Map<String, dynamic>>> _transformRegularSeason(
    Map<String, dynamic> seasonJson,
  ) {
    final regularSeason = Map<String, dynamic>.from(
      seasonJson['2020: Regular Season']!,
    );

    return regularSeason.map(
      (key, value) => MapEntry(key, List<Map<String, dynamic>>.from(value)),
    );
  }
}

class Team {
  final Map<String, dynamic> json;

  Team(this.json);

  Map<String, dynamic> asMap() => {
        'team_name': json['team_name'],
        'primary_color': json['primary_color'],
        if (json.containsKey('secondary_color'))
          'secondary_color': json['secondary_color'],
        'wins': json['wins'],
        'losses': json['losses'],
        'map_wins': json['map_wins'],
        'map_losses': json['map_losses'],
        'map_draws': json['map_draws'],
        'regular_season_stages': json['regular_season_stages'],
        if (json.containsKey('playoffs')) 'playoffs': json['playoffs'],
      };
}
