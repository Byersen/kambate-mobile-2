import 'event_model.dart';
import 'event_status.dart';
import 'sport_type.dart';

/// Segmento de la cartelera de UFC.
enum UfcCardSegment {
  mainCard,
  prelims,
  earlyPrelims;

  static UfcCardSegment fromString(String? value) {
    if (value == null) return UfcCardSegment.mainCard;
    switch (value.trim().toLowerCase()) {
      case 'main':
      case 'main_card':
      case 'principal':
      case 'cartelera principal':
        return UfcCardSegment.mainCard;
      case 'prelims':
      case 'preliminares':
      case 'prelim':
        return UfcCardSegment.prelims;
      case 'early_prelims':
      case 'primeras_preliminares':
      case 'primeras preliminares':
        return UfcCardSegment.earlyPrelims;
      default:
        return UfcCardSegment.mainCard;
    }
  }

  String get displayName {
    switch (this) {
      case UfcCardSegment.mainCard:
        return 'Cartelera principal';
      case UfcCardSegment.prelims:
        return 'Preliminares';
      case UfcCardSegment.earlyPrelims:
        return 'Primeras preliminares';
    }
  }
}

/// Estado individual de un combate de UFC.
enum UfcFightStatus {
  scheduled,
  live,
  finished,
  canceled;

  static UfcFightStatus fromString(String? value) {
    if (value == null) return UfcFightStatus.scheduled;
    switch (value.trim().toLowerCase()) {
      case 'live':
      case 'in':
      case 'en_vivo':
      case 'en vivo':
        return UfcFightStatus.live;
      case 'finished':
      case 'post':
      case 'finalizado':
      case 'finalizada':
      case 'completed':
        return UfcFightStatus.finished;
      case 'canceled':
      case 'cancelled':
      case 'cancelado':
        return UfcFightStatus.canceled;
      case 'scheduled':
      case 'pre':
      case 'programado':
      default:
        return UfcFightStatus.scheduled;
    }
  }

  String get displayName {
    switch (this) {
      case UfcFightStatus.live:
        return 'EN VIVO';
      case UfcFightStatus.finished:
        return 'FINALIZADO';
      case UfcFightStatus.canceled:
        return 'CANCELADO';
      case UfcFightStatus.scheduled:
        return 'PROGRAMADO';
    }
  }
}

/// Estado general de la velada / cartelera UFC.
enum UfcCardStatus {
  scheduled,
  live,
  finished;

  static UfcCardStatus fromString(String? value) {
    if (value == null) return UfcCardStatus.scheduled;
    switch (value.trim().toLowerCase()) {
      case 'live':
      case 'in':
      case 'en_curso':
      case 'en curso':
      case 'evento en curso':
        return UfcCardStatus.live;
      case 'finished':
      case 'post':
      case 'finalizado':
      case 'finalizada':
        return UfcCardStatus.finished;
      case 'scheduled':
      case 'pre':
      case 'programado':
      default:
        return UfcCardStatus.scheduled;
    }
  }

  String get displayName {
    switch (this) {
      case UfcCardStatus.live:
        return 'EVENTO EN CURSO';
      case UfcCardStatus.finished:
        return 'FINALIZADO';
      case UfcCardStatus.scheduled:
        return 'PROGRAMADO';
    }
  }
}

/// Datos de un contendiente de UFC.
class UfcFighterModel {
  final String id;
  final String name;
  final String? nickname;
  final String? photoUrl;
  final String? record;
  final String? country;
  final String? ranking;
  final String? corner;

  const UfcFighterModel({
    required this.id,
    required this.name,
    this.nickname,
    this.photoUrl,
    this.record,
    this.country,
    this.ranking,
    this.corner,
  });

  String get displayName => nickname != null && nickname!.trim().isNotEmpty
      ? '$name "$nickname"'
      : name;

  factory UfcFighterModel.fromJson(Map<String, dynamic> json) {
    return UfcFighterModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Peleador',
      nickname: json['nickname']?.toString(),
      photoUrl: json['photo_url']?.toString() ?? json['photoUrl']?.toString(),
      record: json['record']?.toString(),
      country: json['country']?.toString(),
      ranking: json['ranking']?.toString(),
      corner: json['corner']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (nickname != null) 'nickname': nickname,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (record != null) 'record': record,
      if (country != null) 'country': country,
      if (ranking != null) 'ranking': ranking,
      if (corner != null) 'corner': corner,
    };
  }
}

