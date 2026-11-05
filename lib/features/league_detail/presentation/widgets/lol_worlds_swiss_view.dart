import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/event_model.dart';
import '../../../../models/event_status.dart';
import '../../../../models/lol_worlds_stage_model.dart';
import '../../../../models/sport_type.dart';
import '../../../../models/stats_models.dart';
import '../../../../models/team_model.dart';

/// Vista especializada para la competición Worlds de League of Legends y su formato suizo.
/// Presenta:
/// 1. Pestaña "Partidos": Próximos encuentros agrupados por día con el diseño nativo de Kambate.
/// 2. Pestaña "Tabla": Tabla de clasificación suiza con récord W-L, diferencia y estado de avance.
/// 3. Pestaña "Cuadro Suizo": Diagrama horizontal interactivo con todas las rondas y cubos (R1 a R5 + Clasificados y Eliminados),
///    utilizando la paleta de colores y tokens nativos de Kambate.
class LolWorldsSwissView extends StatefulWidget {
  final LolWorldsStageModel stageData;
  final List<EventModel> upcomingEvents;
  final VoidCallback onRefresh;

  const LolWorldsSwissView({
    super.key,
    required this.stageData,
    this.upcomingEvents = const [],
    required this.onRefresh,
  });

  @override
  State<LolWorldsSwissView> createState() => _LolWorldsSwissViewState();
}

