class StatRemover {
  static void removeStats(Map<String, dynamic> match) {
    for (final map in match['maps']) {
      for (final player in map['team_1_players']) {
        player.remove('stats_per_hero');
      }
      for (final player in map['team_2_players']) {
        player.remove('stats_per_hero');
      }
    }
  }
}