/// Resultado oficial y confirmado de un combate.
class UfcFightResultModel {
  final String? winnerId;
  final String? winnerName;
  final String? method;
  final String? methodDetail;
  final int? round;
  final String? time;

  const UfcFightResultModel({
    this.winnerId,
    this.winnerName,
    this.method,
    this.methodDetail,
    this.round,
    this.time,
  });

  /// Texto conciso para la cartelera y resúmenes.
  /// Ej: "Ganó Topuria • KO/TKO • A2 • 01:48" o "Ganó Torres • Decisión unánime"
  String formattedSummary({String? fallbackWinner}) {
    final winner = winnerName ?? fallbackWinner ?? 'Ganador';
    final parts = <String>[];
    parts.add('Ganó $winner');

    if (method != null && method!.trim().isNotEmpty) {
      parts.add(method!.trim());
    }
    if (round != null && round! > 0) {
      parts.add('A$round');
    }
    if (time != null && time!.trim().isNotEmpty) {
      parts.add(time!.trim());
    }
    return parts.join(' • ');
  }

  factory UfcFightResultModel.fromJson(Map<String, dynamic> json) {
    return UfcFightResultModel(
      winnerId: json['winner_id']?.toString() ?? json['winnerId']?.toString(),
      winnerName:
          json['winner_name']?.toString() ?? json['winnerName']?.toString(),
      method: json['method']?.toString(),
      methodDetail: json['method_detail']?.toString() ??
          json['methodDetail']?.toString(),
      round: json['round'] is int
          ? json['round'] as int
          : int.tryParse(json['round']?.toString() ?? ''),
      time: json['time']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (winnerId != null) 'winnerId': winnerId,
      if (winnerName != null) 'winnerName': winnerName,
      if (method != null) 'method': method,
      if (methodDetail != null) 'methodDetail': methodDetail,
      if (round != null) 'round': round,
      if (time != null) 'time': time,
    };
  }
}

/// Comparativa física o Tale of the Tape.
class UfcTaleOfTheTapeModel {
  final String? division;
  final String? record1;
  final String? record2;
  final String? height1;
  final String? height2;
  final String? reach1;
  final String? reach2;
  final String? stance1;
  final String? stance2;
  final String? age1;
  final String? age2;

  const UfcTaleOfTheTapeModel({
    this.division,
    this.record1,
    this.record2,
    this.height1,
    this.height2,
    this.reach1,
    this.reach2,
    this.stance1,
    this.stance2,
    this.age1,
    this.age2,
  });

  bool get hasAnyData =>
      (division != null && division!.trim().isNotEmpty) ||
      (record1 != null && record1!.trim().isNotEmpty) ||
      (height1 != null && height1!.trim().isNotEmpty) ||
      (reach1 != null && reach1!.trim().isNotEmpty) ||
      (stance1 != null && stance1!.trim().isNotEmpty) ||
      (age1 != null && age1!.trim().isNotEmpty);

  factory UfcTaleOfTheTapeModel.fromJson(Map<String, dynamic> json) {
    return UfcTaleOfTheTapeModel(
      division: json['division']?.toString(),
      record1: json['record1']?.toString(),
      record2: json['record2']?.toString(),
      height1: json['height1']?.toString(),
      height2: json['height2']?.toString(),
      reach1: json['reach1']?.toString(),
      reach2: json['reach2']?.toString(),
      stance1: json['stance1']?.toString(),
      stance2: json['stance2']?.toString(),
      age1: json['age1']?.toString(),
      age2: json['age2']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (division != null) 'division': division,
      if (record1 != null) 'record1': record1,
      if (record2 != null) 'record2': record2,
      if (height1 != null) 'height1': height1,
      if (height2 != null) 'height2': height2,
      if (reach1 != null) 'reach1': reach1,
      if (reach2 != null) 'reach2': reach2,
      if (stance1 != null) 'stance1': stance1,
      if (stance2 != null) 'stance2': stance2,
      if (age1 != null) 'age1': age1,
      if (age2 != null) 'age2': age2,
    };
  }
}

/// Estadísticas por asalto individual.
class UfcRoundStatsModel {
  final int roundNumber;
  final String? homeSigStrikes;
  final String? awaySigStrikes;
  final String? homeTotalStrikes;
  final String? awayTotalStrikes;
  final String? homeTakedowns;
  final String? awayTakedowns;
  final String? homeControlTime;
  final String? awayControlTime;

