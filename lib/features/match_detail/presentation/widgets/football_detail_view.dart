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
                    ),
                    onSelected: (_) => setState(() => _section = index),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: switch (_section) {
              0 => _summary(event, detail),
              1 => _statistics(event, detail),
              _ => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _lineup(event.participant1Name, detail?.homeLineup),
                  const Divider(height: 32),
                  _lineup(event.participant2Name, detail?.awayLineup),
                ],
              ),
            },
          ),
        ),
      ],
    );
  }

  Widget _summary(EventModel event, FootballDetailModel? detail) {
    final incidents = detail?.timeline;
    if (incidents == null || incidents.isEmpty) {
      return _empty(
        Icons.sports_soccer_outlined,
        'Cronología del partido',
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
        _title('Cronología del partido'),
        for (final incident in incidents) ...[
          const SizedBox(height: 18),
          _incident(event, incident),
        ],
      ],
    );
  }

  Widget _incident(EventModel event, FootballIncident item) {
    final (label, icon, color) = switch (item.kind) {
      'goal' => ('Gol', Icons.sports_soccer, AppColors.primary),
      'yellowCard' => (
        'Tarjeta amarilla',
        Icons.square_rounded,
        AppColors.warning,
      ),
      'redCard' => ('Tarjeta roja', Icons.square_rounded, AppColors.error),
      _ => ('Cambio', Icons.swap_horiz_rounded, AppColors.textSecondary),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 54,
          child: Text(
            item.minute ?? '—',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Icon(icon, size: 19, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(
                item.side == 'home'
                    ? event.participant1Name
                    : event.participant2Name,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              if (item.player != null)
                Text(
                  '${item.kind == 'substitution' ? 'Entra: ' : ''}${item.player}',
                ),
              if (item.secondaryPlayer != null)
                Text(
                  '${item.kind == 'substitution' ? 'Sale' : 'Asistencia'}: ${item.secondaryPlayer}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
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
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(event.participant2Name, textAlign: TextAlign.end),
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
          if (stat.home != null &&
              stat.away != null &&
              stat.home! + stat.away! > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: stat.home! / (stat.home! + stat.away!),
                color: AppColors.primary,
                backgroundColor: AppColors.textMuted,
              ),
            )
          else
            const Divider(height: 6, thickness: 2),
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
          style: const TextStyle(color: AppColors.primary),
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
                    style: const TextStyle(color: AppColors.primary),
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
