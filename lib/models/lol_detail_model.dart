/// Estado de una partida individual dentro de una serie de LoL.
enum LolGameStatus {
  scheduled,
  live,
  finished;

  static LolGameStatus fromString(String? value) {
    if (value == null) return LolGameStatus.scheduled;
    switch (value.trim().toLowerCase()) {
      case 'live':
      case 'in_game':
      case 'en_vivo':
      case 'en_juego':
        return LolGameStatus.live;
      case 'finished':
      case 'completed':
      case 'finalizada':
      case 'finalizado':
        return LolGameStatus.finished;
      case 'scheduled':
      case 'upcoming':
      case 'programada':
      case 'programado':
      default:
        return LolGameStatus.scheduled;
    }
  }

  String get displayName {
    switch (this) {
      case LolGameStatus.live:
        return 'EN VIVO';
      case LolGameStatus.finished:
        return 'FINALIZADA';
      case LolGameStatus.scheduled:
        return 'PROGRAMADA';
    }
  }
}

/// Contrato opcional v1 en EsportsStats.extraStats.detail para League of Legends.
/// Documentado en docs/lol-detail-contract.md.
class LolDetailModel {
  final int version;
  final String homeParticipantId;
  final String awayParticipantId;
  final String? format;
  final int? activeGameNumber;
  final List<LolGameDetail> games;

  const LolDetailModel({
    this.version = 1,
    required this.homeParticipantId,
    required this.awayParticipantId,
    this.format,
    this.activeGameNumber,
    required this.games,
  });

  /// Formato legible de la serie (ej. "Serie al mejor de 3", "Serie al mejor de 5", "Partida única").
  /// Si el formato es desconocido o nulo, retorna null para no inventar supuestos.
  String? get formatDisplayName {
    if (format == null || format!.trim().isEmpty) return null;
    final clean = format!.trim().toLowerCase();
    if (clean == 'bo1') return 'Partida única';
    if (clean == 'bo3') return 'Serie al mejor de 3';
    if (clean == 'bo5') return 'Serie al mejor de 5';
    if (clean == 'bo2') return 'Serie al mejor de 2';
    if (clean.startsWith('bo')) {
      final numStr = clean.replaceFirst('bo', '');
      return 'Serie al mejor de $numStr';
    }
    return format;
  }

  /// Retorna la partida activa según el campo explícito, la que esté en vivo,
  /// o la última finalizada (o la primera si aún no comienza ninguna).
  LolGameDetail? get activeGame {
    if (games.isEmpty) return null;
    if (activeGameNumber != null) {
      final found = games.where((g) => g.gameNumber == activeGameNumber).firstOrNull;
      if (found != null) return found;
    }
    final live = games.where((g) => g.status == LolGameStatus.live).firstOrNull;
    if (live != null) return live;
    final finished = games.where((g) => g.status == LolGameStatus.finished).lastOrNull;
    if (finished != null) return finished;
    return games.first;
  }

  LolGameDetail? gameByNumber(int number) {
    return games.where((g) => g.gameNumber == number).firstOrNull;
  }

  static LolDetailModel? parse(Object? value) {
    if (value is! Map<String, dynamic> || value['version'] != 1) return null;
    final home = _text(value['homeParticipantId']);
    final away = _text(value['awayParticipantId']);
    if (home == null || away == null || home == away) return null;

    final rawGames = value['games'] is List
        ? (value['games'] as List)
            .whereType<Map<String, dynamic>>()
            .map(LolGameDetail.parse)
            .whereType<LolGameDetail>()
            .toList()
        : <LolGameDetail>[];

    // Ordenar partidas por número
    rawGames.sort((a, b) => a.gameNumber.compareTo(b.gameNumber));

    return LolDetailModel(
      version: 1,
      homeParticipantId: home,
      awayParticipantId: away,
      format: _text(value['format']),
      activeGameNumber: _toInt(value['activeGameNumber'] ?? value['currentMapNumber']),
      games: rawGames,
    );
  }
}