  const UfcRoundStatsModel({
    required this.roundNumber,
    this.homeSigStrikes,
    this.awaySigStrikes,
    this.homeTotalStrikes,
    this.awayTotalStrikes,
    this.homeTakedowns,
    this.awayTakedowns,
    this.homeControlTime,
    this.awayControlTime,
  });

  factory UfcRoundStatsModel.fromJson(Map<String, dynamic> json) {
    return UfcRoundStatsModel(
      roundNumber: json['roundNumber'] is int
          ? json['roundNumber'] as int
          : (int.tryParse(json['roundNumber']?.toString() ?? '1') ?? 1),
      homeSigStrikes: json['homeSigStrikes']?.toString(),
      awaySigStrikes: json['awaySigStrikes']?.toString(),
      homeTotalStrikes: json['homeTotalStrikes']?.toString(),
      awayTotalStrikes: json['awayTotalStrikes']?.toString(),
      homeTakedowns: json['homeTakedowns']?.toString(),
      awayTakedowns: json['awayTakedowns']?.toString(),
      homeControlTime: json['homeControlTime']?.toString(),
      awayControlTime: json['awayControlTime']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roundNumber': roundNumber,
      if (homeSigStrikes != null) 'homeSigStrikes': homeSigStrikes,
      if (awaySigStrikes != null) 'awaySigStrikes': awaySigStrikes,
      if (homeTotalStrikes != null) 'homeTotalStrikes': homeTotalStrikes,
      if (awayTotalStrikes != null) 'awayTotalStrikes': awayTotalStrikes,
      if (homeTakedowns != null) 'homeTakedowns': homeTakedowns,
      if (awayTakedowns != null) 'awayTakedowns': awayTakedowns,
      if (homeControlTime != null) 'homeControlTime': homeControlTime,
      if (awayControlTime != null) 'awayControlTime': awayControlTime,
    };
  }
}

/// Estadísticas consolidadas del combate.
class UfcFightStatsModel {
  final String? homeSigStrikes;
  final String? awaySigStrikes;
  final double? homeSigStrikeRatio;
  final String? homeSigStrikePct;
  final String? awaySigStrikePct;
  final double? homeSigStrikePctRatio;
  final String? homeTakedowns;
  final String? awayTakedowns;
  final double? homeTakedownRatio;
  final String? homeSubAttempts;
  final String? awaySubAttempts;
  final double? homeSubAttemptRatio;
  final String? homeControlTime;
  final String? awayControlTime;
  final double? homeControlRatio;
  final List<UfcRoundStatsModel> rounds;

  const UfcFightStatsModel({
    this.homeSigStrikes,
    this.awaySigStrikes,
    this.homeSigStrikeRatio,
    this.homeSigStrikePct,
    this.awaySigStrikePct,
    this.homeSigStrikePctRatio,
    this.homeTakedowns,
    this.awayTakedowns,
    this.homeTakedownRatio,
    this.homeSubAttempts,
    this.awaySubAttempts,
    this.homeSubAttemptRatio,
    this.homeControlTime,
    this.awayControlTime,
    this.homeControlRatio,
    this.rounds = const [],
  });

  bool get hasStats =>
      homeSigStrikes != null ||
      awaySigStrikes != null ||
      homeTakedowns != null ||
      homeSubAttempts != null ||
      homeControlTime != null ||
      rounds.isNotEmpty;

