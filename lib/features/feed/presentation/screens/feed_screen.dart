import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../models/event_model.dart';
import '../../../../models/event_status.dart';
import '../../../../models/sport_type.dart';
import '../../../favorites/providers/favorites_provider.dart';
import '../../providers/feed_provider.dart';
import '../widgets/date_filter_carousel.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  bool _isEventFollowed(EventModel event, Set<String> followedTeamIds) {
    if (followedTeamIds.isEmpty) return false;
    if (event.homeTeam != null && followedTeamIds.contains(event.homeTeam!.id)) return true;
    if (event.awayTeam != null && followedTeamIds.contains(event.awayTeam!.id)) return true;
    if (event.fighter1 != null && followedTeamIds.contains(event.fighter1!.id)) return true;
    if (event.fighter2 != null && followedTeamIds.contains(event.fighter2!.id)) return true;
    for (final p in event.participants) {
      if (followedTeamIds.contains(p.id)) return true;
    }
    return false;
  }

  static const _featuredKeywords = [
    'libertadores', 'sudamericana', 'champions', 'europa league',
    'conference league', 'copa america', 'eurocopa', 'euro ',
    'mundial', 'world cup', 'supercopa de europa', 'copa del rey',
  ];

  bool _isFeatured(String leagueName) {
    final l = leagueName.toLowerCase();
    return _featuredKeywords.any((kw) => l.contains(kw));
  }

  Map<String, List<EventModel>> _groupByLeague(List<EventModel> events) {
    final map = <String, List<EventModel>>{};
    for (final e in events) {
      map.putIfAbsent(e.league, () => []).add(e);
    }
    return map;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedFeedDateProvider);
    final followedTeamIds = ref.watch(favoriteTeamIdsProvider);
    final followedLeagues = ref.watch(followedLeaguesProvider);
    final feedAsync = ref.watch(feedNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'KAMBATE',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
      body: feedAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Error al cargar eventos: $error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.read(feedNotifierProvider.notifier).loadEvents(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (allEvents) {
          // ── Días con eventos para el carrusel
          final Set<String> daysWithEvents = {};
          for (final e in allEvents) {
            final key =
                '${e.startTime.year}-${e.startTime.month.toString().padLeft(2, '0')}-${e.startTime.day.toString().padLeft(2, '0')}';
            daysWithEvents.add(key);
          }

          // ── Eventos del día seleccionado
          final dayEvents = allEvents
              .where((e) => AppDateFormatter.isSameDay(e.startTime, selectedDate))
              .toList();

          final isToday = AppDateFormatter.getRelativeDayName(selectedDate) == 'Hoy';

          // ── SECCIÓN 1: MIS EQUIPOS
          final myTeamEvents = dayEvents
              .where((e) => _isEventFollowed(e, followedTeamIds))
              .toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime));
          final myTeamIds = myTeamEvents.map((e) => e.id).toSet();
          final myTeamByLeague = _groupByLeague(myTeamEvents);

          // ── SECCIÓN 2: COMPETICIONES DESTACADAS
          final featuredEvents = dayEvents
              .where((e) => !myTeamIds.contains(e.id) && _isFeatured(e.league))
              .toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime));
          final featuredByLeague = _groupByLeague(featuredEvents);

          // ── SECCIÓN 3: MIS LIGAS
          final shownIds = {...myTeamIds, ...featuredEvents.map((e) => e.id)};
          final myLeagueEvents = dayEvents.where((e) {
            if (shownIds.contains(e.id)) return false;
            if (followedLeagues.isEmpty) return false;
            final ll = e.league.toLowerCase();
            return followedLeagues.any((fl) => ll.contains(fl));
          }).toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime));
          final myLeagueByLeague = _groupByLeague(myLeagueEvents);

          final hasContent = myTeamEvents.isNotEmpty ||
              featuredEvents.isNotEmpty ||
              myLeagueEvents.isNotEmpty;

          // ── SECCIÓN 4: OTROS PARTIDOS
          final allShownIds = {...shownIds, ...myLeagueEvents.map((e) => e.id)};
          final otherEvents = dayEvents
              .where((e) => !allShownIds.contains(e.id))
              .toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime));
          final otherEventsByLeague = _groupByLeague(otherEvents);

          final carousel = DateFilterCarousel(
            selectedDate: selectedDate,
            daysWithEvents: daysWithEvents,
            onDateSelected: (date) {
              ref.read(selectedFeedDateProvider.notifier).state = date;
            },
          );

          if (dayEvents.isEmpty) {
            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceDark,
              onRefresh: () async {
                await ref.read(feedNotifierProvider.notifier).loadEvents(forceRefresh: true);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  carousel,
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.65,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceDark,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.cardBorderDark),
                              ),
                              child: const Icon(
                                Icons.event_busy_rounded,
                                size: 40,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'No hay partidos programados para el ${AppDateFormatter.formatCarouselLabel(selectedDate)}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Explora otros días en el carrusel superior o vuelve al día de hoy.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            if (!isToday) ...[
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                onPressed: () {
                                  final now = DateTime.now();
                                  ref.read(selectedFeedDateProvider.notifier).state =
                                      DateTime(now.year, now.month, now.day);
                                },
                                icon: const Icon(Icons.today_rounded, size: 15),
                                label: const Text('Ir a Hoy'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceDark,
            onRefresh: () async {
              await ref.read(feedNotifierProvider.notifier).loadEvents(forceRefresh: true);
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                carousel,
                const SizedBox(height: 4),
                // ── SECCIÓN 1: MIS EQUIPOS ──────────────────────────────
                      if (myTeamEvents.isNotEmpty) ...[
                        _FeedSectionHeader(
                          label: 'MIS EQUIPOS',
                          icon: Icons.star_rounded,
                          iconColor: AppColors.warning,
                          count: myTeamEvents.length,
                        ),
                        for (final entry in myTeamByLeague.entries)
                          _LeagueBlock(
                            leagueName: entry.key,
                            events: entry.value,
                            followedTeamIds: followedTeamIds,
                            isFollowedFn: _isEventFollowed,
                            onEventTap: (e) => context.push('/detail/${e.id}', extra: e),
                          ),
                      ],

                      // ── SECCIÓN 2: COMPETICIONES DESTACADAS ─────────────────
                      if (featuredEvents.isNotEmpty) ...[
                        _FeedSectionHeader(
                          label: 'COMPETICIONES DESTACADAS',
                          icon: Icons.emoji_events_rounded,
                          iconColor: AppColors.primary,
                          count: featuredEvents.length,
                        ),
                        for (final entry in featuredByLeague.entries)
                          _LeagueBlock(
                            leagueName: entry.key,
                            events: entry.value,
                            followedTeamIds: followedTeamIds,
                            isFollowedFn: _isEventFollowed,
                            onEventTap: (e) => context.push('/detail/${e.id}', extra: e),
                          ),
                      ],

                      // ── SECCIÓN 3: MIS LIGAS ────────────────────────────────
                      if (myLeagueEvents.isNotEmpty) ...[
                        _FeedSectionHeader(
                          label: 'MIS LIGAS',
                          icon: Icons.shield_rounded,
                          iconColor: AppColors.secondary,
                          count: myLeagueEvents.length,
                        ),
                        for (final entry in myLeagueByLeague.entries)
                          _LeagueBlock(
                            leagueName: entry.key,
                            events: entry.value,
                            followedTeamIds: followedTeamIds,
                            isFollowedFn: _isEventFollowed,
                            onEventTap: (e) => context.push('/detail/${e.id}', extra: e),
                          ),
                      ],

                      // ── SECCIÓN 4: OTRAS LIGAS ──
                      if (otherEvents.isNotEmpty) ...[
                        _FeedSectionHeader(
                          label: 'OTRAS LIGAS',
                          icon: Icons.public_rounded,
                          iconColor: AppColors.textMuted,
                          count: otherEvents.length,
                        ),
                        for (final entry in otherEventsByLeague.entries)
                          _LeagueBlock(
                            leagueName: entry.key,
                            events: entry.value,
                            followedTeamIds: followedTeamIds,
                            isFollowedFn: _isEventFollowed,
                            onEventTap: (e) => context.push('/detail/${e.id}', extra: e),
                          ),
                      ],
                    ],
                  ),
          );
        },
      ),
    );
  }
}

