import 'package:flutter_test/flutter_test.dart';
import 'package:kambate_mobile/core/utils/nba_team_formatter.dart';

void main() {
  group('NbaTeamFormatter', () {
    test('Formatea nombres completos a sobrenombres de la NBA solicitados (Bucks, Heat, Bulls, etc.)', () {
      expect(NbaTeamFormatter.format('Milwaukee Bucks'), 'Bucks');
      expect(NbaTeamFormatter.format('Miami Heat'), 'Heat');
      expect(NbaTeamFormatter.format('Miami Heats'), 'Heat');
      expect(NbaTeamFormatter.format('Chicago Bulls'), 'Bulls');
      expect(NbaTeamFormatter.format('Los Angeles Lakers'), 'Lakers');
      expect(NbaTeamFormatter.format('LA Lakers'), 'Lakers');
      expect(NbaTeamFormatter.format('Boston Celtics'), 'Celtics');
      expect(NbaTeamFormatter.format('Golden State Warriors'), 'Warriors');
      expect(NbaTeamFormatter.format('Denver Nuggets'), 'Nuggets');
      expect(NbaTeamFormatter.format('Dallas Mavericks'), 'Mavericks');
      expect(NbaTeamFormatter.format('Phoenix Suns'), 'Suns');
      expect(NbaTeamFormatter.format('Philadelphia 76ers'), '76ers');
      expect(NbaTeamFormatter.format('Portland Trail Blazers'), 'Trail Blazers');
      expect(NbaTeamFormatter.format('San Antonio Spurs'), 'Spurs');
    });

    test('Conserva sobrenombres que ya vienen compactos sin alteración', () {
      expect(NbaTeamFormatter.format('Bucks'), 'Bucks');
      expect(NbaTeamFormatter.format('Heat'), 'Heat');
      expect(NbaTeamFormatter.format('Heats'), 'Heat');
      expect(NbaTeamFormatter.format('Bulls'), 'Bulls');
      expect(NbaTeamFormatter.format('Lakers'), 'Lakers');
      expect(NbaTeamFormatter.format('Celtics'), 'Celtics');
      expect(NbaTeamFormatter.format('Warriors'), 'Warriors');
    });

    test('Maneja variaciones de mayúsculas/minúsculas y espacios', () {
      expect(NbaTeamFormatter.format('  milwaukee bucks  '), 'Bucks');
      expect(NbaTeamFormatter.format('MIAMI HEAT'), 'Heat');
      expect(NbaTeamFormatter.format('chicago bulls'), 'Bulls');
    });

    test('Retorna el nombre sin modificar si no corresponde a la NBA', () {
      expect(NbaTeamFormatter.format('Colo-Colo'), 'Colo-Colo');
      expect(NbaTeamFormatter.format('U. de Chile'), 'U. de Chile');
      expect(NbaTeamFormatter.format('Real Madrid'), 'Real Madrid');
    });

    test('Maneja nulos y cadenas vacías de forma segura', () {
      expect(NbaTeamFormatter.format(null), '');
      expect(NbaTeamFormatter.format(''), '');
      expect(NbaTeamFormatter.format('   '), '');
    });
  });
}