  factory UfcFightStatsModel.fromJson(Map<String, dynamic> json) {
    final roundsList = <UfcRoundStatsModel>[];
    if (json['rounds'] is List) {
      for (final r in json['rounds'] as List) {
        if (r is Map<String, dynamic>) {
          roundsList.add(UfcRoundStatsModel.fromJson(r));
        }
      }
    }

    return UfcFightStatsModel(
      homeSigStrikes: json['homeSigStrikes']?.toString(),
      awaySigStrikes: json['awaySigStrikes']?.toString(),
      homeSigStrikeRatio: (json['homeSigStrikeRatio'] is num)
          ? (json['homeSigStrikeRatio'] as num).toDouble()
          : null,
      homeSigStrikePct: json['homeSigStrikePct']?.toString(),
      awaySigStrikePct: json['awaySigStrikePct']?.toString(),
      homeSigStrikePctRatio: (json['homeSigStrikePctRatio'] is num)
          ? (json['homeSigStrikePctRatio'] as num).toDouble()
          : null,
      homeTakedowns: json['homeTakedowns']?.toString(),
      awayTakedowns: json['awayTakedowns']?.toString(),
      homeTakedownRatio: (json['homeTakedownRatio'] is num)
          ? (json['homeTakedownRatio'] as num).toDouble()
          : null,
      homeSubAttempts: json['homeSubAttempts']?.toString(),
      awaySubAttempts: json['awaySubAttempts']?.toString(),
      homeSubAttemptRatio: (json['homeSubAttemptRatio'] is num)
          ? (json['homeSubAttemptRatio'] as num).toDouble()
          : null,
      homeControlTime: json['homeControlTime']?.toString(),
      awayControlTime: json['awayControlTime']?.toString(),
      homeControlRatio: (json['homeControlRatio'] is num)
          ? (json['homeControlRatio'] as num).toDouble()
          : null,
      rounds: roundsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (homeSigStrikes != null) 'homeSigStrikes': homeSigStrikes,
      if (awaySigStrikes != null) 'awaySigStrikes': awaySigStrikes,
      if (homeSigStrikeRatio != null) 'homeSigStrikeRatio': homeSigStrikeRatio,
      if (homeSigStrikePct != null) 'homeSigStrikePct': homeSigStrikePct,
      if (awaySigStrikePct != null) 'awaySigStrikePct': awaySigStrikePct,
      if (homeSigStrikePctRatio != null)
        'homeSigStrikePctRatio': homeSigStrikePctRatio,
      if (homeTakedowns != null) 'homeTakedowns': homeTakedowns,
      if (awayTakedowns != null) 'awayTakedowns': awayTakedowns,
      if (homeTakedownRatio != null) 'homeTakedownRatio': homeTakedownRatio,
      if (homeSubAttempts != null) 'homeSubAttempts': homeSubAttempts,
      if (awaySubAttempts != null) 'awaySubAttempts': awaySubAttempts,
      if (homeSubAttemptRatio != null)
        'homeSubAttemptRatio': homeSubAttemptRatio,
      if (homeControlTime != null) 'homeControlTime': homeControlTime,
      if (awayControlTime != null) 'awayControlTime': awayControlTime,
      if (homeControlRatio != null) 'homeControlRatio': homeControlRatio,
      if (rounds.isNotEmpty)
        'rounds': rounds.map((r) => r.toJson()).toList(),
    };
  }
}

/// Combate individual dentro de la cartelera de UFC.
class UfcFightModel {
  final String id;
  final int order;
  final UfcCardSegment segment;
  final bool isMainEvent;
  final bool isCoMainEvent;
  final String weightClass;
  final bool titleFight;
  final int roundsScheduled;
  final UfcFightStatus status;
  final int? currentRound;
  final String? clock;
  final String? scheduledTime;
  final UfcFighterModel fighter1;
  final UfcFighterModel fighter2;
  final UfcFightResultModel? result;
  final UfcTaleOfTheTapeModel? taleOfTheTape;
  final UfcFightStatsModel? stats;
  final String? referee;

  const UfcFightModel({
    required this.id,
    required this.order,
    this.segment = UfcCardSegment.mainCard,
    this.isMainEvent = false,
    this.isCoMainEvent = false,
    required this.weightClass,
    this.titleFight = false,
    this.roundsScheduled = 3,
    this.status = UfcFightStatus.scheduled,
    this.currentRound,
    this.clock,
    this.scheduledTime,
    required this.fighter1,
    required this.fighter2,
    this.result,
    this.taleOfTheTape,
    this.stats,
    this.referee,
  });

  bool get isLive => status == UfcFightStatus.live;
  bool get isFinished => status == UfcFightStatus.finished;
  bool get isScheduled => status == UfcFightStatus.scheduled;

  bool get hasConfirmedResult =>
      isFinished && (result != null || (winnerId != null && winnerId!.isNotEmpty));

  String? get winnerId => result?.winnerId;
  String? get winnerName =>
      result?.winnerName ??
      (result?.winnerId == fighter1.id
          ? fighter1.name
          : (result?.winnerId == fighter2.id ? fighter2.name : null));

  /// Categoría o etiqueta superior para la tarjeta (ej. "COMBATE ESTELAR • Peso ligero").
  String get categoryHeader {
    if (isMainEvent) {
      return 'COMBATE ESTELAR • $weightClass';
    } else if (isCoMainEvent) {
      return 'COMBATE CO-ESTELAR • $weightClass';
    } else if (titleFight) {
      return 'TÍTULO • $weightClass';
    }
    return weightClass;
  }

