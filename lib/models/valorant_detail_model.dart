/// Estado de un mapa individual dentro de una serie de Valorant.
enum ValorantMapStatus {
  scheduled,
  live,
  finished;

  static ValorantMapStatus fromString(String? value) {
    if (value == null) return ValorantMapStatus.scheduled;
    switch (value.trim().toLowerCase()) {
      case 'live':
      case 'in_game':
      case 'en_vivo':
      case 'en_juego':
        return ValorantMapStatus.live;
      case 'finished':
      case 'completed':
      case 'finalizada':
      case 'finalizado':
        return ValorantMapStatus.finished;
      case 'scheduled':
      case 'upcoming':
      case 'programada':
      case 'programado':
      default:
        return ValorantMapStatus.scheduled;
    }
  }

  String get displayName {
    switch (this) {
      case ValorantMapStatus.live:
        return 'EN VIVO';
      case ValorantMapStatus.finished:
        return 'FINALIZADO';
      case ValorantMapStatus.scheduled:
        return 'PROGRAMADO';
    }
  }
}

/// Contrato opcional v1 en EsportsStats.extraStats.detail para Valorant.
/// Documentado en docs/valorant-detail-contract.md.
class ValorantDetailModel {
  final int version;
  final String homeParticipantId;
  final String awayParticipantId;
  final String? format;
  final int? activeMapNumber;
  final List<ValorantMapDetail> maps;

  const ValorantDetailModel({
    this.version = 1,
    required this.homeParticipantId,
    required this.awayParticipantId,
    this.format,
    this.activeMapNumber,
    required this.maps,
  });

  /// Formato legible de la serie (ej. "Al mejor de 3", "Al mejor de 5", "Partida única").
  /// Si el formato es desconocido o nulo, retorna null para no inventar supuestos.
  String? get formatDisplayName {
    if (format == null || format!.trim().isEmpty) return null;
    final clean = format!.trim().toLowerCase();
    if (clean == 'bo1') return 'Partida única';
    if (clean == 'bo3') return 'Al mejor de 3';
    if (clean == 'bo5') return 'Al mejor de 5';
    if (clean == 'bo2') return 'Al mejor de 2';
    if (clean.startsWith('bo')) {
      final numStr = clean.replaceFirst('bo', '');
      return 'Al mejor de $numStr';
    }
    return format;
  }

  /// Retorna el mapa activo según el campo explícito, el que esté en vivo,
  /// o el último finalizado (o el primero si aún no comienza ninguno).
  ValorantMapDetail? get activeMap {
    if (maps.isEmpty) return null;
    if (activeMapNumber != null) {
      final found = maps.where((m) => m.mapNumber == activeMapNumber).firstOrNull;
      if (found != null) return found;
    }
    final live = maps.where((m) => m.status == ValorantMapStatus.live).firstOrNull;
    if (live != null) return live;
    final finished = maps.where((m) => m.status == ValorantMapStatus.finished).lastOrNull;
    if (finished != null) return finished;
    return maps.first;
  }

  ValorantMapDetail? mapByNumber(int number) {
    return maps.where((m) => m.mapNumber == number).firstOrNull;
  }

  static ValorantDetailModel? parse(Object? value) {
    if (value is! Map<String, dynamic> || value['version'] != 1) return null;
    final home = _text(value['homeParticipantId']);
    final away = _text(value['awayParticipantId']);
    if (home == null || away == null || home == away) return null;

    final rawMaps = value['maps'];
    final mapsList = <ValorantMapDetail>[];
    if (rawMaps is List) {
      for (final item in rawMaps) {
        if (item is Map<String, dynamic>) {
          final parsed = ValorantMapDetail.fromJson(item);
          if (parsed != null) mapsList.add(parsed);
        }
      }
    }

    return ValorantDetailModel(
      version: 1,
      homeParticipantId: home,
      awayParticipantId: away,
      format: _text(value['format']),
      activeMapNumber: _int(value['activeMapNumber']),
      maps: mapsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'homeParticipantId': homeParticipantId,
      'awayParticipantId': awayParticipantId,
      if (format != null) 'format': format,
      if (activeMapNumber != null) 'activeMapNumber': activeMapNumber,
      'maps': maps.map((m) => m.toJson()).toList(),
    };
  }
}

