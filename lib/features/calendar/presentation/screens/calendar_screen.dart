import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../models/event_model.dart';
import '../../../../models/event_status.dart';
import '../../../../models/sport_type.dart';
import '../../../favorites/providers/favorites_provider.dart';
import '../../../feed/data/feed_repository.dart';
import '../../../feed/providers/connection_provider.dart';
import '../../../feed/providers/feed_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _currentMonth;
  bool _onlyFollowed = false;
  SportType _selectedSport = SportType.all;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _currentMonth = DateTime(now.year, now.month, 1);
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _selectedDate = DateTime(now.year, now.month, now.day);
      _currentMonth = DateTime(now.year, now.month, 1);
    });
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  static const List<String> _monthNames = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  static const List<String> _weekDays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  final List<SportType> _filterSports = [
    SportType.all,
    SportType.soccer,
    SportType.nba,
    SportType.lol,
    SportType.valorant,
    SportType.ufc,
  ];

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(feedNotifierProvider);
    final favoriteTeamIds = ref.watch(favoriteTeamIdsProvider);
    final source = ref.watch(feedDataSourceProvider);
    final updated = ref.watch(feedLastUpdatedProvider);
    final connectionStatus = ref.watch(connectionStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Calendario',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _goToToday,
            icon: const Icon(Icons.today_rounded, size: 16, color: AppColors.primary),
            label: const Text(
              'Hoy',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(feedNotifierProvider.notifier)
            .loadEvents(forceRefresh: true),
        child: eventsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 48,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No pudimos cargar el calendario',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$err',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () => ref
                          .read(feedNotifierProvider.notifier)
                          .loadEvents(forceRefresh: true),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          data: (allEvents) {
            var availableEvents = allEvents
                .where((e) =>
                    e.status != EventStatus.finished &&
                    e.status != EventStatus.archived)
                .toList();

            if (_onlyFollowed && favoriteTeamIds.isNotEmpty) {
              availableEvents = availableEvents.where((e) {
                final hasFollowed =
                    e.participants.any((p) => favoriteTeamIds.contains(p.id));
                return hasFollowed || e.isFavorite;
              }).toList();
            }

            if (_selectedSport != SportType.all) {
              availableEvents =
                  availableEvents.where((e) => e.sport == _selectedSport).toList();
            }

            final Map<String, List<EventModel>> eventsByDay = {};
            for (final event in availableEvents) {
              final local = event.startTime.toLocal();
              final key =
                  '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
              eventsByDay.putIfAbsent(key, () => []).add(event);
            }

            final selectedDayKey =
                '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
            final selectedDayEvents =
                List<EventModel>.from(eventsByDay[selectedDayKey] ?? []);

            // Ordenar por hora local ascendente mezclando deportes, con desempate determinista
            selectedDayEvents.sort((a, b) {
              final cmp = a.startTime.toLocal().compareTo(b.startTime.toLocal());
              if (cmp != 0) return cmp;
              return a.id.compareTo(b.id);
            });

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                if ((source == FeedDataSource.cache ||
                        connectionStatus == ConnectionStatus.offlineCached) &&
                    !eventsAsync.isLoading)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cloud_off_outlined,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              updated == null
                                  ? 'Mostrando datos guardados. Desliza para actualizar.'
                                  : 'Datos guardados · ${AppDateFormatter.formatEventTime(updated)}. Desliza para actualizar.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                _buildFilterBar(),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.chevron_left_rounded),
                            onPressed: _prevMonth,
                            color: AppColors.textPrimary,
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.chevron_right_rounded),
                            onPressed: _nextMonth,
                            color: AppColors.textPrimary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                _buildMonthGrid(eventsByDay),
                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PARTIDOS • ${AppDateFormatter.formatDate(_selectedDate).toUpperCase()}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorderDark),
                        ),
                        child: Text(
                          '${selectedDayEvents.length} encuentros',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                if (selectedDayEvents.isEmpty)
                  Builder(
                    builder: (context) {
                      final now = DateTime.now();
                      final todayMidnight = DateTime(now.year, now.month, now.day);
                      final selectedMidnight =
                          DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
                      final isPastDate = selectedMidnight.isBefore(todayMidnight);

                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
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
                              const SizedBox(height: 12),
                              Text(
                                _onlyFollowed
                                    ? 'No hay partidos de tus equipos seguidos este día'
                                    : (_selectedSport != SportType.all
                                        ? 'No hay partidos de ${_selectedSport.displayName} para esta fecha'
                                        : (isPastDate
                                            ? 'No hay partidos programados ni en vivo para esta fecha'
                                            : 'No hay partidos programados para esta fecha')),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isPastDate
                                    ? 'Los resultados históricos y partidos finalizados se encuentran en la sección Partidos.'
                                    : 'Toca los días con puntos de colores para ver otros encuentros.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              if (isPastDate) ...[
                                const SizedBox(height: 14),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    ref.read(selectedFeedDateProvider.notifier).state =
                                        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
                                    context.go('/feed');
                                  },
                                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                                  label: const Text('Ver resultados en Partidos'),
                                ),
                              ],
                              if (_onlyFollowed || _selectedSport != SportType.all) ...[
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _onlyFollowed = false;
                                      _selectedSport = SportType.all;
                                    });
                                  },
                                  child: const Text('Restablecer filtros'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  )
                else
                  ...selectedDayEvents.map((event) => _SimpleMatchRow(
                        event: event,
                        onTap: () => context.push('/detail/${event.id}', extra: event),
                      )),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _onlyFollowed = !_onlyFollowed),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _onlyFollowed ? AppColors.warning : AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _onlyFollowed ? AppColors.warning : AppColors.cardBorderDark,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _onlyFollowed ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 14,
                      color: _onlyFollowed ? AppColors.onPrimary : AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Siguiendo',
                      style: TextStyle(
                        color: _onlyFollowed ? AppColors.onPrimary : AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(width: 1, height: 20, color: AppColors.cardBorderDark),
            const SizedBox(width: 8),

            ..._filterSports.map((sport) {
              final isSelected = _selectedSport == sport;
              final sportColor = sport == SportType.all ? AppColors.primary : sport.color;

              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedSport = sport),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? sportColor.withValues(alpha: 0.2) : AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? sportColor : AppColors.cardBorderDark,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          sport.icon,
                          size: 13,
                          color: isSelected ? sportColor : AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          sport.displayName,
                          style: TextStyle(
                            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthGrid(Map<String, List<EventModel>> eventsByDay) {
    final year = _currentMonth.year;
    final month = _currentMonth.month;

    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday;

    final List<Widget> dayWidgets = [];

    for (final dayName in _weekDays) {
      dayWidgets.add(
        Center(
          child: Text(
            dayName,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    for (int i = 1; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox.shrink());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final key = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final dayEvents = eventsByDay[key] ?? [];
      final hasEvents = dayEvents.isNotEmpty;
      final isSelected = _selectedDate.year == year &&
          _selectedDate.month == month &&
          _selectedDate.day == day;
      final isToday = DateTime.now().year == year &&
          DateTime.now().month == month &&
          DateTime.now().day == day;

      final uniqueSports = dayEvents.map((e) => e.sport).toSet().take(3).toList();

      dayWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : (isToday ? AppColors.surfaceDark : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
              border: isToday && !isSelected
                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.6))
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.onPrimary
                        : (isToday ? AppColors.primary : AppColors.textPrimary),
                    fontSize: 12,
                    fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (hasEvents)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: uniqueSports.map((sport) {
                      final dotColor = isSelected ? AppColors.onPrimary : sport.color;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
                        width: 3.5,
                        height: 3.5,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  )
                else
                  const SizedBox(height: 5.5),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorderDark),
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 7,
        childAspectRatio: 1.2,
        children: dayWidgets,
      ),
    );
  }
}

class _SimpleMatchRow extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;

  const _SimpleMatchRow({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final team1Name = event.participant1Name;
    final team2Name = event.participant2Name;

    final local = event.startTime.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');

    String timeStr;
    Color timeColor;
    if (event.isLive) {
      timeStr = 'EN VIVO';
      timeColor = AppColors.liveRed;
    } else if (event.status == EventStatus.finished) {
      timeStr = 'FIN';
      timeColor = AppColors.textMuted;
    } else if (event.status == EventStatus.canceled) {
      timeStr = 'CANC';
      timeColor = AppColors.textMuted;
    } else if (event.status == EventStatus.postponed) {
      timeStr = 'APLAZ';
      timeColor = AppColors.warning;
    } else {
      timeStr = '$h:$m';
      timeColor = AppColors.textSecondary;
    }

    Widget timeWidget;
    if (event.isLive) {
      timeWidget = Semantics(
        container: true,
        label: 'En vivo',
        child: Container(
          key: const ValueKey('live_indicator_dot'),
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.liveRed,
            shape: BoxShape.circle,
          ),
        ),
      );
    } else {
      timeWidget = Text(
        timeStr,
        style: TextStyle(
          color: timeColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    String matchText = '$team1Name vs $team2Name';
    if ((event.isLive || event.status == EventStatus.finished) &&
        !event.isCombat) {
      if (event.homeScore != null && event.awayScore != null) {
        matchText = '$team1Name ${event.homeScore} - ${event.awayScore} $team2Name';
      } else if (event.status == EventStatus.finished &&
          event.score != null &&
          event.score != 'vs' &&
          event.score!.trim().isNotEmpty) {
        matchText = '$team1Name vs $team2Name • ${event.score}';
      }
    } else if (event.isCombat &&
        (event.status == EventStatus.finished || event.isLive) &&
        (event.fightResult != null || event.score != null)) {
      final res = event.fightResult ?? event.score;
      matchText = '$team1Name vs $team2Name • $res';
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: event.sport.color.withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 54),
              child: timeWidget,
            ),
            const SizedBox(width: 6),
            Container(width: 1, height: 16, color: AppColors.cardBorderDark),
            const SizedBox(width: 10),
            Icon(event.sport.icon, size: 14, color: event.sport.color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                matchText,
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
      ),
    );
  }
}