  /// Texto de tiempo u orden.
  /// Si está programado y no hay hora fija individual: "A continuación".
  String get timeOrOrderLabel {
    if (isLive) {
      final r = currentRound != null ? 'Asalto $currentRound' : 'En vivo';
      return clock != null && clock!.isNotEmpty ? '$r • $clock' : r;
    }
    if (isFinished) {
      return result?.formattedSummary(fallbackWinner: winnerName) ??
          'Finalizado';
    }
    if (scheduledTime != null && scheduledTime!.trim().isNotEmpty) {
      return scheduledTime!.trim();
    }
    return 'A continuación';
  }

  factory UfcFightModel.fromJson(Map<String, dynamic> json) {
    return UfcFightModel(
      id: json['id']?.toString() ?? '',
      order: json['order'] is int
          ? json['order'] as int
          : (int.tryParse(json['order']?.toString() ?? '1') ?? 1),
      segment: UfcCardSegment.fromString(json['segment']?.toString()),
      isMainEvent: json['is_main_event'] == true || json['isMainEvent'] == true,
      isCoMainEvent:
          json['is_co_main_event'] == true || json['isCoMainEvent'] == true,
      weightClass: json['weight_class']?.toString() ??
          json['weightClass']?.toString() ??
          'Peso acordado',
      titleFight: json['title_fight'] == true || json['titleFight'] == true,
      roundsScheduled: json['rounds_scheduled'] is int
          ? json['rounds_scheduled'] as int
          : (int.tryParse(json['roundsScheduled']?.toString() ?? '3') ?? 3),
      status: UfcFightStatus.fromString(json['status']?.toString()),
      currentRound: json['current_round'] is int
          ? json['current_round'] as int
          : int.tryParse(json['currentRound']?.toString() ?? ''),
      clock: json['clock']?.toString(),
      scheduledTime: json['scheduled_time']?.toString() ??
          json['scheduledTime']?.toString(),
      fighter1: json['fighter1'] is Map<String, dynamic>
          ? UfcFighterModel.fromJson(json['fighter1'] as Map<String, dynamic>)
          : UfcFighterModel(id: 'f1', name: 'Peleador 1'),
      fighter2: json['fighter2'] is Map<String, dynamic>
          ? UfcFighterModel.fromJson(json['fighter2'] as Map<String, dynamic>)
          : UfcFighterModel(id: 'f2', name: 'Peleador 2'),
      result: json['result'] is Map<String, dynamic>
          ? UfcFightResultModel.fromJson(json['result'] as Map<String, dynamic>)
          : null,
      taleOfTheTape: json['tale_of_the_tape'] is Map<String, dynamic>
          ? UfcTaleOfTheTapeModel.fromJson(
              json['tale_of_the_tape'] as Map<String, dynamic>,
            )
          : (json['taleOfTheTape'] is Map<String, dynamic>
              ? UfcTaleOfTheTapeModel.fromJson(
                  json['taleOfTheTape'] as Map<String, dynamic>,
                )
              : null),
      stats: json['stats'] is Map<String, dynamic>
          ? UfcFightStatsModel.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
      referee: json['referee']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'segment': segment.name,
      'isMainEvent': isMainEvent,
      'isCoMainEvent': isCoMainEvent,
      'weightClass': weightClass,
      'titleFight': titleFight,
      'roundsScheduled': roundsScheduled,
      'status': status.name,
      if (currentRound != null) 'currentRound': currentRound,
      if (clock != null) 'clock': clock,
      if (scheduledTime != null) 'scheduledTime': scheduledTime,
      'fighter1': fighter1.toJson(),
      'fighter2': fighter2.toJson(),
      if (result != null) 'result': result!.toJson(),
      if (taleOfTheTape != null) 'taleOfTheTape': taleOfTheTape!.toJson(),
      if (stats != null) 'stats': stats!.toJson(),
      if (referee != null) 'referee': referee,
    };
  }
}

/// Contrato completo de la Cartelera de UFC (v1).
/// Documentado en docs/ufc-detail-contract.md.
class UfcCardModel {
  final int version;
  final String cardId;
  final String name;
  final String? subtitle;
  final String? venue;
  final String? city;
  final String? country;
  final DateTime? date;
  final UfcCardStatus status;
  final List<UfcFightModel> fights;