/// Detalle de un mapa individual en una serie de Valorant.
class ValorantMapDetail {
  final int mapNumber;
  final String mapName;
  final ValorantMapStatus status;
  final String? duration;
  final String? winnerParticipantId;
  final int? homeScore;
  final int? awayScore;
  final int? currentRound;
  final String? homeSide;
  final String? awaySide;
  final List<ValorantRoundDetail>? rounds;
  final ValorantMapStats? stats;
  final List<ValorantPlayerStats>? homePlayers;
  final List<ValorantPlayerStats>? awayPlayers;

  const ValorantMapDetail({
    required this.mapNumber,
    required this.mapName,
    required this.status,
    this.duration,
    this.winnerParticipantId,
    this.homeScore,
    this.awayScore,
    this.currentRound,
    this.homeSide,
    this.awaySide,
    this.rounds,
    this.stats,
    this.homePlayers,
    this.awayPlayers,
  });

  bool get isLive => status == ValorantMapStatus.live;
  bool get isFinished => status == ValorantMapStatus.finished;
  bool get isScheduled => status == ValorantMapStatus.scheduled;

  bool get hasScore => homeScore != null && awayScore != null;

  String? get scoreString => hasScore ? '$homeScore — $awayScore' : null;

  /// Retorna las últimas 6 rondas disputadas para el carrusel de historial.
  List<ValorantRoundDetail> get recentRounds {
    if (rounds == null || rounds!.isEmpty) return const [];
    if (rounds!.length <= 6) return rounds!;
    return rounds!.sublist(rounds!.length - 6);
  }

  static ValorantMapDetail? fromJson(Map<String, dynamic> json) {
    final num = _int(json['mapNumber'] ?? json['gameNumber']);
    final name = _text(json['mapName'] ?? json['map'] ?? json['name']);
    if (num == null) return null;

    final rawStatus = _text(json['status']);
    ValorantMapStatus status;
    if (rawStatus != null) {
      status = ValorantMapStatus.fromString(rawStatus);
    } else if (json['winnerParticipantId'] != null) {
      status = ValorantMapStatus.finished;
    } else if (json['currentRound'] != null || json['homeScore'] != null || json['awayScore'] != null) {
      status = ValorantMapStatus.live;
    } else {
      status = ValorantMapStatus.scheduled;
    }

    final rawRounds = json['rounds'];
    List<ValorantRoundDetail>? roundsList;
    if (rawRounds is List) {
      roundsList = [];
      for (final r in rawRounds) {
        if (r is Map<String, dynamic>) {
          final parsed = ValorantRoundDetail.fromJson(r);
          if (parsed != null) roundsList.add(parsed);
        }
      }
    }

    final stats = json['stats'] is Map<String, dynamic>
        ? ValorantMapStats.fromJson(json['stats'] as Map<String, dynamic>)
        : null;

    final homePlayers = _parsePlayers(json['homePlayers'] ?? json['home_players']);
    final awayPlayers = _parsePlayers(json['awayPlayers'] ?? json['away_players']);

    return ValorantMapDetail(
      mapNumber: num,
      mapName: name ?? 'Mapa $num',
      status: status,
      duration: _text(json['duration'] ?? json['durationString']),
      winnerParticipantId: _text(json['winnerParticipantId'] ?? json['winner_participant_id']),
      homeScore: _int(json['homeScore'] ?? json['home_score'] ?? json['homeRounds']),
      awayScore: _int(json['awayScore'] ?? json['away_score'] ?? json['awayRounds']),
      currentRound: _int(json['currentRound'] ?? json['current_round']),
      homeSide: _text(json['homeSide'] ?? json['home_side']),
      awaySide: _text(json['awaySide'] ?? json['away_side']),
      rounds: roundsList,
      stats: stats,
      homePlayers: homePlayers,
      awayPlayers: awayPlayers,
    );
  }

