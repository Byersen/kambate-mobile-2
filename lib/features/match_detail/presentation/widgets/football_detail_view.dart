import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/event_model.dart';
import '../../../../models/event_status.dart';
import '../../../../models/football_detail_model.dart';

class FootballDetailView extends StatefulWidget {
  final EventModel event;
  const FootballDetailView({super.key, required this.event});
  @override
  State<FootballDetailView> createState() => _FootballDetailViewState();
}

class _FootballDetailViewState extends State<FootballDetailView> {
  int _section = 0;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final parsed = FootballDetailModel.parse(
      event.footballStats?.extraStats?['detail'],
    );
    final detail =
        parsed?.homeParticipantId == event.homeTeam?.id &&
            parsed?.awayParticipantId == event.awayTeam?.id
        ? parsed
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (index, label) in [
                'Resumen',
                'Estadísticas',
                'Alineaciones',
              ].indexed)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: _section == index,
                    showCheckmark: false,
                    selectedColor: AppColors.primary,
                    side: BorderSide.none,
                    backgroundColor: AppColors.surfaceMuted,
                    labelStyle: TextStyle(
                      color: _section == index
                          ? AppColors.onPrimary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => setState(() => _section = index),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        switch (_section) {
          0 => _summaryView(event, detail),
          1 => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _statistics(event, detail),
              ),
            ),
          _ => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _lineup(event.participant1Name, detail?.homeLineup),
                    const Divider(height: 32),
                    _lineup(event.participant2Name, detail?.awayLineup),
                  ],
                ),
              ),
            ),
        },
      ],
    );
  }

  Widget _summaryView(EventModel event, FootballDetailModel? detail) {
    final keyStats = _extractKeyStats(detail?.statistics ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _summaryTimeline(event, detail),
          ),
        ),
        if (keyStats.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _keyStatsSection(keyStats),
            ),
          ),
        ],
      ],
    );
  }

  Widget _summaryTimeline(EventModel event, FootballDetailModel? detail) {
    final incidents = detail?.timeline;
    if (incidents == null || incidents.isEmpty) {
      return _empty(
        Icons.sports_soccer_outlined,
        'Momentos del partido',
        event.status == EventStatus.scheduled
            ? 'El partido aún no comienza. La cronología aparecerá cuando esté disponible.'
            : incidents == null
            ? 'La cronología no está disponible para este encuentro.'
            : 'No hay incidencias registradas en los datos recibidos.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Momentos del partido'),
        const SizedBox(height: 16),
        for (var i = 0; i < incidents.length; i++)
          _timelineItem(event, incidents[i], isLast: i == incidents.length - 1),
      ],
    );
  }

  Widget _timelineItem(
    EventModel event,
    FootballIncident item, {
    required bool isLast,
  }) {
    final label = switch (item.kind) {
      'goal' => 'Gol',
      'yellowCard' => 'Tarjeta amarilla',
      'redCard' => 'Tarjeta roja',
      _ => 'Cambio',
    };

    final teamName =
        item.side == 'home' ? event.participant1Name : event.participant2Name;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Text(
              item.minute ?? '—',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceMuted,
                ),
                alignment: Alignment.center,
                child: _incidentIcon(item.kind),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    teamName,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  if (item.player != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${item.kind == 'substitution' ? 'Entra: ' : ''}${item.player}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                  if (item.secondaryPlayer != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${item.kind == 'substitution' ? 'Sale' : 'Asistencia'}: ${item.secondaryPlayer}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (!isLast) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppColors.surfaceMuted),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _incidentIcon(String kind) {
    switch (kind) {
      case 'goal':
        return const Icon(
          Icons.sports_soccer,
          size: 18,
          color: AppColors.textPrimary,
        );
      case 'yellowCard':
        return Container(
          width: 12,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      case 'redCard':
        return Container(
          width: 12,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      default:
        return const Icon(
          Icons.swap_horiz_rounded,
          size: 18,
          color: AppColors.textSecondary,
        );
    }
  }

  List<FootballStatistic> _extractKeyStats(List<FootballStatistic> all) {
    if (all.isEmpty) return [];
    final desired = ['possession', 'shotsOnTarget', 'corners'];
    final result = <FootballStatistic>[];

    for (final key in desired) {
      final label = switch (key) {
        'possession' => 'Posesión',
        'shotsOnTarget' => 'Tiros al arco',
        'corners' => 'Córners',
        _ => '',
      };
      final found = all.where((s) => s.label == label).firstOrNull;
      if (found != null && (found.home != null || found.away != null)) {
        result.add(found);
      }
    }
    return result;
  }

  Widget _keyStatsSection(List<FootballStatistic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title('Estadísticas clave'),
        const SizedBox(height: 16),
        for (final stat in stats) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  stat.display(stat.home),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  stat.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  stat.display(stat.away),
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _statProgressBar(stat),
          const SizedBox(height: 16),
        ],
        const Divider(height: 1),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => setState(() => _section = 1),
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Ver todas las estadísticas',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statProgressBar(FootballStatistic stat) {
    if (stat.home != null &&
        stat.away != null &&
        stat.home! + stat.away! > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          minHeight: 6,
          value: stat.home! / (stat.home! + stat.away!),
          color: AppColors.primary,
          backgroundColor: const Color(0xFFD8E2ED),
        ),
      );
    }
    return const Divider(height: 6, thickness: 2);
  }

  Widget _statistics(EventModel event, FootballDetailModel? detail) {
    final stats = detail?.statistics ?? [];
    if (stats.isEmpty) {
      return _empty(
        Icons.bar_chart_rounded,
        'Estadísticas no disponibles',
        event.status == EventStatus.scheduled
            ? 'Las estadísticas se publicarán cuando comience el partido y haya cobertura.'
            : 'No se han recibido estadísticas para este encuentro.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title('Comparativa de equipos'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                event.participant1Name,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                event.participant2Name,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          '— Dato no disponible',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        for (final stat in stats) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  stat.display(stat.home),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(stat.label, textAlign: TextAlign.center),
              ),
              Expanded(
                child: Text(
                  stat.display(stat.away),
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _statProgressBar(stat),
        ],
      ],
    );
  }

  Widget _lineup(String team, FootballLineup? lineup) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _title(team),
      const SizedBox(height: 8),
      if (lineup?.formation != null)
        Text(
          'Formación ${lineup!.formation}',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      if (lineup == null)
        const Text(
          'Alineación no disponible',
          style: TextStyle(color: AppColors.textSecondary),
        )
      else ...[
        _players('Titulares', lineup.starters),
        _players('Suplentes', lineup.substitutes),
      ],
    ],
  );

  Widget _players(String title, List<FootballPlayer>? players) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 14),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      if (players == null || players.isEmpty)
        const Text(
          'Información no disponible',
          style: TextStyle(color: AppColors.textSecondary),
        )
      else
        for (final player in players)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    player.number ?? '—',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(player.name),
                      if (player.position != null)
                        Text(
                          player.position!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    ],
  );

  Widget _title(String text) => Text(
    text,
    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
  );

  Widget _empty(IconData icon, String title, String message) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Column(
      children: [
        Icon(icon, size: 32, color: AppColors.textMuted),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