  const UfcCardModel({
    this.version = 1,
    required this.cardId,
    required this.name,
    this.subtitle,
    this.venue,
    this.city,
    this.country,
    this.date,
    this.status = UfcCardStatus.scheduled,
    required this.fights,
  });

  bool get isLive => status == UfcCardStatus.live;
  bool get isFinished => status == UfcCardStatus.finished;

  /// Retorna los combates pertenecientes a la Cartelera Principal, ordenados.
  List<UfcFightModel> get mainFights => fights
      .where((f) => f.segment == UfcCardSegment.mainCard)
      .toList()
    ..sort((a, b) => a.order.compareTo(b.order));

  /// Retorna los combates preliminares y primeras preliminares, ordenados.
  List<UfcFightModel> get prelimFights => fights
      .where(
        (f) =>
            f.segment == UfcCardSegment.prelims ||
            f.segment == UfcCardSegment.earlyPrelims,
      )
      .toList()
    ..sort((a, b) => a.order.compareTo(b.order));

  /// Combate estelar de la velada.
  UfcFightModel? get mainEvent {
    for (final f in fights) {
      if (f.isMainEvent) return f;
    }
    return mainFights.firstOrNull ?? fights.firstOrNull;
  }

  /// Combate co-estelar de la velada.
  UfcFightModel? get coMainEvent {
    for (final f in fights) {
      if (f.isCoMainEvent) return f;
    }
    if (mainFights.length > 1) return mainFights[1];
    return null;
  }

  /// Retorna el combate que actualmente esté en vivo, si existe alguno.
  UfcFightModel? get liveFight {
    for (final f in fights) {
      if (f.isLive) return f;
    }
    return null;
  }

  /// Fecha legible en español para la velada.
  String? get formattedDate {
    if (date == null) return null;
    final local = date!.toLocal();
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    final m = months[local.month - 1];
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '${local.day} de $m, ${local.year} • $h:$min';
  }

  /// Busca un combate por su identificador único.
  UfcFightModel? fightById(String id) {
    for (final f in fights) {
      if (f.id == id) return f;
    }
    return null;
  }

  static UfcCardModel? parse(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    if (value['version'] != null && value['version'] != 1) return null;

    final id = value['cardId']?.toString() ??
        value['card_id']?.toString() ??
        value['id']?.toString() ??
        '';
    final name = value['name']?.toString() ?? '';
    if (name.isEmpty) return null;

    DateTime? parsedDate;
    final rawDate = value['date'] ?? value['start_date'] ?? value['startDate'];
    if (rawDate != null) {
      parsedDate = DateTime.tryParse(rawDate.toString());
    }

    final fightsList = <UfcFightModel>[];
    if (value['fights'] is List) {
      for (final f in value['fights'] as List) {
        if (f is Map<String, dynamic>) {
          fightsList.add(UfcFightModel.fromJson(f));
        }
      }
    }

    fightsList.sort((a, b) => a.order.compareTo(b.order));

    return UfcCardModel(
      version: 1,
      cardId: id.isNotEmpty ? id : 'ufc-card-default',
      name: name,
      subtitle: value['subtitle']?.toString(),
      venue: value['venue']?.toString(),
      city: value['city']?.toString(),
      country: value['country']?.toString(),
      date: parsedDate,
      status: UfcCardStatus.fromString(value['status']?.toString()),
      fights: fightsList,
    );
  }

