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
                child: _lineups(event, detail),
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

  // ignore: unused_element
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

    final sorted = List<FootballIncident>.from(incidents)
      ..sort((a, b) {
        final mA = _parseBaseMinute(a.minute) ?? 0;
        final mB = _parseBaseMinute(b.minute) ?? 0;
        return mA.compareTo(mB);
      });

    final firstHalf = <FootballIncident>[];
    final secondHalf = <FootballIncident>[];
    for (final item in sorted) {
      final m = _parseBaseMinute(item.minute);
      if (m != null && m > 45) {
        secondHalf.add(item);
      } else {
        firstHalf.add(item);
      }
    }

    final showHalftime = secondHalf.isNotEmpty ||
        (event.status == EventStatus.finished && firstHalf.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title('Momentos del partido'),
        const SizedBox(height: 12),
        for (final item in secondHalf.reversed) _timelineItem(item),
        if (showHalftime) _timelineDivider('Medio tiempo $halftimeScore'),
        for (final item in firstHalf.reversed) _timelineItem(item),
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
          key: ValueKey('goal-incident-icon'),
          width: 30,
          height: 30,
          child: Icon(
            Icons.sports_soccer,
            size: 28,
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

  /// Alineaciones en dos columnas simultáneas: equipo local a la izquierda y
  /// visitante a la derecha, con titulares y suplentes alineados por sección.
  Widget _lineups(EventModel event, FootballDetailModel? detail) {
    final home = detail?.homeLineup;
    final away = detail?.awayLineup;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _twoColumns(
          _lineupHeader(event.participant1Name, home, alignEnd: false),
          _lineupHeader(event.participant2Name, away, alignEnd: true),
          key: const ValueKey('lineup-headers'),
        ),
        if (home != null || away != null) ...[
          _sectionLabel('Titulares'),
          _twoColumns(
            _players(home?.starters, available: home != null, alignEnd: false),
            _players(away?.starters, available: away != null, alignEnd: true),
            key: const ValueKey('lineup-starters'),
          ),
          _sectionLabel('Suplentes'),
          _twoColumns(
            _players(
              home?.substitutes,
              available: home != null,
              alignEnd: false,
            ),
            _players(
              away?.substitutes,
              available: away != null,
              alignEnd: true,
            ),
            key: const ValueKey('lineup-substitutes'),
          ),
        ],
      ],
    );
  }

  Widget _twoColumns(Widget left, Widget right, {Key? key}) => Row(
    key: key,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: left),
      const SizedBox(width: 12),
      Expanded(child: right),
    ],
  );

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 6),
    child: Center(
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
    ),
  );

  Widget _lineupHeader(
    String team,
    FootballLineup? lineup, {
    required bool alignEnd,
  }) {
    final textAlign = alignEnd ? TextAlign.end : TextAlign.start;
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          team,
          textAlign: textAlign,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        if (lineup?.formation != null)
          Text(
            'Formación ${lineup!.formation}',
            textAlign: textAlign,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        if (lineup == null)
          Text(
            'Alineación no disponible',
            textAlign: textAlign,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
            ),
          ),
      ],
    );
  }

  Widget _players(
    List<FootballPlayer>? players, {
    required bool available,
    required bool alignEnd,
  }) {
    if (!available) return const SizedBox.shrink();
    if (players == null || players.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          'Información no disponible',
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final player in players)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _playerRow(player, alignEnd: alignEnd),
          ),
      ],
    );
  }

  Widget _playerRow(FootballPlayer player, {required bool alignEnd}) {
    final number = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 20),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          player.number ?? '—',
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
    final info = Expanded(
      child: Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            player.name,
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
            style: const TextStyle(fontSize: 13),
          ),
          if (player.position != null)
            Text(
              player.position!,
              textAlign: alignEnd ? TextAlign.end : TextAlign.start,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: alignEnd
          ? [info, const SizedBox(width: 4), number]
          : [number, const SizedBox(width: 4), info],
    );
  }

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
