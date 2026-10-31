import 'package:flutter_test/flutter_test.dart';
import 'package:kambate_mobile/core/utils/match_round_formatter.dart';

void main() {
  group('MatchRoundFormatter', () {
    test('Fechas / jornadas numeradas se muestran como "Fecha N"', () {
      expect(MatchRoundFormatter.format('12'), 'Fecha 12');
      expect(MatchRoundFormatter.format('Regular Season - 12'), 'Fecha 12');
      expect(MatchRoundFormatter.format('Matchday 5'), 'Fecha 5');
      expect(MatchRoundFormatter.format('Round 30'), 'Fecha 30');
      expect(MatchRoundFormatter.format('Jornada 8'), 'Fecha 8');
      expect(MatchRoundFormatter.format('Fecha 3'), 'Fecha 3');
    });

    test('Fases eliminatorias se traducen al español', () {
      expect(MatchRoundFormatter.format('Round of 32'), 'Dieciseisavos de final');
      expect(MatchRoundFormatter.format('Round of 16'), 'Octavos de final');
      expect(MatchRoundFormatter.format('Quarter-finals'), 'Cuartos de final');
      expect(MatchRoundFormatter.format('Quarterfinals'), 'Cuartos de final');
      expect(MatchRoundFormatter.format('Semi-finals'), 'Semifinal');
      expect(MatchRoundFormatter.format('3rd Place Final'), 'Tercer puesto');
      expect(MatchRoundFormatter.format('Final'), 'Final');
    });

    test('Fases de grupos y de liga', () {
      expect(MatchRoundFormatter.format('Group Stage'), 'Fase de grupos');
      expect(MatchRoundFormatter.format('Group C'), 'Grupo C');
      expect(MatchRoundFormatter.format('League Phase'), 'Fase de liga');
      expect(MatchRoundFormatter.format('Knockout Round Playoffs'), 'Playoffs');
    });

    test('Valores en español o desconocidos se conservan', () {
      expect(MatchRoundFormatter.format('Fase de Liga'), 'Fase de liga');
      expect(MatchRoundFormatter.format('Cuartos de final'), 'Cuartos de final');
      expect(MatchRoundFormatter.format('Liguilla Apertura'), 'Liguilla Apertura');
    });

    test('Nulos y vacíos devuelven null', () {
      expect(MatchRoundFormatter.format(null), isNull);
      expect(MatchRoundFormatter.format(''), isNull);
      expect(MatchRoundFormatter.format('   '), isNull);
    });
  });
}