class _LolWorldsSwissViewState extends State<LolWorldsSwissView>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TransformationController _transformationController;
  late AnimationController _panAnimationController;
  Animation<double>? _xAnimation;

  final ValueNotifier<double> _sliderProgressNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<int> _currentColumnNotifier = ValueNotifier<int>(0);
  double _maxScrollExtent = 1200.0;
  double _currentScale = 0.75;
  bool _isInteractingSlider = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformationChanged);

    _panAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..addListener(() {
        if (_xAnimation != null) {
          final x = _xAnimation!.value;
          final currentY = _transformationController.value.storage[13];
          _transformationController.value = Matrix4.identity()
            ..setTranslationRaw(-x, currentY, 0.0);
        }
      });
  }

  void _onTransformationChanged() {
    final matrix = _transformationController.value;
    final currentX = -matrix.storage[12];
    final colStep = 278.0 * _currentScale;
    final approxCol = (colStep > 0 ? (currentX / colStep).round() : 0).clamp(0, 5);

    _currentColumnNotifier.value = approxCol;
    if (!_isInteractingSlider && _maxScrollExtent > 0) {
      _sliderProgressNotifier.value = (currentX / _maxScrollExtent).clamp(0.0, 1.0);
    }
  }

  void _goToColumn(int colIndex, double maxScroll) {
    _panAnimationController.stop();
    final colStep = 278.0 * _currentScale;
    final offsets = [
      0.0,
      colStep,
      colStep * 2,
      colStep * 3,
      colStep * 4,
      maxScroll,
    ];
    final targetX = offsets[colIndex.clamp(0, 5)].clamp(0.0, maxScroll);
    _currentColumnNotifier.value = colIndex.clamp(0, 5);
    _animateToX(targetX);
  }

  void _animateToX(double targetX) {
    _panAnimationController.stop();
    final currentX = -_transformationController.value.storage[12];

    _xAnimation = Tween<double>(
      begin: currentX,
      end: targetX,
    ).animate(CurvedAnimation(
      parent: _panAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _panAnimationController.reset();
    _panAnimationController.forward();
  }

  void _onSliderChanged(double progress, double maxScroll) {
    _isInteractingSlider = true;
    _panAnimationController.stop();
    final targetX = (progress * maxScroll).clamp(0.0, maxScroll);
    final currentY = _transformationController.value.storage[13];
    final colStep = 278.0 * _currentScale;

    _sliderProgressNotifier.value = progress;
    _currentColumnNotifier.value = colStep > 0
        ? (targetX / colStep).round().clamp(0, 5)
        : 0;

    _transformationController.value = Matrix4.identity()
      ..setTranslationRaw(-targetX, currentY, 0.0);

    _isInteractingSlider = false;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    _panAnimationController.dispose();
    _sliderProgressNotifier.dispose();
    _currentColumnNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.stageData;

    // Si la fuente no tiene cobertura, credenciales no configuradas o está vacía
    if ((!data.hasCoverage || data.isUnconfigured || data.isEmpty) &&
        widget.upcomingEvents.isEmpty) {
      return _buildNoCoverageView(data);
    }

    return Column(
      children: [
        Container(
          color: AppColors.surfaceDark,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Partidos'),
              Tab(text: 'Tabla'),
              Tab(text: 'Cuadro Suizo'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildUpcomingMatchesTab(data),
              _buildStandingsTab(data),
              _buildMatchesTab(data),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // PESTAÑA 1: PARTIDOS FUTUROS / PRÓXIMOS ENCUENTROS
  // =========================================================================

  List<EventModel> _resolveUpcomingEvents(LolWorldsStageModel data) {
    final Map<String, EventModel> byKey = {};

    for (final ev in widget.upcomingEvents) {
      if (ev.status == EventStatus.finished) continue;
      final key = ev.externalId ?? ev.id;
      byKey[key] = ev;
    }

    for (final m in data.matches) {
      if (m.isFinished) continue;
      final key = m.externalId ?? 'pandascore-lol-match-${m.id}';
      if (!byKey.containsKey(key) && !byKey.containsKey(m.id)) {
        byKey[key] = EventModel(
          id: m.id,
          externalId: m.externalId,
          sport: SportType.lol,
          league: data.competition.name,
          status: m.isLive ? EventStatus.live : EventStatus.scheduled,
          startTime: m.startTime,
          score: m.isLive
              ? '${m.homeTeam.score ?? 0} - ${m.awayTeam.score ?? 0}'
              : null,
          homeScore: m.homeTeam.score,
          awayScore: m.awayTeam.score,
          homeTeam: TeamModel(
            id: m.homeTeam.id ?? 'home',
            name: m.homeTeam.name,
            shortName: m.homeTeam.code,
            logoUrl: m.homeTeam.logoUrl,
          ),
          awayTeam: TeamModel(
            id: m.awayTeam.id ?? 'away',
            name: m.awayTeam.name,
            shortName: m.awayTeam.code,
            logoUrl: m.awayTeam.logoUrl,
          ),
          esportsStats: EsportsStatsModel(
            id: 'stats-${m.id}',
            eventId: m.id,
            homeScore: m.homeTeam.score,
            awayScore: m.awayTeam.score,
            format: m.format,
            map: m.format,
            extraStats: {
              if (m.roundName != null) 'phase': m.roundName,
              if (m.format != null) 'format': m.format,
            },
          ),
        );
      }
    }

    final list = byKey.values.toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return list;
  }

  Widget _buildUpcomingMatchesTab(LolWorldsStageModel data) {
    final upcoming = _resolveUpcomingEvents(data);

    if (upcoming.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => widget.onRefresh(),
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32.0),
          children: [
            const SizedBox(height: 60),
            Icon(
              Icons.event_available_rounded,
              size: 44,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'No hay próximos partidos programados',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Consulta la Tabla o el Cuadro Suizo para ver los resultados de la competición.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
            ),
          ],
        ),
      );
    }

    // Agrupar partidos por fecha calendario local
    final List<({DateTime day, String headerLabel, List<EventModel> events})>
        dayGroups = [];
    for (final ev in upcoming) {
      final local = ev.startTime.toLocal();
      final dayDate = DateTime(local.year, local.month, local.day);
      if (dayGroups.isEmpty || dayGroups.last.day != dayDate) {
        dayGroups.add((
          day: dayDate,
          headerLabel: _formatUpcomingDayHeader(local),
          events: [ev],
        ));
      } else {
        dayGroups.last.events.add(ev);
      }
    }

    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        itemCount: dayGroups.length,
        itemBuilder: (context, index) {
          final group = dayGroups[index];
          return Container(
            key: ValueKey(
              'lol-worlds-day-group-${group.day.toIso8601String()}',
            ),
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.headerLabel,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 12),
                for (int i = 0; i < group.events.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _buildUpcomingWorldsMatchCard(
                    context,
                    group.events[i],
                    data,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUpcomingWorldsMatchCard(
    BuildContext context,
    EventModel event,
    LolWorldsStageModel stageData,
  ) {
    final isLive = event.isLive;
    final timeInfo = _format12HourTime(event.startTime);
    final homeAbbr = _resolveTeamCode(
      event.homeTeam?.name,
      event.homeTeam?.shortName,
      stageData,
    );
    final awayAbbr = _resolveTeamCode(
      event.awayTeam?.name,
      event.awayTeam?.shortName,
      stageData,
    );
    final isHomeTbd = homeAbbr.toUpperCase() == 'TBD' ||
        (event.homeTeam?.name.toUpperCase() ?? 'TBD') == 'TBD';
    final isAwayTbd = awayAbbr.toUpperCase() == 'TBD' ||
        (event.awayTeam?.name.toUpperCase() ?? 'TBD') == 'TBD';
    final phaseLabel = _resolveSpanishPhaseSubtitle(event);
    final formatLabel = _resolveMatchFormat(event);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('lol-upcoming-match-${event.id}'),
        onTap: () => context.push('/detail/${event.id}', extra: event),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isLive
                  ? AppColors.error.withValues(alpha: 0.6)
                  : AppColors.border,
              width: isLive ? 1.4 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fila principal: Hora + Enfrentamiento centrado
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    // Hora a la izquierda
                    SizedBox(
                      width: 86,
                      child: isLive
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Flexible(
                                  child: Text(
                                    'EN VIVO',
                                    style: TextStyle(
                                      color: AppColors.error,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          : RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: timeInfo.hourMinute,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' ${timeInfo.period}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    // Enfrentamiento centrado: CODE [Logo] / [Logo] CODE
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: Text(
                                    homeAbbr,
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      color: isHomeTbd
                                          ? AppColors.textSecondary
                                          : AppColors.textPrimary,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _buildUpcomingTeamBadge(
                                  logoUrl: event.homeTeam?.logoUrl,
                                  isTbd: isHomeTbd,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: isLive && event.score != null
                                ? Text(
                                    event.score!,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  )
                                : Text(
                                    '/',
                                    style: TextStyle(
                                      color: AppColors.textMuted
                                          .withValues(alpha: 0.6),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                _buildUpcomingTeamBadge(
                                  logoUrl: event.awayTeam?.logoUrl,
                                  isTbd: isAwayTbd,
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    awayAbbr,
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                      color: isAwayTbd
                                          ? AppColors.textSecondary
                                          : AppColors.textPrimary,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Balance visual derecho para centrar el versus respecto a la tarjeta
                    const SizedBox(width: 24),
                  ],
                ),
              ),
              // Barra inferior: Logo Worlds + Fase + Formato (Bo5/Bo3/Bo1)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(9),
                  ),
                  border: Border(
                    top: BorderSide(color: AppColors.border, width: 0.8),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.border, width: 0.8),
                      ),
                      child: Image.network(
                        'https://cdn-api.pandascore.co/images/league/image/297/worlds-png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.sports_esports,
                          size: 13,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        phaseLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      formatLabel,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingTeamBadge({
    required String? logoUrl,
    required bool isTbd,
  }) {
    if (isTbd || logoUrl == null || logoUrl.trim().isEmpty) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceMuted,
          border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.45)),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 10,
          height: 1.8,
          decoration: BoxDecoration(
            color: AppColors.textMuted,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      );
    }

    return SizedBox(
      width: 28,
      height: 28,
      child: Image.network(
        logoUrl,
        width: 28,
        height: 28,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceMuted,
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(
            Icons.shield_outlined,
            size: 16,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  String _formatUpcomingDayHeader(DateTime dateTime) {
    final localTarget = dateTime.toLocal();
    final localNow = DateTime.now();
    final todayNoon = DateTime(localNow.year, localNow.month, localNow.day, 12);
    final targetNoon = DateTime(
      localTarget.year,
      localTarget.month,
      localTarget.day,
      12,
    );
    final diffInDays = (targetNoon.difference(todayNoon).inHours / 24).round();

    if (diffInDays == 0) {
      return localTarget.isAfter(localNow) ? 'Más tarde hoy' : 'Hoy';
    } else if (diffInDays == 1) {
      return 'Mañana';
    } else if (diffInDays == -1) {
      return 'Ayer';
    }

    const weekdays = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    final weekday = weekdays[(localTarget.weekday - 1) % 7];
    final month = months[(localTarget.month - 1) % 12];
    return '$weekday ${localTarget.day} $month';
  }

  ({String hourMinute, String period}) _format12HourTime(DateTime date) {
    final local = date.toLocal();
    final isPm = local.hour >= 12;
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minStr = local.minute.toString().padLeft(2, '0');
    return (
      hourMinute: '$hour12:$minStr',
      period: isPm ? 'p.m.' : 'a.m.',
    );
  }

  String _resolveTeamCode(
    String? teamName,
    String? shortName,
    LolWorldsStageModel stageData,
  ) {
    if (shortName != null && shortName.trim().isNotEmpty) {
      return shortName.trim().toUpperCase();
    }
    final clean = (teamName ?? '').trim();
    if (clean.isEmpty || clean.toUpperCase() == 'TBD') return 'TBD';

    final lower = clean.toLowerCase();

    // Buscar en standings de la etapa suiza
    for (final s in stageData.swissStandings) {
      if (s.teamName.trim().toLowerCase() == lower &&
          s.teamCode != null &&
          s.teamCode!.trim().isNotEmpty) {
        return s.teamCode!.trim().toUpperCase();
      }
    }

    // Buscar en partidos de la etapa suiza
    for (final m in stageData.matches) {
      if (m.homeTeam.name.trim().toLowerCase() == lower &&
          m.homeTeam.code != null &&
          m.homeTeam.code!.trim().isNotEmpty) {
        return m.homeTeam.code!.trim().toUpperCase();
      }
      if (m.awayTeam.name.trim().toLowerCase() == lower &&
          m.awayTeam.code != null &&
          m.awayTeam.code!.trim().isNotEmpty) {
        return m.awayTeam.code!.trim().toUpperCase();
      }
    }

    // Mapa de siglas conocidas de equipos internacionales de LoL
    const knownCodes = <String, String>{
      'dplus kia': 'DK',
      'bilibili gaming': 'BLG',
      'karmine corp': 'KC',
      't1': 'T1',
      'gen.g': 'GEN',
      'geng': 'GEN',
      'invictus gaming': 'IG',
      'top esports': 'TES',
      'hanwha life esports': 'HLE',
      'g2 esports': 'G2',
      'team liquid': 'TL',
      'movistar koi': 'MKOI',
      'mad lions koi': 'MDK',
      'ctbc flying oyster': 'CFO',
      'lyon': 'LY',
      'los': 'LOS',
      "anyone's legend": 'AL',
      'team secret whales': 'TSW',
      'fnatic': 'FNC',
      'cloud9': 'C9',
      'flyquest': 'FLY',
      'weibo gaming': 'WBG',
      'jd gaming': 'JDG',
      'lng esports': 'LNG',
      'kt rolster': 'KT',
      'drx': 'DRX',
      'edward gaming': 'EDG',
      'royal never give up': 'RNG',
      'psg talon': 'PSG',
      'gam esports': 'GAM',
      'pain gaming': 'PNG',
      'loud': 'LLL',
    };
    if (knownCodes.containsKey(lower)) {
      return knownCodes[lower]!;
    }

    if (clean.length <= 4) return clean.toUpperCase();
    final words = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length >= 2) {
      return words.map((w) => w[0]).take(4).join().toUpperCase();
    }
    return clean.substring(0, 3).toUpperCase();
  }

  String _resolveSpanishPhaseSubtitle(EventModel event) {
    final extra = event.esportsStats?.extraStats;
    final rawPhase = extra?['phase']?.toString() ?? event.roundOrPhase ?? '';
    final rawTournament = extra?['tournament']?.toString() ?? '';
    final combined = '$rawPhase $rawTournament'.toLowerCase();

    String stagePart = 'Fase de Grupos';
    if (combined.contains('quarterfinal') || combined.contains('cuartos')) {
      stagePart = 'Cuartos de Final';
    } else if (combined.contains('semifinal')) {
      stagePart = 'Semifinales';
    } else if (combined.contains('grand final') ||
        RegExp(r'\bfinals?\b').hasMatch(combined)) {
      stagePart = 'Final';
    } else if (combined.contains('play-in') || combined.contains('play in')) {
      stagePart = 'Play-In';
    } else if (combined.contains('swiss') || combined.contains('suiza')) {
      stagePart = 'Etapa Suiza';
    } else if (combined.contains('playoff')) {
      stagePart = 'Playoffs';
    } else if (rawPhase.isNotEmpty) {
      final beforeColon = rawPhase.split(':').first.trim();
      final roundMatch = RegExp(
        r'^round\s*(\d+)$',
        caseSensitive: false,
      ).firstMatch(beforeColon);
      if (roundMatch != null) {
        stagePart = 'Ronda ${roundMatch.group(1)}';
      } else if (beforeColon.isNotEmpty) {
        stagePart = beforeColon;
      }
    }

    return 'Worlds • $stagePart';
  }

  String _resolveMatchFormat(EventModel event) {
    final extraFormat = event.esportsStats?.extraStats?['format']?.toString();
    if (extraFormat != null && extraFormat.trim().isNotEmpty) {
      return extraFormat.trim();
    }
    final statFormat = event.esportsStats?.format ?? event.esportsStats?.map;
    if (statFormat != null && statFormat.trim().isNotEmpty) {
      return statFormat.trim();
    }
    final numGames = event.esportsStats?.extraStats?['numberOfGames'];
    if (numGames is int && numGames > 0) {
      return 'Bo$numGames';
    }
    return 'Bo5';
  }

  // =========================================================================
  // PESTAÑA 2: CUADRO SUIZO Y PARTIDOS
  // =========================================================================

  Widget _buildMatchesTab(LolWorldsStageModel data) {
    final allMatches = data.matches;

    if (allMatches.isEmpty) {
      return _buildEmptyMatchesState();
    }

    final isSwiss = data.stage?.isSwiss ?? true;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        // Altura disponible descontando la barra de navegación inferior
        final availableHeight = constraints.maxHeight - (isSwiss ? 54.0 : 0.0);

        // Dimensiones base del diagrama suizo
        const baseContentHeight = 500.0;
        const baseContentWidth = 1650.0;

        // Escala calculada dinámicamente para que todo el cuadro entre en vertical
        final scale = (availableHeight / baseContentHeight).clamp(0.65, 0.85);
        _currentScale = scale;

        final totalContentWidth = baseContentWidth * scale;
        final totalContentHeight = baseContentHeight * scale;
        final maxScroll = (totalContentWidth - viewportWidth).clamp(0.0, totalContentWidth);
        _maxScrollExtent = maxScroll;

        return Column(
          children: [
            Expanded(
              child: _buildSwissBracketView(
                data,
                allMatches,
                scale: scale,
                contentWidth: totalContentWidth,
                contentHeight: totalContentHeight,
              ),
            ),
            if (isSwiss) _buildBottomNavigationBar(maxScroll),
          ],
        );
      },
    );
  }

  Widget _buildBottomNavigationBar(double maxScroll) {
    return AnimatedBuilder(
      animation: Listenable.merge([_currentColumnNotifier, _sliderProgressNotifier]),
      builder: (context, _) {
        final currentColumn = _currentColumnNotifier.value;
        final sliderProgress = _sliderProgressNotifier.value;

        return Container(
          key: const ValueKey('lol-swiss-bottom-bar'),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: const BoxDecoration(
            color: AppColors.surfaceDark,
            border: Border(
              top: BorderSide(color: AppColors.cardBorderDark, width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // Botón Navegación Izquierda
                IconButton(
                  key: const ValueKey('lol-swiss-nav-left'),
                  icon: const Icon(Icons.chevron_left_rounded, size: 24),
                  color: currentColumn > 0
                      ? AppColors.textPrimary
                      : AppColors.textMuted.withValues(alpha: 0.3),
                  onPressed: currentColumn > 0
                      ? () => _goToColumn(currentColumn - 1, maxScroll)
                      : null,
                  tooltip: 'Ronda anterior',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                const SizedBox(width: 4),
                // Centro: Pills de rondas y Slider de desplazamiento
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (i) {
                          final labels = ['R1', 'R2', 'R3', 'R4', 'R5', 'Final'];
                          final isSelected = currentColumn == i;
                          return InkWell(
                            key: ValueKey('lol-swiss-nav-pill-$i'),
                            onTap: () => _goToColumn(i, maxScroll),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected
                                    ? Border.all(color: AppColors.primary, width: 1)
                                    : Border.all(color: Colors.transparent, width: 1),
                              ),
                              child: Text(
                                labels[i],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        height: 20,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: AppColors.surfaceMuted,
                            thumbColor: AppColors.primary,
                          ),
                          child: Slider(
                            key: const ValueKey('lol-swiss-bottom-slider'),
                            value: sliderProgress.clamp(0.0, 1.0),
                            onChanged: maxScroll > 0
                                ? (val) => _onSliderChanged(val, maxScroll)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                // Botón Navegación Derecha
                IconButton(
                  key: const ValueKey('lol-swiss-nav-right'),
                  icon: const Icon(Icons.chevron_right_rounded, size: 24),
                  color: currentColumn < 5
                      ? AppColors.textPrimary
                      : AppColors.textMuted.withValues(alpha: 0.3),
                  onPressed: currentColumn < 5
                      ? () => _goToColumn(currentColumn + 1, maxScroll)
                      : null,
                  tooltip: 'Siguiente ronda',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================================
  // CUADRO SUIZO (DIAGRAMA HORIZONTAL COMPLETO)
  // =========================================================================

  Widget _buildSwissBracketView(
    LolWorldsStageModel data,
    List<LolWorldsMatchModel> currentMatches, {
    double scale = 0.75,
    double contentWidth = 1237.5,
    double contentHeight = 375.0,
  }) {

    final allMatches = data.matches;

    // Ronda 1: (0-0)
    final r1Matches = allMatches.where((m) => m.effectiveRoundNumber == 1).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Si ningún partido tiene número de ronda suiza (e.g. Play-In o fase de grupos), mostrar vista de lista
    if (r1Matches.isEmpty &&
        allMatches.where((m) => (m.effectiveRoundNumber ?? 0) > 1).isEmpty &&
        allMatches.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        itemCount: allMatches.length,
        itemBuilder: (context, index) => _buildSwissMatchCard(allMatches[index]),
      );
    }

    // Identificar ganadores y perdedores de Ronda 1 para ordenar cubos de R2
    final r1Winners = <String>{};
    for (final m in r1Matches) {
      if (m.isFinished && m.winnerTeamId != null) {
        r1Winners.add(m.winnerTeamId!);
      }
    }

    // Ronda 2: (1-0) y (0-1)
    final r2Matches = allMatches.where((m) => m.effectiveRoundNumber == 2).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final r2High = <LolWorldsMatchModel>[];
    final r2Low = <LolWorldsMatchModel>[];

    for (final m in r2Matches) {
      final name = m.roundName?.toLowerCase() ?? '';
      final homeRec = m.homeTeam.record ?? '';
      if (name.contains('1-0') || name.contains('high') || homeRec == '1-0') {
        r2High.add(m);
      } else if (name.contains('0-1') || name.contains('low') || homeRec == '0-1') {
        r2Low.add(m);
      } else if (r1Winners.isNotEmpty &&
          (r1Winners.contains(m.homeTeam.id) || r1Winners.contains(m.awayTeam.id))) {
        r2High.add(m);
      } else if (r1Winners.isNotEmpty) {
        r2Low.add(m);
      }
    }

    final effectiveR2High = r2High.isNotEmpty
        ? r2High
        : (r2Matches.length > 4 ? r2Matches.sublist(0, 4) : r2Matches);
    final effectiveR2Low = r2Low.isNotEmpty
        ? r2Low
        : (r2Matches.length > 4 ? r2Matches.sublist(4) : <LolWorldsMatchModel>[]);

    // Ronda 3: (2-0 Bo3), (1-1 Bo1), (0-2 Bo3)
    final r3Matches = allMatches.where((m) => m.effectiveRoundNumber == 3).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final r3High = <LolWorldsMatchModel>[];
    final r3Mid = <LolWorldsMatchModel>[];
    final r3Low = <LolWorldsMatchModel>[];

    for (final m in r3Matches) {
      final name = m.roundName?.toLowerCase() ?? '';
      final format = m.format?.toLowerCase() ?? '';
      final homeRec = m.homeTeam.record ?? '';

      if (name.contains('2-0') || homeRec == '2-0') {
        r3High.add(m);
      } else if (name.contains('0-2') || homeRec == '0-2') {
        r3Low.add(m);
      } else if (format == 'bo1' || name.contains('1-1') || homeRec == '1-1') {
        r3Mid.add(m);
      } else if (format == 'bo3') {
        // En R3, los Bo3 son 2-0 o 0-2
        if (r3High.length < 2) {
          r3High.add(m);
        } else {
          r3Low.add(m);
        }
      } else {
        r3Mid.add(m);
      }
    }

    // Ronda 4: (2-1 Bo3) y (1-2 Bo3)
    final r4Matches = allMatches.where((m) => m.effectiveRoundNumber == 4).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final r4High = <LolWorldsMatchModel>[];
    final r4Low = <LolWorldsMatchModel>[];

    for (final m in r4Matches) {
      final name = m.roundName?.toLowerCase() ?? '';
      final homeRec = m.homeTeam.record ?? '';
      if (name.contains('2-1') || homeRec == '2-1') {
        r4High.add(m);
      } else if (name.contains('1-2') || homeRec == '1-2') {
        r4Low.add(m);
      } else if (r4High.length < 3) {
        r4High.add(m);
      } else {
        r4Low.add(m);
      }
    }

    // Ronda 5: (2-2 Bo3)
    final r5Matches = allMatches.where((m) => m.effectiveRoundNumber == 5).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Equipos clasificados y eliminados
    final advancesR3 = _resolveAdvancingTeams(
      standings: data.swissStandings.where((s) => s.wins == 3 && s.losses == 0).toList(),
      matches: r3High,
      expected: 2,
    );
    final advancesR4 = _resolveAdvancingTeams(
      standings: data.swissStandings.where((s) => s.wins == 3 && s.losses == 1).toList(),
      matches: r4High,
      expected: 3,
    );
    final advancesR5 = _resolveAdvancingTeams(
      standings: data.swissStandings.where((s) => s.wins == 3 && s.losses == 2).toList(),
      matches: r5Matches,
      expected: 3,
    );

    final eliminatedR3 = _resolveEliminatedTeams(
      standings: data.swissStandings.where((s) => s.wins == 0 && s.losses == 3).toList(),
      matches: r3Low,
      expected: 2,
    );
    final eliminatedR4 = _resolveEliminatedTeams(
      standings: data.swissStandings.where((s) => s.wins == 1 && s.losses == 3).toList(),
      matches: r4Low,
      expected: 3,
    );
    final eliminatedR5 = _resolveEliminatedTeams(
      standings: data.swissStandings.where((s) => s.wins == 2 && s.losses == 3).toList(),
      matches: r5Matches,
      expected: 3,
    );

    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      color: AppColors.primary,
      child: InteractiveViewer(
        transformationController: _transformationController,
        constrained: false,
        scaleEnabled: false,
        minScale: 1.0,
        maxScale: 1.0,
        boundaryMargin: EdgeInsets.zero,
        child: SizedBox(
          width: contentWidth,
          height: contentHeight,
          child: OverflowBox(
            minWidth: 0.0,
            maxWidth: double.infinity,
            minHeight: 0.0,
            maxHeight: double.infinity,
            alignment: Alignment.topLeft,
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.backgroundDark,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==========================================
                    // COLUMNA 1: RONDA 1 (0-0)
                    // ==========================================
                    _buildColumnContainer(
                      child: _buildBracketBucket(
                        title: _formatRoundHeader(r1Matches, fallback: 'OCT. 23 - BO1'),
                        recordBadge: null,
                        matches: r1Matches,
                        expectedCount: 8,
                        defaultFormat: 'Bo1',
                      ),
                    ),

                    _buildBracketConnector(height: 480),

                    // ==========================================
                    // COLUMNA 2: RONDA 2 (1-0 y 0-1)
                    // ==========================================
                    _buildColumnContainer(
                      child: Column(
                        children: [
                          _buildBracketBucket(
                            title: _formatRoundHeader(effectiveR2High, fallback: 'OCT. 24 - BO1'),
                            recordBadge: '(1-0)',
                            matches: effectiveR2High,
                            expectedCount: 4,
                            defaultFormat: 'Bo1',
                          ),
                          const SizedBox(height: 12),
                          _buildBracketBucket(
                            title: _formatRoundHeader(effectiveR2Low, fallback: 'OCT. 24 - BO1'),
                            recordBadge: '(0-1)',
                            matches: effectiveR2Low,
                            expectedCount: 4,
                            defaultFormat: 'Bo1',
                          ),
                        ],
                      ),
                    ),

                    _buildBracketConnector(height: 480),

                    // ==========================================
                    // COLUMNA 3: RONDA 3 (2-0, 1-1, 0-2)
                    // ==========================================
                    _buildColumnContainer(
                      child: Column(
                        children: [
                          _buildBracketBucket(
                            title: _formatRoundHeader(r3High, fallback: 'OCT. 25 - BO3'),
                            recordBadge: '(2-0)',
                            matches: r3High,
                            expectedCount: 2,
                            defaultFormat: 'Bo3',
                          ),
                          const SizedBox(height: 10),
                          _buildBracketBucket(
                            title: _formatRoundHeader(r3Mid, fallback: 'OCT. 25 & 26 - BO1'),
                            recordBadge: '(1-1)',
                            matches: r3Mid,
                            expectedCount: 4,
                            defaultFormat: 'Bo1',
                          ),
                          const SizedBox(height: 10),
                          _buildBracketBucket(
                            title: _formatRoundHeader(r3Low, fallback: 'OCT. 26 - BO3'),
                            recordBadge: '(0-2)',
                            matches: r3Low,
                            expectedCount: 2,
                            defaultFormat: 'Bo3',
                          ),
                        ],
                      ),
                    ),

                    _buildBracketConnector(height: 480),

                    // ==========================================
                    // COLUMNA 4: RONDA 4 (2-1 y 1-2) + Avances R3
                    // ==========================================
                    _buildColumnContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildAdvancementBadgeCard(
                            stageLabel: '1ST/2ND',
                            teams: advancesR3,
                            totalSlots: 2,
                          ),
                          const SizedBox(height: 10),
                          _buildBracketBucket(
                            title: _formatRoundHeader(r4High, fallback: 'OCT. 28-30 - BO3'),
                            recordBadge: '(2-1)',
                            matches: r4High,
                            expectedCount: 3,
                            defaultFormat: 'Bo3',
                          ),
                          const SizedBox(height: 10),
                          _buildBracketBucket(
                            title: _formatRoundHeader(r4Low, fallback: 'OCT. 28-30 - BO3'),
                            recordBadge: '(1-2)',
                            matches: r4Low,
                            expectedCount: 3,
                            defaultFormat: 'Bo3',
                          ),
                          const SizedBox(height: 10),
                          _buildEliminatedBadgeCard(
                            teams: eliminatedR3,
                            totalSlots: 2,
                            roundLabel: 'R3 (0-2)',
                          ),
                        ],
                      ),
                    ),

                    _buildBracketConnector(height: 480),

                    // ==========================================
                    // COLUMNA 5: RONDA 5 (2-2) + Avances R4
                    // ==========================================
                    _buildColumnContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildAdvancementBadgeCard(
                            stageLabel: '3RD/4TH/5TH',
                            teams: advancesR4,
                            totalSlots: 3,
                          ),
                          const SizedBox(height: 24),
                          _buildBracketBucket(
                            title: _formatRoundHeader(r5Matches, fallback: 'OCT. 31 - BO3'),
                            recordBadge: '(2-2)',
                            matches: r5Matches,
                            expectedCount: 3,
                            defaultFormat: 'Bo3',
                          ),
                          const SizedBox(height: 24),
                          _buildEliminatedBadgeCard(
                            teams: eliminatedR4,
                            totalSlots: 3,
                            roundLabel: 'R4 (1-2)',
                          ),
                        ],
                      ),
                    ),

                    _buildBracketConnector(height: 480),

                    // ==========================================
                    // COLUMNA 6: CLASIFICADOS Y ELIMINADOS FINALES
                    // ==========================================
                    _buildColumnContainer(
                      width: 220,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildAdvancementBadgeCard(
                            stageLabel: '6TH/7TH/8TH',
                            teams: advancesR5,
                            totalSlots: 3,
                          ),
                          const SizedBox(height: 70),
                          _buildEliminatedBadgeCard(
                            teams: eliminatedR5,
                            totalSlots: 3,
                            roundLabel: 'R5 (2-2)',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColumnContainer({required Widget child, double width = 250}) {
    return SizedBox(
      width: width,
      child: child,
    );
  }

  Widget _buildBracketConnector({required double height}) {
    return Container(
      width: 24,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: CustomPaint(
        painter: _BracketConnectorPainter(),
      ),
    );
  }

  Widget _buildBracketBucket({
    required String title,
    required String? recordBadge,
    required List<LolWorldsMatchModel> matches,
    required int expectedCount,
    required String defaultFormat,
  }) {
    final totalSlots = matches.length > expectedCount ? matches.length : expectedCount;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorderDark),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
              border: Border(
                bottom: BorderSide(color: AppColors.cardBorderDark),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (recordBadge != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      recordBadge,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Column(
              children: List.generate(
                totalSlots,
                (i) {
                  final m = i < matches.length ? matches[i] : null;
                  return _buildBracketMatchCard(m, defaultFormat: defaultFormat);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBracketMatchCard(LolWorldsMatchModel? match, {required String defaultFormat}) {
    if (match == null) {
      return Container(
        height: 42,
        margin: const EdgeInsets.symmetric(vertical: 2.5),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.cardBorderDark),
        ),
        child: const Center(
          child: Text(
            'VS',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
      );
    }

    final isFinished = match.isFinished;
    final isLive = match.isLive;
    final home = match.homeTeam;
    final away = match.awayTeam;
    final homeWon = isFinished && match.winnerTeamId == home.id;
    final awayWon = isFinished && match.winnerTeamId == away.id;

    return InkWell(
      onTap: () => _showMatchDetailsModal(context, match),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        key: ValueKey('lol-match-card-${match.id}'),
        margin: const EdgeInsets.symmetric(vertical: 2.5),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isLive ? AppColors.error.withValues(alpha: 0.05) : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isLive ? AppColors.error : AppColors.cardBorderDark,
            width: isLive ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (match.format != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      match.format!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                if (isLive)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Text(
                        'EN VIVO',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                else if (isFinished)
                  const Text(
                    'FINAL',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  Text(
                    _formatTime(match.startTime),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 8,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                // Equipo Local
                Expanded(
                  child: Row(
                    children: [
                      _buildTeamLogo(home.logoUrl, 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          home.name,
                          style: TextStyle(
                            color: homeWon
                                ? AppColors.primary
                                : (isFinished && !homeWon
                                    ? AppColors.textMuted
                                    : AppColors.textPrimary),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Marcador / VS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildMatchScoreBadge(match),
                ),
                // Equipo Visitante
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          away.name,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: awayWon
                                ? AppColors.primary
                                : (isFinished && !awayWon
                                    ? AppColors.textMuted
                                    : AppColors.textPrimary),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      _buildTeamLogo(away.logoUrl, 16),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchScoreBadge(LolWorldsMatchModel match) {
    if (match.isLive) {
      return Text(
        '${match.homeTeam.score ?? 0} - ${match.awayTeam.score ?? 0}',
        style: const TextStyle(
          color: AppColors.error,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    if (match.isFinished) {
      final s1 = match.homeTeam.score ?? 0;
      final s2 = match.awayTeam.score ?? 0;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          '$s1 - $s2',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return const Text(
      'VS',
      style: TextStyle(
        color: AppColors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildAdvancementBadgeCard({
    required String stageLabel,
    required List<String> teams,
    required int totalSlots,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ADVANCES',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  stageLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalSlots, (index) {
                final hasTeam = index < teams.length;
                final teamName = hasTeam ? teams[index] : null;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (index > 0)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: Text(
                          '/',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Text(
                      teamName ?? '—',
                      style: TextStyle(
                        color: teamName != null ? AppColors.textPrimary : AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEliminatedBadgeCard({
    required List<String> teams,
    required int totalSlots,
    String? roundLabel,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.cardBorderDark, width: 1.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ELIMINATED',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                if (roundLabel != null)
                  Text(
                    roundLabel,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 8,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalSlots, (index) {
                final hasTeam = index < teams.length;
                final teamName = hasTeam ? teams[index] : null;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (index > 0)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: Text(
                          '/',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Text(
                      teamName ?? '—',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _resolveAdvancingTeams({
    required List<LolSwissStandingEntryModel> standings,
    required List<LolWorldsMatchModel> matches,
    required int expected,
  }) {
    final result = <String>[];
    for (final s in standings) {
      result.add(s.teamCode ?? s.teamName);
    }
    for (final m in matches) {
      if (m.isFinished && m.winnerTeamId != null) {
        final winner = m.winnerTeamId == m.homeTeam.id ? m.homeTeam : m.awayTeam;
        final name = winner.code ?? winner.name;
        if (!result.contains(name)) {
          result.add(name);
        }
      }
    }
    return result;
  }

  List<String> _resolveEliminatedTeams({
    required List<LolSwissStandingEntryModel> standings,
    required List<LolWorldsMatchModel> matches,
    required int expected,
  }) {
    final result = <String>[];
    for (final s in standings) {
      result.add(s.teamCode ?? s.teamName);
    }
    for (final m in matches) {
      if (m.isFinished && m.winnerTeamId != null) {
        final loser = m.winnerTeamId == m.homeTeam.id ? m.awayTeam : m.homeTeam;
        final name = loser.code ?? loser.name;
        if (!result.contains(name)) {
          result.add(name);
        }
      }
    }
    return result;
  }

  Widget _buildTeamLogo(String? logoUrl, double size) {
    if (logoUrl != null && logoUrl.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Image.network(
          logoUrl,
          width: size,
          height: size,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.shield_outlined,
            size: size,
            color: AppColors.textMuted,
          ),
        ),
      );
    }
    return Icon(
      Icons.shield_outlined,
      size: size,
      color: AppColors.textMuted,
    );
  }

  String _formatRoundHeader(List<LolWorldsMatchModel> matches, {required String fallback}) {
    if (matches.isEmpty) return fallback;
    final first = matches.first;
    final format = first.format ?? 'Bo1';
    final date = first.startTime;
    final month = _monthAbbr(date.month);
    return '$month. ${date.day} - $format';
  }

  String _monthAbbr(int month) {
    const months = [
      'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
      'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return 'OCT';
  }

  void _showMatchDetailsModal(BuildContext context, LolWorldsMatchModel match) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorderDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                (match.roundName ?? 'Encuentro').toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Formato: ${match.format ?? "Bo1"}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  Text(
                    match.isLive
                        ? 'EN VIVO'
                        : match.isFinished
                            ? 'FINALIZADO'
                            : _formatTime(match.startTime),
                    style: TextStyle(
                      color: match.isLive ? AppColors.error : AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Divider(color: AppColors.cardBorderDark, height: 24),
              _buildTeamRow(
                participant: match.homeTeam,
                isWinner: match.isFinished && match.winnerTeamId == match.homeTeam.id,
                score: match.homeTeam.score,
              ),
              const SizedBox(height: 10),
              _buildTeamRow(
                participant: match.awayTeam,
                isWinner: match.isFinished && match.winnerTeamId == match.awayTeam.id,
                score: match.awayTeam.score,
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================================
  // LISTA TRADICIONAL DE PARTIDOS (MODO VERTICAL)
  // =========================================================================

  Widget _buildSwissMatchCard(LolWorldsMatchModel match) {
    final home = match.homeTeam;
    final away = match.awayTeam;
    final isFinished = match.isFinished;
    final isLive = match.isLive;

    return Container(
      key: ValueKey('lol-match-card-${match.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLive
              ? AppColors.error.withValues(alpha: 0.6)
              : AppColors.cardBorderDark,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.cardBorderDark),
              ),
            ),
            child: Row(
              children: [
                if (match.roundName != null && match.roundName!.isNotEmpty) ...[
                  Text(
                    match.roundName!.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else if (match.effectiveRoundNumber != null) ...[
                  Text(
                    'RONDA ${match.effectiveRoundNumber}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const Spacer(),
                if (match.format != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      match.format!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (isLive) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'EN VIVO',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ] else if (isFinished) ...[
                  const Text(
                    'FINAL',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ] else ...[
                  Text(
                    _formatTime(match.startTime),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              children: [
                _buildTeamRow(
                  participant: home,
                  isWinner: isFinished && match.winnerTeamId == home.id,
                  score: home.score,
                ),
                const SizedBox(height: 8),
                _buildTeamRow(
                  participant: away,
                  isWinner: isFinished && match.winnerTeamId == away.id,
                  score: away.score,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamRow({
    required LolWorldsParticipantModel participant,
    required bool isWinner,
    required int? score,
  }) {
    return Row(
      children: [
        if (participant.logoUrl != null &&
            participant.logoUrl!.trim().isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              participant.logoUrl!,
              width: 22,
              height: 22,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.shield_outlined,
                size: 20,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ] else ...[
          const Icon(
            Icons.shield_outlined,
            size: 20,
            color: AppColors.textMuted,
          ),
        ],
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  participant.name,
                  style: TextStyle(
                    color: isWinner
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: isWinner ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (participant.code != null &&
                  participant.code!.isNotEmpty &&
                  participant.code != participant.name) ...[
                const SizedBox(width: 6),
                Text(
                  participant.code!,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
              if (participant.record != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    participant.record!,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (score != null) ...[
          Text(
            '$score',
            style: TextStyle(
              color: isWinner ? AppColors.primary : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ] else ...[
          const Text(
            '—',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }

  // =========================================================================
  // PESTAÑA 1: TABLA SUIZA
  // =========================================================================

  Widget _buildStandingsTab(LolWorldsStageModel data) {
    final standings = data.swissStandings;

    if (standings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.table_chart_outlined,
                size: 40,
                color: AppColors.textMuted.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'Sin registro de posiciones',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'El proveedor oficial aún no ha publicado el registro de la etapa suiza.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorderDark),
            ),
            child: Column(
              children: [
                _buildStandingsHeader(),
                ...standings.map(_buildStandingRow),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandingsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorderDark)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '#',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'EQUIPO',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              'RÉCORD',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            width: 34,
            child: Text(
              'DIF',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandingRow(LolSwissStandingEntryModel entry) {
    final hasAdvancement = entry.advancementStatus != null ||
        (entry.advancementText != null && entry.advancementText!.isNotEmpty);

    Color? rowAccentColor;
    if (entry.isQualified) {
      rowAccentColor = AppColors.success;
    } else if (entry.isEliminated) {
      rowAccentColor = AppColors.error;
    }

    return Container(
      key: ValueKey('lol-standing-row-${entry.position}'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorderDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 22,
                child: Text(
                  '${entry.position}',
                  style: TextStyle(
                    color: rowAccentColor ?? AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (entry.teamLogo != null && entry.teamLogo!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    entry.teamLogo!,
                    width: 20,
                    height: 20,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(width: 20),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.teamName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.teamCode != null &&
                        entry.teamCode!.isNotEmpty &&
                        entry.teamCode != entry.teamName) ...[
                      const SizedBox(width: 6),
                      Text(
                        entry.teamCode!,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  entry.record,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: rowAccentColor ?? AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              SizedBox(
                width: 34,
                child: Text(
                  entry.diff != null
                      ? (entry.diff! > 0 ? '+${entry.diff}' : '${entry.diff}')
                      : '—',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (hasAdvancement) ...[
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 4),
              child: _buildAdvancementBadge(entry),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancementBadge(LolSwissStandingEntryModel entry) {
    final text = entry.advancementText ??
        (entry.isQualified
            ? 'Clasificado a Cuartos'
            : entry.isEliminated
                ? 'Eliminado'
                : 'En competencia');

    final color = entry.isQualified
        ? AppColors.success
        : entry.isEliminated
            ? AppColors.error
            : AppColors.primary;

    return Container(
      key: ValueKey('lol-advancement-badge-${entry.position}'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildEmptyMatchesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 40,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'No hay partidos en esta ronda',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'La fase o ronda seleccionada no cuenta con encuentros programados en el proveedor oficial.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCoverageView(LolWorldsStageModel data) {
    final String title;
    final String subtitle;
    final IconData icon;

    if (data.isUnconfigured) {
      title = 'Cobertura oficial no disponible';
      subtitle = data.message ??
          'La fuente oficial de Worlds requiere credenciales de API (LOL_ESPORTS_API_KEY o PANDASCORE_API_KEY) no configuradas en el entorno.';
      icon = Icons.lock_outline_rounded;
    } else if (data.isNoCoverage) {
      title = 'Sin cobertura del proveedor';
      subtitle = data.message ??
          'El proveedor oficial no reporta partidos ni fases activas para esta edición de Worlds.';
      icon = Icons.sports_esports_outlined;
    } else if (data.isRateLimited) {
      title = 'Límite de solicitudes alcanzado';
      subtitle = data.message ??
          'Se ha superado la cuota de consultas hacia el proveedor oficial de League of Legends. Por favor, intenta más tarde.';
      icon = Icons.timer_outlined;
    } else if (data.isUnauthorized) {
      title = 'Acceso no autorizado';
      subtitle = data.message ??
          'El proveedor oficial denegó el acceso a las estadísticas de League of Legends.';
      icon = Icons.security_outlined;
    } else if (data.isProviderError) {
      title = 'Error de conexión con el proveedor';
      subtitle = data.message ??
          'No se pudo conectar con el servicio oficial de League of Legends.';
      icon = Icons.cloud_off_outlined;
    } else if (data.isEmpty) {
      title = 'Sin información disponible';
      subtitle = data.message ??
          'Actualmente no hay partidas ni etapas activas registradas para Worlds en el proveedor oficial.';
      icon = Icons.event_busy_rounded;
    } else {
      title = 'Cobertura oficial no disponible';
      subtitle = data.message ??
          'No hay información confirmada por el proveedor oficial para esta edición de Worlds.';
      icon = Icons.lock_outline_rounded;
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorderDark),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_outlined, size: 16, color: AppColors.textMuted),
                  SizedBox(width: 8),
                  Text(
                    'Sin datos simulados ni fixtures inventados',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: widget.onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Comprobar disponibilidad'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _BracketConnectorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = AppColors.cardBorderDark
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final midX = size.width / 2;

    void drawPath(Path path) {
      canvas.drawPath(path, paintLine);
    }

    final pathTop = Path()
      ..moveTo(0, size.height * 0.25)
      ..lineTo(midX, size.height * 0.25)
      ..lineTo(midX, size.height * 0.48)
      ..lineTo(size.width, size.height * 0.48);
    drawPath(pathTop);

    final pathBottom = Path()
      ..moveTo(0, size.height * 0.75)
      ..lineTo(midX, size.height * 0.75)
      ..lineTo(midX, size.height * 0.52)
      ..lineTo(size.width, size.height * 0.52);
    drawPath(pathBottom);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