// ─── Header de sección con badge de contador ──────────────────────────────────
class _FeedSectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final int? count;

  const _FeedSectionHeader({
    required this.label,
    required this.icon,
    required this.iconColor,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: iconColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: iconColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: iconColor.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bloque colapsable de una liga ────────────────────────────────────────────
class _LeagueBlock extends ConsumerStatefulWidget {
  final String leagueName;
  final List<EventModel> events;
  final Set<String> followedTeamIds;
  final bool Function(EventModel, Set<String>) isFollowedFn;
  final void Function(EventModel) onEventTap;

  const _LeagueBlock({
    required this.leagueName,
    required this.events,
    required this.followedTeamIds,
    required this.isFollowedFn,
    required this.onEventTap,
  });

  @override
  ConsumerState<_LeagueBlock> createState() => _LeagueBlockState();
}

class _LeagueBlockState extends ConsumerState<_LeagueBlock> {
  bool _expanded = true;

  bool get _hasFollowed => widget.events.any(
        (e) => widget.isFollowedFn(e, widget.followedTeamIds),
      );

  SportType get _sport =>
      widget.events.isNotEmpty ? widget.events.first.sport : SportType.soccer;

  String? _getFlagEmoji(String? country) {
    if (country == null) return null;
    final c = country.toLowerCase();
    if (c.contains('argentina')) return '🇦🇷';
    if (c.contains('brasil') || c.contains('brazil')) return '🇧🇷';
    if (c.contains('chile')) return '🇨🇱';
    if (c.contains('colombia')) return '🇨🇴';
    if (c.contains('mexico') || c.contains('méxico')) return '🇲🇽';
    if (c.contains('estados unidos') || c.contains('usa')) return '🇺🇸';
    if (c.contains('españa') || c.contains('spain')) return '🇪🇸';
    if (c.contains('inglaterra') || c.contains('england')) return '🏴󠁧󠁢󠁥󠁮󠁧󠁿';
    if (c.contains('italia') || c.contains('italy')) return '🇮🇹';
    if (c.contains('alemania') || c.contains('germany')) return '🇩🇪';
    if (c.contains('francia') || c.contains('france')) return '🇫🇷';
    if (c.contains('países bajos') || c.contains('netherlands')) return '🇳🇱';
    if (c.contains('portugal')) return '🇵🇹';
    if (c.contains('europa') || c.contains('europe')) return '🇪🇺';
    if (c.contains('internacional') || c.contains('international') || c.contains('mundo')) return '🌍';
    if (c.contains('turquía') || c.contains('turkey')) return '🇹🇷';
    if (c.contains('sudamérica')) return '🌎';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final sportColor = _sport.color;
    final hasLive = widget.events.any((e) => e.isLive);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hasFollowed
              ? AppColors.warning.withValues(alpha: 0.4)
              : AppColors.cardBorderDark,
          width: _hasFollowed ? 1.2 : 0.8,
        ),
      ),
      child: Column(
        children: [
          // Header de la liga
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  // Bandera o Icono de deporte
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: sportColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Builder(
                      builder: (context) {
                        final country = widget.events.isNotEmpty ? widget.events.first.leagueModel?.country : null;
                        final flag = _getFlagEmoji(country);
                        if (flag != null) {
                          return Text(flag, style: const TextStyle(fontSize: 16));
                        }
                        return Icon(_sport.icon, size: 14, color: sportColor);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Nombre de la liga + badges
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.leagueName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Badge "TU EQUIPO" si hay equipos seguidos en esta liga
                        if (_hasFollowed) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '⭐ TU EQUIPO',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        // Badge EN VIVO
                        if (hasLive) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.liveRed.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'EN VIVO',
                              style: TextStyle(
                                color: AppColors.liveRed,
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Icon(
                          _expanded
                              ? Icons.keyboard_arrow_down_rounded
                              : Icons.chevron_right_rounded,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),

                  // Contador de partidos
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(left: 6, right: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.cardBorderDark, width: 0.7),
                    ),
                    child: Text(
                      '${widget.events.length}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Botón seguir liga
                  GestureDetector(
                    onTap: () {
                      ref.read(followedLeaguesProvider.notifier).toggle(widget.leagueName);
                    },
                    child: Builder(builder: (context) {
                      final isFollowingLeague = ref.watch(followedLeaguesProvider
                          .select((s) => s.contains(widget.leagueName.toLowerCase())));
                      return Icon(
                        isFollowingLeague ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 20,
                        color: isFollowingLeague ? AppColors.warning : AppColors.textMuted,
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

          // Divisor
          if (_expanded) Container(height: 0.5, color: AppColors.cardBorderDark),

          // Lista de partidos
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _expanded
                ? Column(
                    children: [
                      for (int i = 0; i < widget.events.length; i++) ...[
                        _LeagueMatchRow(
                          event: widget.events[i],
                          isFollowed:
                              widget.isFollowedFn(widget.events[i], widget.followedTeamIds),
                          onTap: () => widget.onEventTap(widget.events[i]),
                        ),
                        if (i < widget.events.length - 1)
                          Divider(
                            height: 0.5,
                            thickness: 0.5,
                            indent: 54,
                            color: AppColors.cardBorderDark.withValues(alpha: 0.6),
                          ),
                      ],
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─── Fila compacta de partido ──────────────────────────────────────────────────
class _LeagueMatchRow extends StatelessWidget {
  final EventModel event;
  final bool isFollowed;
  final VoidCallback onTap;

  const _LeagueMatchRow({
    required this.event,
    required this.isFollowed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLive = event.isLive;
    final isFinished = event.status == EventStatus.finished;
    final isCombat = event.isCombat;
    final isEsports =
        event.sport == SportType.lol || event.sport == SportType.valorant;

    // Tiempo
    String timeLabel;
    Color timeColor;
    if (isLive) {
      timeLabel = event.currentPeriod ?? 'EN VIVO';
      timeColor = AppColors.liveRed;
    } else if (isFinished) {
      timeLabel = 'FIN';
      timeColor = AppColors.textMuted;
    } else {
      final h = event.startTime.hour.toString().padLeft(2, '0');
      final m = event.startTime.minute.toString().padLeft(2, '0');
      timeLabel = '$h:$m';
      timeColor = AppColors.primary;
    }

    // Participantes
    String? team1Name, team2Name, score1, score2;
    if (isCombat) {
      team1Name = event.fighter1?.name;
      team2Name = event.fighter2?.name;
    } else if (isEsports) {
      final p = event.participants;
      if (p.isNotEmpty) team1Name = p[0].name;
      if (p.length > 1) team2Name = p[1].name;
    } else {
      team1Name = event.homeTeam?.name;
      team2Name = event.awayTeam?.name;
      if (isLive || isFinished) {
        score1 = event.homeScore?.toString();
        score2 = event.awayScore?.toString();
      }
    }

    String? combinedScore;
    if ((isLive || isFinished) && score1 != null && score2 != null) {
      combinedScore = '$score1 - $score2';
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Hora / estado
            SizedBox(
              width: 46,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    timeLabel,
                    style: TextStyle(
                      color: timeColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (combinedScore != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      combinedScore,
                      style: TextStyle(
                        color: timeColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Separador vertical
            Container(width: 1, height: 36, color: AppColors.cardBorderDark),

            const SizedBox(width: 12),

            // Equipos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _TeamLogo(name: team1Name ?? '?', sport: event.sport),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          team1Name ?? '—',
                          style: TextStyle(
                            color: isFollowed
                                ? AppColors.textPrimary
                                : AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      _TeamLogo(name: team2Name ?? '?', sport: event.sport),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          team2Name ?? '—',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Avatar/logo del equipo ────────────────────────────────────────────────────
class _TeamLogo extends StatelessWidget {
  final String name;
  final SportType sport;

  const _TeamLogo({required this.name, required this.sport});

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : '?';

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: sport.color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: sport.color.withValues(alpha: 0.3), width: 0.8),
      ),
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          color: sport.color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