  /// Agrupa una lista de eventos individuales de UFC en una Cartelera completa (UfcCardModel).
  /// Asigna segmentos (Cartelera principal / Preliminares), orden de combate, combate estelar y co-estelar,
  /// categoría de peso y resultados oficiales sin inventar registros o datos inexistentes.
  static UfcCardModel fromEvents(
    List<EventModel> events, {
    EventModel? currentEvent,
  }) {
    if (events.isEmpty) {
      if (currentEvent != null) return fromEvent(currentEvent);
      return const UfcCardModel(
        cardId: 'ufc-card-empty',
        name: 'UFC',
        status: UfcCardStatus.scheduled,
        fights: [],
      );
    }

    final ref = currentEvent ?? events.first;

    // Si el evento de referencia ya posee una cartelera completa provista por extraStats, se usa directamente
    if (ref.ufcCard != null) return ref.ufcCard!;
    for (final e in events) {
      if (e.ufcCard != null) return e.ufcCard!;
    }

    // Ordenar los combates de la velada:
    // En UFC, el combate estelar tiene 5 asaltos (o título) y suele disputarse al final.
    final sorted = List<EventModel>.from(events);
    sorted.sort((a, b) {
      // 1. Asaltos (5 asaltos van primero en importancia de cartelera)
      final aRounds = a.ufcStats?.round ?? 0;
      final bRounds = b.ufcStats?.round ?? 0;
      if (aRounds != bRounds) return bRounds.compareTo(aRounds);

      // 2. Horario si difiere
      if (a.startTime != null && b.startTime != null) {
        final timeDiff = b.startTime!.compareTo(a.startTime!);
        if (timeDiff != 0) return timeDiff;
      }

      // 3. Identificador / externalId
      return a.id.compareTo(b.id);
    });

    final total = sorted.length;
    final fights = <UfcFightModel>[];

    for (var i = 0; i < total; i++) {
      final ev = sorted[i];
      final order = i + 1;
      final isMain = i == 0;
      final isCoMain = i == 1 && total > 1;

      // Cartelera principal: los primeros 5 combates o todos si hay <= 5
      final segment = (i < 5 || total <= 5)
          ? UfcCardSegment.mainCard
          : (i >= 9 ? UfcCardSegment.earlyPrelims : UfcCardSegment.prelims);

      final f1 = ev.fighter1;
      final f2 = ev.fighter2;
      final stats = ev.ufcStats;

      final ufcFighter1 = UfcFighterModel(
        id: f1?.id ?? 'f1',
        name: f1?.name ?? 'Peleador 1',
        nickname: f1?.nickname,
        photoUrl: f1?.photoUrl,
        record: f1?.record,
        corner: 'red',
      );

      final ufcFighter2 = UfcFighterModel(
        id: f2?.id ?? 'f2',
        name: f2?.name ?? 'Peleador 2',
        nickname: f2?.nickname,
        photoUrl: f2?.photoUrl,
        record: f2?.record,
        corner: 'blue',
      );

      final isEvLive = ev.status == EventStatus.live;
      final isEvFinished = ev.status == EventStatus.finished;
      final fightStatus = isEvLive
          ? UfcFightStatus.live
          : (isEvFinished ? UfcFightStatus.finished : UfcFightStatus.scheduled);

      UfcFightResultModel? result;
      if (isEvFinished &&
          (stats?.winnerName != null ||
              ev.fightResult != null ||
              stats?.method != null)) {
        result = UfcFightResultModel(
          winnerName: stats?.winnerName ?? f1?.name,
          winnerId: stats?.winnerName == f2?.name ? f2?.id : f1?.id,
          method: stats?.method ?? ev.fightResult ?? 'Decisión',
          round: stats?.round,
          time: stats?.time,
        );
      }

      final weightClass =
          f1?.weightClass ?? f2?.weightClass ?? 'Peso acordado';

      final titleFight = isMain &&
          (stats?.round == 5 ||
              ev.league.toLowerCase().contains('championship') ||
              ev.league.toLowerCase().contains('título'));

      fights.add(
        UfcFightModel(
          id: ev.id,
          order: order,
          segment: segment,
          isMainEvent: isMain,
          isCoMainEvent: isCoMain,
          weightClass: weightClass,
          titleFight: titleFight,
          roundsScheduled: isMain ? 5 : 3,
          status: fightStatus,
          currentRound: stats?.round,
          clock: stats?.time,
          fighter1: ufcFighter1,
          fighter2: ufcFighter2,
          result: result,
          taleOfTheTape: UfcTaleOfTheTapeModel(
            division: weightClass,
            record1: f1?.record,
            record2: f2?.record,
          ),
        ),
      );
    }

    final hasLive = fights.any((f) => f.isLive);
    final allFinished = fights.isNotEmpty && fights.every((f) => f.isFinished);
    final cardStatus = hasLive
        ? UfcCardStatus.live
        : (allFinished ? UfcCardStatus.finished : UfcCardStatus.scheduled);

    String? cardExternalId;
    if (ref.externalId != null && ref.externalId!.startsWith('ufc-')) {
      final parts = ref.externalId!.split('-');
      if (parts.length >= 2) cardExternalId = 'ufc-card-${parts[1]}';
    }

    return UfcCardModel(
      cardId: cardExternalId ?? ref.id,
      name: ref.league,
      subtitle: ref.venue,
      venue: ref.venue,
      date: ref.startTime,
      status: cardStatus,
      fights: fights,
    );
  }

