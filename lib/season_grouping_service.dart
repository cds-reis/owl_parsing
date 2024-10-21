import 'dart:convert';
import 'dart:io';

class SeasonGroupingService {
  static void groupSeasons({
    required String teamName,
  }) {
    final formattedName = teamName.toLowerCase().split(' ').join('_');

    const season1Key = 'season_1';
    const season2Key = 'season_2';
    const season3Key = 'season_3';

    final jsonOutput = <String, dynamic>{
      'team_name': teamName,
      season1Key: null,
      season2Key: null,
    };

    final season1File = _getSeason1File(formattedName);

    if (season1File.existsSync()) {
      jsonOutput[season1Key] = jsonDecode(season1File.readAsStringSync());
    }

    final season2File = _getSeason2File(formattedName);
    jsonOutput[season2Key] = jsonDecode(season2File.readAsStringSync());

    final season3File = _getSeason3File(formattedName);
    jsonOutput[season3Key] = jsonDecode(season3File.readAsStringSync());

    File(_outputFile(formattedName)).writeAsStringSync(jsonEncode(jsonOutput));
  }

  static String _outputFile(String formattedTeamName) =>
      'output/teams/$formattedTeamName.json';

  static File _getSeason2File(String formattedName) =>
      _getSeasonFile(2019, formattedName);
  static File _getSeason1File(String formattedName) =>
      _getSeasonFile(2018, formattedName);
  static File _getSeason3File(String formattedName) =>
      File('output/2020/team_no_stats/$formattedName.json');

  static File _getSeasonFile(int season, String formattedName) =>
      File('output/$season/teams_no_stats/$formattedName.json');
}