  static List<ValorantPlayerStats>? _parsePlayers(Object? raw) {
    if (raw is! List) return null;
    final list = <ValorantPlayerStats>[];
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        final parsed = ValorantPlayerStats.fromJson(item);
        if (parsed != null) list.add(parsed);
      }
    }
    return list.isEmpty ? null : list;
  }

  Map<String, dynamic> toJson() {
    return {
      'mapNumber': mapNumber,
      'mapName': mapName,
      'status': status.name,
      if (duration != null) 'duration': duration,
      if (winnerParticipantId != null) 'winnerParticipantId': winnerParticipantId,
      if (homeScore != null) 'homeScore': homeScore,
      if (awayScore != null) 'awayScore': awayScore,
      if (currentRound != null) 'currentRound': currentRound,
      if (homeSide != null) 'homeSide': homeSide,
      if (awaySide != null) 'awaySide': awaySide,
      if (rounds != null) 'rounds': rounds!.map((r) => r.toJson()).toList(),
      if (stats != null) 'stats': stats!.toJson(),
      if (homePlayers != null) 'homePlayers': homePlayers!.map((p) => p.toJson()).toList(),
      if (awayPlayers != null) 'awayPlayers': awayPlayers!.map((p) => p.toJson()).toList(),
    };
  }
}

/// Registro de una ronda individual disputada en el mapa.
class ValorantRoundDetail {
  final int roundNumber;
  final String winnerParticipantId;
  final String? winType;
  final String? winningSide;

  const ValorantRoundDetail({
    required this.roundNumber,
    required this.winnerParticipantId,
    this.winType,
    this.winningSide,
  });

  static ValorantRoundDetail? fromJson(Map<String, dynamic> json) {
    final num = _int(json['roundNumber'] ?? json['round_number'] ?? json['round']);
    final winner = _text(json['winnerParticipantId'] ?? json['winner_participant_id'] ?? json['winner']);
    if (num == null || winner == null) return null;

    return ValorantRoundDetail(
      roundNumber: num,
      winnerParticipantId: winner,
      winType: _text(json['winType'] ?? json['win_type']),
      winningSide: _text(json['winningSide'] ?? json['winning_side']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roundNumber': roundNumber,
      'winnerParticipantId': winnerParticipantId,
      if (winType != null) 'winType': winType,
      if (winningSide != null) 'winningSide': winningSide,
    };
  }
}

/// Métricas comparativas del mapa en disputa.
class ValorantMapStats {
  final int? homeFirstBloods;
  final int? awayFirstBloods;
  final int? homePlants;
  final int? awayPlants;
  final int? homeDefuses;
  final int? awayDefuses;

  const ValorantMapStats({
    this.homeFirstBloods,
    this.awayFirstBloods,
    this.homePlants,
    this.awayPlants,
    this.homeDefuses,
    this.awayDefuses,
  });

  bool get hasFirstBloods => homeFirstBloods != null && awayFirstBloods != null;
  bool get hasPlants => homePlants != null && awayPlants != null;
  bool get hasDefuses => homeDefuses != null && awayDefuses != null;

  bool get hasAnyMetric => hasFirstBloods || hasPlants || hasDefuses;

