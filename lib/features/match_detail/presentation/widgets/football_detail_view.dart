import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
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

    final halftimeScore = _computeHalftimeScore(incidents);
    final startTimeText = AppDateFormatter.formatEventTime(event.startTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title('Momentos del partido'),
        const SizedBox(height: 12),
        for (var i = 0; i < incidents.length; i++) ...[
          if (i > 0 &&
              _isHalfTransition(incidents[i - 1].minute, incidents[i].minute))
            _timelineDivider('Medio tiempo $halftimeScore'),
          _timelineItem(incidents[i]),
        ],
        const SizedBox(height: 4),
        _timelineDivider('Empieza el partido $startTimeText'),
      ],
    );
  }

  int? _parseBaseMinute(String? raw) {
    if (raw == null) return null;
    final match = RegExp(r'(\d+)').firstMatch(raw);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  bool _isHalfTransition(String? prevMinute, String? currMinute) {
    final prev = _parseBaseMinute(prevMinute);
    final curr = _parseBaseMinute(currMinute);
    if (prev == null || curr == null) return false;
    return (prev <= 45 && curr > 45) || (prev > 45 && curr <= 45);
  }

  String _computeHalftimeScore(List<FootballIncident> incidents) {
    var homeGoals = 0;
    var awayGoals = 0;
    for (final item in incidents) {
      if (item.kind != 'goal') continue;
      final minute = _parseBaseMinute(item.minute);
      if (minute != null && minute <= 45) {
        if (item.side == 'home') {
          homeGoals++;
        } else {
          awayGoals++;
        }
      }
    }
    return '$homeGoals-$awayGoals';
  }

  Widget _timelineDivider(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
          Flexible(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
        ],
      ),
    );
  }

  Widget _timelineItem(FootballIncident item) {
    final isHome = item.side == 'home';
    final minuteText = item.minute ?? '—';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: isHome
            ? [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 38),
                  child: Text(
                    minuteText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _incidentIcon(item.kind),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildIncidentText(item, alignRight: false),
                ),
              ]
            : [
                Expanded(
                  child: _buildIncidentText(item, alignRight: true),
                ),
                const SizedBox(width: 12),
                _incidentIcon(item.kind),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 38),
                  child: Text(
                    minuteText,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
      ),
    );
  }

  Widget _buildIncidentText(FootballIncident item, {required bool alignRight}) {
    final alignment =
        alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textAlign = alignRight ? TextAlign.end : TextAlign.start;

    final primaryLabel = switch (item.kind) {
      'goal' => item.player ?? 'Gol',
      'yellowCard' => item.player ?? 'Tarjeta amarilla',
      'redCard' => item.player ?? 'Tarjeta roja',
      _ => item.player ?? 'Cambio',
    };

    final secondaryLabel = switch (item.kind) {
      'goal'
          when item.secondaryPlayer != null &&
              item.secondaryPlayer!.isNotEmpty =>
        'Asista: ${item.secondaryPlayer}',
      'substitution'
          when item.secondaryPlayer != null &&
              item.secondaryPlayer!.isNotEmpty =>
        'para ${item.secondaryPlayer}',
      _ => null,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        Text(
          primaryLabel,
          textAlign: textAlign,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        if (secondaryLabel != null) ...[
          const SizedBox(height: 2),
          Text(
            secondaryLabel,
            textAlign: textAlign,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _incidentIcon(String kind) {
    switch (kind) {
      case 'goal':
        return const SizedBox(
          width: 22,
          height: 22,
          child: Icon(
            Icons.sports_soccer,
            size: 20,
            color: AppColors.primary,
          ),
        );
      case 'yellowCard':
        return SizedBox(
          width: 22,
          height: 22,
          child: Center(
            child: Container(
              width: 13,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFFACC15),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
        );
      case 'redCard':
        return SizedBox(
          width: 22,
          height: 22,
          child: Center(
            child: Container(
              width: 13,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.liveRed,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
        );
      default:
        return const SizedBox(
          width: 22,
          height: 22,
          child: CustomPaint(
            painter: _SubstitutionCyclePainter(),
          ),
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

class _SubstitutionCyclePainter extends CustomPainter {
  const _SubstitutionCyclePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.36;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final greenPaint = Paint()
      ..color = AppColors.soccer
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final redPaint = Paint()
      ..color = AppColors.liveRed
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Arco superior verde (entra)
    const startGreen = -math.pi * 0.85;
    const sweepGreen = math.pi * 0.7;
    canvas.drawArc(rect, startGreen, sweepGreen, false, greenPaint);
    _drawArrowHead(
      canvas,
      center: center,
      radius: radius,
      endAngle: startGreen + sweepGreen,
      clockwise: true,
      paint: greenPaint,
    );

    // Arco inferior rojo (sale)
    const startRed = math.pi * 0.15;
    const sweepRed = math.pi * 0.7;
    canvas.drawArc(rect, startRed, sweepRed, false, redPaint);
    _drawArrowHead(
      canvas,
      center: center,
      radius: radius,
      endAngle: startRed + sweepRed,
      clockwise: true,
      paint: redPaint,
    );
  }

  void _drawArrowHead(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double endAngle,
    required bool clockwise,
    required Paint paint,
  }) {
    final tip = Offset(
      center.dx + radius * math.cos(endAngle),
      center.dy + radius * math.sin(endAngle),
    );
    final tangentAngle = endAngle + (clockwise ? math.pi / 2 : -math.pi / 2);
    const headLen = 3.8;
    const spread = 0.6;
    final p1 = Offset(
      tip.dx - headLen * math.cos(tangentAngle - spread),
      tip.dy - headLen * math.sin(tangentAngle - spread),
    );
    final p2 = Offset(
      tip.dx - headLen * math.cos(tangentAngle + spread),
      tip.dy - headLen * math.sin(tangentAngle + spread),
    );
    canvas.drawLine(tip, p1, paint);
    canvas.drawLine(tip, p2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