/// Detalle individual de cada mapa / partida en la serie de LoL.
class LolGameDetail {
  final int gameNumber;
  final LolGameStatus status;
  final String mapName;
  final String? duration;
  final String? winnerParticipantId;
  final int? homeKills;
  final int? awayKills;
  final LolGameObjectives? objectives;
  final List<LolPlayerStats>? homePlayers;
  final List<LolPlayerStats>? awayPlayers;

  const LolGameDetail({
    required this.gameNumber,
    required this.status,
    this.mapName = 'Grieta del Invocador',
    this.duration,
    this.winnerParticipantId,
    this.homeKills,
    this.awayKills,
    this.objectives,
    this.homePlayers,
    this.awayPlayers,
  });

  bool get isFinished => status == LolGameStatus.finished;
  bool get isLive => status == LolGameStatus.live;
  bool get isScheduled => status == LolGameStatus.scheduled;

  static LolGameDetail? parse(Map<String, dynamic> json) {
    final gameNum = _toInt(json['gameNumber'] ?? json['mapNumber'] ?? json['number']);
    if (gameNum == null || gameNum <= 0) return null;

    final winner = _text(json['winnerParticipantId'] ?? json['winner']);
    LolGameStatus status = LolGameStatus.fromString(_text(json['status']));

    // Deducir status si no vino explícito
    if (json['status'] == null) {
      if (winner != null) {
        status = LolGameStatus.finished;
      } else if (json['duration'] != null || json['homeKills'] != null || json['awayKills'] != null) {
        status = LolGameStatus.live;
      } else {
        status = LolGameStatus.scheduled;
      }
    }

    final homePlayersList = json['homePlayers'] is List
        ? (json['homePlayers'] as List)
            .whereType<Map<String, dynamic>>()
            .map(LolPlayerStats.parse)
            .whereType<LolPlayerStats>()
            .toList()
        : null;

    final awayPlayersList = json['awayPlayers'] is List
        ? (json['awayPlayers'] as List)
            .whereType<Map<String, dynamic>>()
            .map(LolPlayerStats.parse)
            .whereType<LolPlayerStats>()
            .toList()
        : null;

    return LolGameDetail(
      gameNumber: gameNum,
      status: status,
      mapName: _text(json['mapName']) ?? 'Grieta del Invocador',
      duration: _text(json['duration']),
      winnerParticipantId: winner,
      homeKills: _scoreInt(json['homeKills'] ?? json['homeScore']),
      awayKills: _scoreInt(json['awayKills'] ?? json['awayScore']),
      objectives: LolGameObjectives.parse(json['objectives']),
      homePlayers: homePlayersList,
      awayPlayers: awayPlayersList,
    );
  }
}

/// Objetivos y recursos por partida en League of Legends.
/// Solo se muestran en la interfaz si existen datos reportados por la fuente.
class LolGameObjectives {
  final double? homeGold;
  final double? awayGold;
  final String? homeGoldFormatted;
  final String? awayGoldFormatted;
  final int? homeTowers;
  final int? awayTowers;
  final int? homeDragons;
  final int? awayDragons;
  final int? homeBarons;
  final int? awayBarons;

  const LolGameObjectives({
    this.homeGold,
    this.awayGold,
    this.homeGoldFormatted,
    this.awayGoldFormatted,
    this.homeTowers,
    this.awayTowers,
    this.homeDragons,
    this.awayDragons,
    this.homeBarons,
    this.awayBarons,
  });

  bool get hasGold => (homeGold != null || homeGoldFormatted != null) &&
      (awayGold != null || awayGoldFormatted != null);

  bool get hasTowers => homeTowers != null && awayTowers != null;
  bool get hasDragons => homeDragons != null && awayDragons != null;
  bool get hasBarons => homeBarons != null && awayBarons != null;

  bool get hasAny => hasGold || hasTowers || hasDragons || hasBarons;

