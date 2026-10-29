import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/event_model.dart';
import '../../../../models/event_status.dart';
import '../../../../models/football_detail_model.dart';
import '../../../../models/team_model.dart';

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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title('Momentos del partido'),
        const SizedBox(height: 14),
        _timelineTeamsHeader(event),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1, color: AppColors.border),
        ),
        for (var i = 0; i < incidents.length; i++)
          _timelineItem(
            incidents[i],
            isFirst: i == 0,
            isLast: i == incidents.length - 1,
          ),
      ],
    );
  }

  Widget _timelineTeamsHeader(EventModel event) {
    return Row(
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  event.participant1Name,
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _smallTeamLogo(event.homeTeam),
            ],
          ),
        ),
        const SizedBox(width: 28),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _smallTeamLogo(event.awayTeam),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  event.participant2Name,
                  textAlign: TextAlign.start,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _smallTeamLogo(TeamModel? team) {
    const fallback = Icon(
      Icons.shield_outlined,
      size: 20,
      color: AppColors.textMuted,
    );
    final url = team?.logoUrl;
    if (url == null || url.isEmpty) return fallback;
    return SizedBox(
      width: 24,
      height: 24,
      child: Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }

  Widget _timelineItem(
    FootballIncident item, {
    required bool isFirst,
    required bool isLast,
  }) {
    final isHome = item.side == 'home';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: isHome
                  ? _buildIncidentDetails(item, isHome: true)
                  : _buildMinuteText(item.minute, alignRight: true),
            ),
          ),
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: isFirst ? Colors.transparent : AppColors.border,
                  ),
                ),
                _incidentBadge(item.kind),
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: isLast ? Colors.transparent : AppColors.border,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: isHome
                  ? _buildMinuteText(item.minute, alignRight: false)
                  : _buildIncidentDetails(item, isHome: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinuteText(String? minute, {required bool alignRight}) {
    return Text(
      minute ?? '—',
      textAlign: alignRight ? TextAlign.end : TextAlign.start,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildIncidentDetails(FootballIncident item, {required bool isHome}) {
    final alignment =
        isHome ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textAlign = isHome ? TextAlign.end : TextAlign.start;

    switch (item.kind) {
      case 'goal':
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: alignment,
          children: [
            Text(
              item.player ?? 'Gol',
              textAlign: textAlign,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: AppColors.textPrimary,
              ),
            ),
            if (item.secondaryPlayer != null &&
                item.secondaryPlayer!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Asista: ${item.secondaryPlayer}',
                textAlign: textAlign,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        );

      case 'yellowCard':
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: alignment,
          children: [
            Text(
              item.player ?? 'Tarjeta amarilla',
              textAlign: textAlign,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: AppColors.warning,
              ),
            ),
          ],
        );

      case 'redCard':
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: alignment,
          children: [
            Text(
              item.player ?? 'Tarjeta roja',
              textAlign: textAlign,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: AppColors.liveRed,
              ),
            ),
          ],
        );

      default:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: alignment,
          children: [
            if (item.player != null)
              Text(
                '↑ ${item.player}',
                textAlign: textAlign,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.soccer,
                ),
              ),
            if (item.secondaryPlayer != null) ...[
              const SizedBox(height: 2),
              Text(
                '↓ ${item.secondaryPlayer}',
                textAlign: textAlign,
                style: const TextStyle(
                  color: AppColors.liveRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        );
    }
  }

  Widget _incidentBadge(String kind) {
    final (Color bgColor, Color borderColor, Widget icon) = switch (kind) {
      'goal' => (
        AppColors.primary.withValues(alpha: 0.12),
        AppColors.primary.withValues(alpha: 0.35),
        const Icon(
          Icons.sports_soccer,
          size: 17,
          color: AppColors.primary,
        ),
      ),
      'yellowCard' => (
        const Color(0xFFF59E0B).withValues(alpha: 0.14),
        const Color(0xFFF59E0B).withValues(alpha: 0.45),
        Container(
          width: 11,
          height: 15,
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
      'redCard' => (
        AppColors.liveRed.withValues(alpha: 0.12),
        AppColors.liveRed.withValues(alpha: 0.4),
        Container(
          width: 11,
          height: 15,
          decoration: BoxDecoration(
            color: AppColors.liveRed,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
      _ => (
        AppColors.surfaceMuted,
        AppColors.border,
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.arrow_downward_rounded,
              size: 12,
              color: AppColors.liveRed,
            ),
            Icon(
              Icons.arrow_upward_rounded,
              size: 12,
              color: AppColors.soccer,
            ),
          ],
        ),
      ),
    };

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: Border.all(color: borderColor, width: 1.2),
      ),
      alignment: Alignment.center,
      child: icon,
    );
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