  static ValorantMapStats? fromJson(Map<String, dynamic> json) {
    final hFb = _int(json['homeFirstBloods'] ?? json['home_first_bloods'] ?? json['homeFirstKills']);
    final aFb = _int(json['awayFirstBloods'] ?? json['away_first_bloods'] ?? json['awayFirstKills']);
    final hPl = _int(json['homePlants'] ?? json['home_plants'] ?? json['homeSpikePlants']);
    final aPl = _int(json['awayPlants'] ?? json['away_plants'] ?? json['awaySpikePlants']);
    final hDf = _int(json['homeDefuses'] ?? json['home_defuses'] ?? json['homeSpikeDefuses']);
    final aDf = _int(json['awayDefuses'] ?? json['away_defuses'] ?? json['awaySpikeDefuses']);

    if (hFb == null && aFb == null && hPl == null && aPl == null && hDf == null && aDf == null) {
      return null;
    }

    return ValorantMapStats(
      homeFirstBloods: hFb,
      awayFirstBloods: aFb,
      homePlants: hPl,
      awayPlants: aPl,
      homeDefuses: hDf,
      awayDefuses: aDf,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (homeFirstBloods != null) 'homeFirstBloods': homeFirstBloods,
      if (awayFirstBloods != null) 'awayFirstBloods': awayFirstBloods,
      if (homePlants != null) 'homePlants': homePlants,
      if (awayPlants != null) 'awayPlants': awayPlants,
      if (homeDefuses != null) 'homeDefuses': homeDefuses,
      if (awayDefuses != null) 'awayDefuses': awayDefuses,
    };
  }
}

/// Estadísticas individuales de un jugador en el mapa de Valorant.
class ValorantPlayerStats {
  final String name;
  final String? agent;
  final String? role;
  final int? combatScore;
  final int? kills;
  final int? deaths;
  final int? assists;
  final int? firstKills;
  final int? plants;
  final int? defuses;
  final double? rating;

  const ValorantPlayerStats({
    required this.name,
    this.agent,
    this.role,
    this.combatScore,
    this.kills,
    this.deaths,
    this.assists,
    this.firstKills,
    this.plants,
    this.defuses,
    this.rating,
  });

  bool get hasKda => kills != null && deaths != null && assists != null;

  String get kdaString {
    if (!hasKda) return '-';
    return '$kills / $deaths / $assists';
  }

  double? get kdaRatio {
    if (kills == null || deaths == null) return null;
    final a = assists ?? 0;
    final d = deaths == 0 ? 1 : deaths!;
    return (kills! + a) / d;
  }

  String? get acsDisplay => combatScore != null ? '$combatScore ACS' : null;

  static ValorantPlayerStats? fromJson(Map<String, dynamic> json) {
    final name = _text(json['name'] ?? json['player']);
    if (name == null) return null;

    return ValorantPlayerStats(
      name: name,
      agent: _text(json['agent'] ?? json['character']),
      role: _text(json['role']),
      combatScore: _int(json['combatScore'] ?? json['combat_score'] ?? json['acs']),
      kills: _int(json['kills']),
      deaths: _int(json['deaths']),
      assists: _int(json['assists']),
      firstKills: _int(json['firstKills'] ?? json['first_kills'] ?? json['firstBloods']),
      plants: _int(json['plants'] ?? json['spike_plants']),
      defuses: _int(json['defuses'] ?? json['spike_defuses']),
      rating: _double(json['rating']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (agent != null) 'agent': agent,
      if (role != null) 'role': role,
      if (combatScore != null) 'combatScore': combatScore,
      if (kills != null) 'kills': kills,
      if (deaths != null) 'deaths': deaths,
      if (assists != null) 'assists': assists,
      if (firstKills != null) 'firstKills': firstKills,
      if (plants != null) 'plants': plants,
      if (defuses != null) 'defuses': defuses,
      if (rating != null) 'rating': rating,
    };
  }
}

String? _text(Object? value) {
  if (value == null) return null;
  final str = value.toString().trim();
  return str.isEmpty ? null : str;
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value == null) return null;
  return int.tryParse(value.toString().trim());
}

double? _double(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value == null) return null;
  return double.tryParse(value.toString().trim());
}