  String displayHomeGold() {
    if (homeGoldFormatted != null && homeGoldFormatted!.isNotEmpty) {
      return homeGoldFormatted!;
    }
    return _formatGold(homeGold);
  }

  String displayAwayGold() {
    if (awayGoldFormatted != null && awayGoldFormatted!.isNotEmpty) {
      return awayGoldFormatted!;
    }
    return _formatGold(awayGold);
  }

  static String _formatGold(double? gold) {
    if (gold == null) return '—';
    if (gold >= 1000) {
      final k = gold / 1000.0;
      final fixed = k.toStringAsFixed(1).replaceAll('.', ',');
      return '$fixed mil';
    }
    // Si viene en unidades de mil ya (ej. 45.2)
    if (gold > 0 && gold < 200) {
      final fixed = gold.toStringAsFixed(1).replaceAll('.', ',');
      return '$fixed mil';
    }
    return gold.toInt().toString();
  }

  static LolGameObjectives? parse(Object? value) {
    if (value is! Map<String, dynamic>) return null;

    double? parseGold(Object? raw) {
      if (raw == null) return null;
      if (raw is num) return raw.toDouble();
      final str = raw.toString().replaceAll('k', '').replaceAll('mil', '').replaceAll(',', '.').trim();
      return double.tryParse(str);
    }

    final hGold = parseGold(value['homeGold']);
    final aGold = parseGold(value['awayGold']);

    return LolGameObjectives(
      homeGold: hGold,
      awayGold: aGold,
      homeGoldFormatted: _text(value['homeGoldFormatted']),
      awayGoldFormatted: _text(value['awayGoldFormatted']),
      homeTowers: _scoreInt(value['homeTowers']),
      awayTowers: _scoreInt(value['awayTowers']),
      homeDragons: _scoreInt(value['homeDragons']),
      awayDragons: _scoreInt(value['awayDragons']),
      homeBarons: _scoreInt(value['homeBarons']),
      awayBarons: _scoreInt(value['awayBarons']),
    );
  }
}

/// Estadísticas individuales de un jugador en una partida de LoL.
class LolPlayerStats {
  final String name;
  final String? champion;
  final String? role; // TOP, JGL, MID, ADC, SUP
  final int? kills;
  final int? deaths;
  final int? assists;
  final int? cs;
  final double? gold;

  const LolPlayerStats({
    required this.name,
    this.champion,
    this.role,
    this.kills,
    this.deaths,
    this.assists,
    this.cs,
    this.gold,
  });

  String get kdaString {
    final k = kills != null ? '$kills' : '—';
    final d = deaths != null ? '$deaths' : '—';
    final a = assists != null ? '$assists' : '—';
    return '$k / $d / $a';
  }

  String? get kdaRatio {
    if (kills == null || deaths == null || assists == null) return null;
    final d = deaths == 0 ? 1 : deaths!;
    final ratio = (kills! + assists!) / d;
    return ratio.toStringAsFixed(1);
  }

  static LolPlayerStats? parse(Map<String, dynamic> json) {
    final name = _text(json['name']);
    if (name == null) return null;

    double? parseGold(Object? raw) {
      if (raw == null) return null;
      if (raw is num) return raw.toDouble();
      final str = raw.toString().replaceAll('k', '').replaceAll('mil', '').replaceAll(',', '.').trim();
      return double.tryParse(str);
    }

    return LolPlayerStats(
      name: name,
      champion: _text(json['champion']),
      role: _text(json['role'])?.toUpperCase(),
      kills: _scoreInt(json['kills']),
      deaths: _scoreInt(json['deaths']),
      assists: _scoreInt(json['assists']),
      cs: _scoreInt(json['cs']),
      gold: parseGold(json['gold']),
    );
  }
}

String? _text(Object? value) {
  if (value is! String && value is! num) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _toInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString().trim());
}

int? _scoreInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value >= 0 ? value : null;
  final n = int.tryParse(value.toString().trim());
  return n != null && n >= 0 ? n : null;
}
