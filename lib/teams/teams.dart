import 'team_color.dart';

final teams = [
  (
    'New York Excelsior',
    TeamColor(
      primaryColor: (r: 15, g: 87, b: 234),
      secondaryColor: (r: 255, g: 28, b: 38),
    ),
  ),
  (
    'Atlanta Reign',
    TeamColor(
      primaryColor: (r: 145, g: 15, b: 27),
      secondaryColor: (r: 239, g: 223, b: 0),
    ),
  ),
  (
    'Boston Uprising',
    TeamColor(
      primaryColor: (r: 23, g: 75, b: 151),
      secondaryColor: (r: 239, g: 223, b: 0),
    ),
  ),
  (
    'Toronto Defiant',
    TeamColor(
      primaryColor: (r: 193, g: 0, b: 3),
      secondaryColor: (r: 0, g: 0, b: 0),
    ),
  ),
  (
    'London Spitfire',
    TeamColor(
      primaryColor: (r: 89, g: 202, b: 232),
      secondaryColor: (r: 255, g: 130, b: 1),
    ),
  ),
  (
    'Philadelphia Fusion',
    TeamColor(
      primaryColor: (r: 249, g: 158, b: 41),
      secondaryColor: (r: 0, g: 0, b: 0),
    ),
  ),
  (
    'Paris Eternal',
    TeamColor(
      primaryColor: (r: 48, g: 61, b: 86),
      secondaryColor: (r: 253, g: 170, b: 30),
    ),
  ),
  (
    'Houston Outlaws',
    TeamColor(
      primaryColor: (r: 151, g: 215, b: 0),
      secondaryColor: (r: 0, g: 0, b: 0),
    ),
  ),
  (
    'Washington Justice',
    TeamColor(
      primaryColor: (r: 153, g: 0, b: 52),
      secondaryColor: (r: 0, g: 55, b: 104),
    ),
  ),
  (
    'Florida Mayhem',
    TeamColor(
      primaryColor: (r: 254, g: 200, b: 1),
      secondaryColor: (r: 175, g: 40, b: 47),
    ),
  ),
  (
    'Vancouver Titans',
    TeamColor(
      primaryColor: (r: 47, g: 178, b: 40),
      secondaryColor: (r: 10, g: 34, b: 108),
    ),
  ),
  (
    'San Francisco Shock',
    TeamColor(
      primaryColor: (r: 252, g: 76, b: 1),
      secondaryColor: (r: 0, g: 0, b: 0),
    ),
  ),
  (
    'Hangzhou Spark',
    TeamColor(
      primaryColor: rgb(251, 114, 153),
      secondaryColor: rgb(87, 136, 206),
    ),
  ),
  (
    'Los Angeles Gladiators',
    TeamColor(
      primaryColor: rgb(96, 38, 158),
      secondaryColor: rgb(255, 255, 255),
    ),
  ),
  (
    'Seoul Dynasty',
    TeamColor(
      primaryColor: rgb(173, 137, 0),
      secondaryColor: rgb(0, 0, 0),
    ),
  ),
  (
    'Guangzhou Charge',
    TeamColor(
      primaryColor: rgb(18, 44, 66),
      secondaryColor: rgb(103, 162, 178),
    ),
  ),
  (
    'Shanghai Dragons',
    TeamColor(
      primaryColor: rgb(210, 39, 48),
      secondaryColor: rgb(252, 227, 0),
    ),
  ),
  (
    'Los Angeles Valiant',
    TeamColor(
      primaryColor: rgb(42, 114, 48),
      secondaryColor: rgb(229, 214, 97),
    ),
  ),
  (
    'Dallas Fuel',
    TeamColor(
      primaryColor: rgb(0, 113, 205),
      secondaryColor: rgb(3, 35, 64),
    ),
  ),
  (
    'Chengdu Hunters',
    TeamColor(
      primaryColor: rgb(253, 157, 10),
      secondaryColor: rgb(180, 146, 106),
    ),
  ),
];

({int r, int g, int b}) rgb(int r, int g, int b) => (r: r, g: g, b: b);
