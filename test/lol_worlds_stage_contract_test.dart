import 'package:flutter_test/flutter_test.dart';
import 'package:kambate_mobile/models/lol_worlds_stage_model.dart';

void main() {
  group('LolWorldsStageModel - Contrato Versionado (Tarea 30)', () {
    test('Parsea fixture representativo de Worlds con etapa suiza, rondas, partidos y avance', () {
      final jsonFixture = {
        'version': 1,
        'competition': {
          'slug': 'worlds',
          'name': 'League of Legends World Championship',
          'sport': 'lol',
        },
        'season': {
          'slug': '2026',
          'name': 'Worlds 2026',
          'year': 2026,
          'isCurrent': true,
        },
        'stage': {
          'id': 'worlds-2026-swiss',
          'slug': 'swiss-stage',
          'name': 'Etapa Suiza',
          'format': 'swiss',
          'status': 'in_progress',
          'currentRoundNumber': 3,
          'totalRounds': 5,
        },
        'rounds': [
          {
            'roundNumber': 1,
            'name': 'Ronda 1 (0-0)',
            'status': 'completed',
            'matchIds': ['match-w-1', 'match-w-2'],
          },
          {
            'roundNumber': 2,
            'name': 'Ronda 2 (1-0 / 0-1)',
            'status': 'completed',
            'matchIds': ['match-w-3'],
          },
          {
            'roundNumber': 3,
            'name': 'Ronda 3 (2-0 / 1-1 / 0-2)',
            'status': 'in_progress',
            'matchIds': ['match-w-4'],
          },
        ],
        'matches': [
          {
            'id': 'match-w-1',
            'externalId': 'lol-worlds-match-1',
            'roundNumber': 1,
            'roundName': 'Ronda 1',
            'startTime': '2026-10-20T14:00:00.000Z',
            'status': 'FINISHED',
            'homeTeam': {
              'id': 'team-t1',
              'name': 'T1',
              'code': 'T1',
              'logoUrl': 'https://example.com/t1.png',
              'score': 1,
              'record': '1-0',
            },
            'awayTeam': {
              'id': 'team-tes',
              'name': 'Top Esports',
              'code': 'TES',
              'logoUrl': 'https://example.com/tes.png',
              'score': 0,
              'record': '0-1',
            },
            'format': 'Bo1',
            'winnerTeamId': 'team-t1',
          },
          {
            'id': 'match-w-4',
            'externalId': 'lol-worlds-match-4',
            'roundNumber': 3,
            'roundName': 'Ronda 3 (2-0)',
            'startTime': '2026-10-25T18:00:00.000Z',
            'status': 'LIVE',
            'homeTeam': {
              'id': 'team-gen',
              'name': 'Gen.G',
              'code': 'GEN',
              'logoUrl': 'https://example.com/gen.png',
              'score': 1,
              'record': '2-0',
            },
            'awayTeam': {
              'id': 'team-hle',
              'name': 'Hanwha Life Esports',
              'code': 'HLE',
              'logoUrl': 'https://example.com/hle.png',
              'score': 0,
              'record': '2-0',
            },
            'format': 'Bo3',
          },
        ],
        'swissStandings': [
          {
            'position': 1,
            'teamId': 'team-gen',
            'teamName': 'Gen.G',
            'teamCode': 'GEN',
            'teamLogo': 'https://example.com/gen.png',
            'wins': 3,
            'losses': 0,
            'diff': 3,
            'gamesWon': 4,
            'gamesLost': 1,
            'buchholz': 12,
            'advancementStatus': 'QUALIFIED',
            'advancementText': 'Clasificado a Cuartos de Final',
          },
          {
            'position': 2,
            'teamId': 'team-t1',
            'teamName': 'T1',
            'teamCode': 'T1',
            'teamLogo': 'https://example.com/t1.png',
            'wins': 2,
            'losses': 1,
            'diff': 1,
            'gamesWon': 3,
            'gamesLost': 2,
            'buchholz': 9,
            'advancementStatus': 'IN_CONTENTION',
            'advancementText': null,
          },
          {
            'position': 16,
            'teamId': 'team-mad',
            'teamName': 'MAD Lions KOI',
            'teamCode': 'MDK',
            'wins': 0,
            'losses': 3,
            'diff': -3,
            'gamesWon': 0,
            'gamesLost': 4,
            'buchholz': 3,
            'advancementStatus': 'ELIMINATED',
            'advancementText': 'Eliminado',
          },
        ],
        'hasCoverage': true,
        'coverageStatus': 'ACTIVE',
      };

      final model = LolWorldsStageModel.fromJson(jsonFixture);

      expect(model.version, 1);
      expect(model.hasCoverage, true);
      expect(model.coverageStatus, 'ACTIVE');
      expect(model.competition.slug, 'worlds');
      expect(model.season.name, 'Worlds 2026');
      expect(model.season.year, 2026);

      // Etapa
      expect(model.stage, isNotNull);
      expect(model.stage!.name, 'Etapa Suiza');
      expect(model.stage!.isSwiss, true);
      expect(model.stage!.currentRoundNumber, 3);
      expect(model.stage!.totalRounds, 5);

      // Rondas
      expect(model.rounds, hasLength(3));
      expect(model.rounds[0].roundNumber, 1);
      expect(model.rounds[0].matchIds, ['match-w-1', 'match-w-2']);

      // Partidos
      expect(model.matches, hasLength(2));
      expect(model.matches[0].id, 'match-w-1');
      expect(model.matches[0].isFinished, true);
      expect(model.matches[0].homeTeam.score, 1);
      expect(model.matches[0].awayTeam.score, 0);
      expect(model.matches[1].isLive, true);
      expect(model.matches[1].format, 'Bo3');

      // Tabla Suiza y Avance
      expect(model.swissStandings, hasLength(3));
      expect(model.swissStandings[0].record, '3-0');
      expect(model.swissStandings[0].isQualified, true);
      expect(model.swissStandings[0].advancementText, 'Clasificado a Cuartos de Final');
      expect(model.swissStandings[1].isInContention, true);
      expect(model.swissStandings[1].advancementText, isNull);
      expect(model.swissStandings[2].isEliminated, true);
      expect(model.swissStandings[2].advancementText, 'Eliminado');

      // Verificación de serialización de ida y vuelta
      final jsonOutput = model.toJson();
      expect(jsonOutput['version'], 1);
      expect(jsonOutput['hasCoverage'], true);
    });

    test('Parsea etapa sin partidos sin fallar conservando la tabla suiza', () {
      final jsonEmptyMatches = {
        'version': 1,
        'competition': {'slug': 'worlds', 'name': 'Worlds', 'sport': 'lol'},
        'season': {'slug': '2026', 'name': 'Worlds 2026'},
        'stage': {
          'id': 'worlds-swiss',
          'slug': 'swiss',
          'name': 'Etapa Suiza',
          'format': 'swiss',
          'status': 'upcoming',
        },
        'rounds': [],
        'matches': [],
        'swissStandings': [
          {
            'position': 1,
            'teamName': 'Bilibili Gaming',
            'wins': 0,
            'losses': 0,
          },
        ],
        'hasCoverage': true,
        'coverageStatus': 'ACTIVE',
      };

      final model = LolWorldsStageModel.fromJson(jsonEmptyMatches);
      expect(model.hasCoverage, true);
      expect(model.matches, isEmpty);
      expect(model.swissStandings, hasLength(1));
      expect(model.stage!.status, 'upcoming');
    });

    test('Maneja fuente sin credenciales (UNCONFIGURED_CREDENTIALS) como estado no disponible', () {
      final unconfiguredJson = {
        'version': 1,
        'competition': {'slug': 'worlds', 'name': 'Worlds', 'sport': 'lol'},
        'season': {'slug': 'current', 'name': 'Worlds'},
        'stage': null,
        'rounds': [],
        'matches': [],
        'swissStandings': [],
        'hasCoverage': false,
        'coverageStatus': 'UNCONFIGURED_CREDENTIALS',
        'message': 'Requiere credenciales oficiales no configuradas en el entorno.',
      };

      final model = LolWorldsStageModel.fromJson(unconfiguredJson);
      expect(model.hasCoverage, false);
      expect(model.isUnconfigured, true);
      expect(model.isEmpty, true);
      expect(model.message, contains('Requiere credenciales'));
    });

    test('Tolera payloads parciales y campos nulos limpiamente sin lanzar excepciones', () {
      final partialJson = {
        'version': 1,
        'hasCoverage': true,
        'stage': {'name': 'Fase Suiza'},
        'matches': [
          {
            'id': 'partial-1',
            'homeTeam': {'name': 'Team Alpha'},
            'awayTeam': {'name': 'Team Beta'},
          },
        ],
        'swissStandings': [
          {
            'position': 1,
            'teamName': 'Team Alpha',
          },
        ],
      };

      final model = LolWorldsStageModel.fromJson(partialJson);
      expect(model.hasCoverage, true);
      expect(model.stage?.name, 'Fase Suiza');
      expect(model.matches[0].homeTeam.score, isNull);
      expect(model.matches[0].format, 'Bo1');
      expect(model.swissStandings[0].wins, 0);
      expect(model.swissStandings[0].losses, 0);
      expect(model.swissStandings[0].advancementStatus, isNull);
    });

    test('empty() crea modelo seguro de respaldo sin inventar datos', () {
      final empty = LolWorldsStageModel.empty(
        message: 'No disponible',
        coverageStatus: 'PROVIDER_ERROR',
      );

      expect(empty.hasCoverage, false);
      expect(empty.isProviderError, true);
      expect(empty.stage, isNull);
      expect(empty.rounds, isEmpty);
      expect(empty.matches, isEmpty);
      expect(empty.swissStandings, isEmpty);
    });
  });
}