  /// Construye una cartelera a partir de un EventModel existente.
  /// Si el EventModel ya tiene `ufcCard`, lo retorna directamente.
  /// Si se provee `allEvents`, busca y agrupa los combates hermanos de la misma velada.
  /// En caso contrario, sintetiza una cartelera de un combate con datos reales del evento.
  static UfcCardModel fromEvent(
    EventModel event, {
    List<EventModel>? allEvents,
  }) {
    if (event.ufcCard != null) return event.ufcCard!;

    if (allEvents != null && allEvents.isNotEmpty) {
      String? cardExternalPrefix;
      if (event.externalId != null && event.externalId!.startsWith('ufc-')) {
        final parts = event.externalId!.split('-');
        if (parts.length >= 2) {
          cardExternalPrefix = 'ufc-${parts[1]}-';
        }
      }

      final pool = allEvents.where((e) {
        if (e.sport != SportType.ufc) return false;
        if (cardExternalPrefix != null &&
            e.externalId != null &&
            e.externalId!.startsWith(cardExternalPrefix)) {
          return true;
        }
        if (e.league.trim().toLowerCase() ==
            event.league.trim().toLowerCase()) {
          if (e.startTime != null && event.startTime != null) {
            return e.startTime!
                    .difference(event.startTime!)
                    .inHours
                    .abs() <
                18;
          }
          return true;
        }
        return false;
      }).toList();

      if (pool.length > 1) {
        return fromEvents(pool, currentEvent: event);
      }
    }

    final f1 = event.fighter1;
    final f2 = event.fighter2;
    final stats = event.ufcStats;

    final ufcFighter1 = UfcFighterModel(
      id: f1?.id ?? 'f1',
      name: f1?.name ?? 'Peleador 1',
      nickname: f1?.nickname,
      photoUrl: f1?.photoUrl,
      record: f1?.record,
      corner: 'red',
    );

    final ufcFighter2 = UfcFighterModel(
      id: f2?.id ?? 'f2',
      name: f2?.name ?? 'Peleador 2',
      nickname: f2?.nickname,
      photoUrl: f2?.photoUrl,
      record: f2?.record,
      corner: 'blue',
    );

    final isLive = event.status == EventStatus.live;
    final isFinished = event.status == EventStatus.finished;
    final fightStatus = isLive
        ? UfcFightStatus.live
        : (isFinished ? UfcFightStatus.finished : UfcFightStatus.scheduled);

    UfcFightResultModel? result;
    if (isFinished &&
        (stats?.winnerName != null ||
            event.fightResult != null ||
            stats?.method != null)) {
      result = UfcFightResultModel(
        winnerName: stats?.winnerName ?? (f1?.name),
        winnerId: stats?.winnerName == f2?.name ? f2?.id : f1?.id,
        method: stats?.method ?? event.fightResult ?? 'KO / TKO',
        round: stats?.round,
        time: stats?.time,
      );
    }

    final singleFight = UfcFightModel(
      id: event.id,
      order: 1,
      segment: UfcCardSegment.mainCard,
      isMainEvent: true,
      weightClass: f1?.weightClass ?? f2?.weightClass ?? 'Peso acordado',
      status: fightStatus,
      currentRound: stats?.round,
      clock: stats?.time,
      fighter1: ufcFighter1,
      fighter2: ufcFighter2,
      result: result,
      taleOfTheTape: UfcTaleOfTheTapeModel(
        division: f1?.weightClass ?? f2?.weightClass,
        record1: f1?.record,
        record2: f2?.record,
      ),
    );

    final cardStatus = isLive
        ? UfcCardStatus.live
        : (isFinished ? UfcCardStatus.finished : UfcCardStatus.scheduled);

    return UfcCardModel(
      cardId: event.id,
      name: event.league,
      subtitle: event.venue,
      venue: event.venue,
      date: event.startTime,
      status: cardStatus,
      fights: [singleFight],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'cardId': cardId,
      'name': name,
      if (subtitle != null) 'subtitle': subtitle,
      if (venue != null) 'venue': venue,
      if (city != null) 'city': city,
      if (country != null) 'country': country,
      if (date != null) 'date': date!.toIso8601String(),
      'status': status.name,
      'fights': fights.map((f) => f.toJson()).toList(),
    };
  }
}
