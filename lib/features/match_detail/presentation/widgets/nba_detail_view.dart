import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/basketball_detail_model.dart';
import '../../../../models/event_model.dart';
import '../../../../models/event_status.dart';
import '../../../../models/team_model.dart';

class NbaDetailView extends StatefulWidget {
  final EventModel event;

  const NbaDetailView({super.key, required this.event});

  @override
  State<NbaDetailView> createState() => _NbaDetailViewState();
}

class _NbaDetailViewState extends State<NbaDetailView> {
  int _section = 0; // 0: Resumen, 1: Jugadores
  int _playerTeamIndex = 0; // 0: Home team, 1: Away team

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final parsed = BasketballDetailModel.parse(
      event.nbaStats?.extraStats?['detail'],
    );
    // Verificar coherencia de participantes si existen identificadores en el detalle
    final detail = (parsed != null &&
            event.homeTeam != null &&
            event.awayTeam != null &&
            (parsed.homeParticipantId != event.homeTeam!.id ||
                parsed.awayParticipantId != event.awayTeam!.id))
        ? null
        : parsed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionChips(),
        const SizedBox(height: 16),
        _section == 0
            ? _buildSummaryTab(event, detail)
            : _buildPlayersTab(event, detail),
      ],
    );
  }

  // --- SELECTION CHIPS (Resumen / Jugadores / Jugadas) ---
  Widget _buildSectionChips() {
    const tabs = ['Resumen', 'Jugadores'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (index, label) in tabs.indexed)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                key: ValueKey('basketball-tab-$index'),
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
    );
  }

  // =========================================================================
  // TAB 0: RESUMEN
  // =========================================================================
  Widget _buildSummaryTab(EventModel event, BasketballDetailModel? detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildQuarterScoresCard(event, detail),
        const SizedBox(height: 16),
        _buildTeamComparisonCard(event, detail),
        if (detail?.leaders?.points != null) ...[
          const SizedBox(height: 16),
          _buildPointsLeadersCard(event, detail!.leaders!.points!),
        ],
      ],
    );
  }

  // --- 1. PUNTOS POR CUARTO ---
  Widget _buildQuarterScoresCard(EventModel event, BasketballDetailModel? detail) {
    final periods = detail?.periods ?? [];
    final activeQuarterNum = _resolveActiveQuarter(event);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Puntos por cuarto',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            if (periods.isEmpty)
              _buildEmptyQuarterState(event)
            else
              _buildQuarterTable(event, periods, activeQuarterNum),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyQuarterState(EventModel event) {
    final message = event.status == EventStatus.scheduled
        ? 'El partido aún no comienza. Los parciales por cuarto aparecerán cuando esté en juego.'
        : 'Desglose por cuartos no disponible para este encuentro.';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildQuarterTable(
    EventModel event,
    List<BasketballPeriodScore> periods,
    int? activeQuarter,
  ) {
    // Definición de anchos de columna dinámicos
    final Map<int, TableColumnWidth> widths = {
      0: const FlexColumnWidth(2.6),
    };
    for (var i = 0; i < periods.length; i++) {
      widths[i + 1] = const FlexColumnWidth(1.0);
    }
    widths[periods.length + 1] = const FlexColumnWidth(1.3);

    final homeTotal = event.homeScore ?? _sumPeriodScores(periods, isHome: true);
    final awayTotal = event.awayScore ?? _sumPeriodScores(periods, isHome: false);

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: widths,
      children: [
        // Encabezado
        TableRow(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.cardBorderDark, width: 1),
            ),
          ),
          children: [
            _buildTableHeaderCell('Equipo', alignLeft: true),
            for (var i = 0; i < periods.length; i++)
              _buildTableHeaderCell(
                periods[i].period,
                isActive: event.isLive && (i + 1) == activeQuarter,
              ),
            _buildTableHeaderCell('Total', isHighlight: true),
          ],
        ),
        // Fila Equipo Local
        TableRow(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.cardBorderDark, width: 0.5),
            ),
          ),
          children: [
            _buildTeamLabelCell(event.homeTeam, 'Local'),
            for (var i = 0; i < periods.length; i++)
              _buildScoreCell(
                periods[i].homeScore,
                isActive: event.isLive && (i + 1) == activeQuarter,
              ),
            _buildScoreCell(homeTotal, isBold: true, isHighlight: true),
          ],
        ),
        // Fila Equipo Visitante
        TableRow(
          children: [
            _buildTeamLabelCell(event.awayTeam, 'Visitante'),
            for (var i = 0; i < periods.length; i++)
              _buildScoreCell(
                periods[i].awayScore,
                isActive: event.isLive && (i + 1) == activeQuarter,
              ),
            _buildScoreCell(awayTotal, isBold: true, isHighlight: true),
          ],
        ),
      ],
    );
  }

  Widget _buildTableHeaderCell(
    String text, {
    bool alignLeft = false,
    bool isHighlight = false,
    bool isActive = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: isActive ? BorderRadius.circular(4) : null,
      ),
      child: Text(
        text,
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        style: TextStyle(
          color: isActive
              ? AppColors.primary
              : isHighlight
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: isHighlight || isActive ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTeamLabelCell(TeamModel? team, String fallback) {
    const placeholder = Icon(
      Icons.sports_basketball_outlined,
      size: 18,
      color: AppColors.textMuted,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: team?.logoUrl == null || team!.logoUrl!.isEmpty
                ? placeholder
                : Image.network(
                    team.logoUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, error, stack) => placeholder,
                  ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              team?.shortName ?? team?.name ?? fallback,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCell(
    int? score, {
    bool isBold = false,
    bool isHighlight = false,
    bool isActive = false,
  }) {
    // Si el score es null, indica periodo pendiente -> '—'
    // Si el score es 0, indica 0 puntos disputados -> '0'
    final displayText = score == null ? '—' : '$score';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: isActive ? BorderRadius.circular(4) : null,
      ),
      child: Text(
        displayText,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isHighlight
              ? AppColors.textPrimary
              : isActive
                  ? AppColors.primary
                  : score == null
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
          fontSize: 13.5,
          fontWeight: isBold || isHighlight || isActive
              ? FontWeight.w700
              : FontWeight.normal,
        ),
      ),
    );
  }

  int? _sumPeriodScores(List<BasketballPeriodScore> periods, {required bool isHome}) {
    int sum = 0;
    bool hasAny = false;
    for (final p in periods) {
      final val = isHome ? p.homeScore : p.awayScore;
      if (val != null) {
        sum += val;
        hasAny = true;
      }
    }
    return hasAny ? sum : null;
  }

  int? _resolveActiveQuarter(EventModel event) {
    final raw = event.nbaStats?.extraStats?['quarter']?.toString() ??
        event.nbaStats?.quarter ??
        event.currentPeriod;
    if (raw == null) return null;
    final match = RegExp(r'(\d)').firstMatch(raw);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  // --- 2. ESTADÍSTICAS POR EQUIPO ---
  Widget _buildTeamComparisonCard(EventModel event, BasketballDetailModel? detail) {
    final stats = detail?.statistics ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header con ambos equipos (sin título de sección)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildTeamHeaderBadge(event.homeTeam, isHome: true),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTeamHeaderBadge(event.awayTeam, isHome: false),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (stats.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Estadísticas de equipo no disponibles para este encuentro.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              )
            else
              for (final stat in stats) ...[
                _buildStatComparisonRow(stat),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeamHeaderBadge(TeamModel? team, {required bool isHome}) {
    const placeholder = Icon(
      Icons.sports_basketball_outlined,
      size: 20,
      color: AppColors.textMuted,
    );
    final rowChildren = [
      SizedBox(
        width: 22,
        height: 22,
        child: team?.logoUrl == null || team!.logoUrl!.isEmpty
            ? placeholder
            : Image.network(
                team.logoUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, error, stack) => placeholder,
              ),
      ),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          team?.shortName ?? team?.name ?? (isHome ? 'Local' : 'Visitante'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: isHome ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: isHome ? rowChildren : rowChildren.reversed.toList(),
    );
  }

  Widget _buildStatComparisonRow(BasketballStatistic stat) {
    final homeText = stat.display(stat.home);
    final awayText = stat.display(stat.away);

    double homeRatio = 0.5;
    if (stat.home != null && stat.away != null) {
      final total = stat.home! + stat.away!;
      if (total > 0) {
        homeRatio = (stat.home! / total).clamp(0.05, 0.95);
      }
    } else if (stat.home != null && stat.away == null) {
      homeRatio = 1.0;
    } else if (stat.home == null && stat.away != null) {
      homeRatio = 0.0;
    }

    final hasValues = stat.home != null || stat.away != null;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              homeText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                stat.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              awayText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              Expanded(
                flex: (homeRatio * 100).toInt(),
                child: Container(
                  height: 6,
                  color: hasValues ? AppColors.primary : AppColors.surfaceMuted,
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                flex: ((1.0 - homeRatio) * 100).toInt(),
                child: Container(
                  height: 6,
                  color: hasValues
                      ? AppColors.textPrimary
                      : AppColors.surfaceMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 3. LÍDERES EN PUNTOS ---
  Widget _buildPointsLeadersCard(
    EventModel event,
    BasketballLeaderItem leaderItem,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Líderes en puntos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildLeaderBox(
                    team: event.homeTeam,
                    leader: leaderItem.home,
                    fallbackTeam: 'Local',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLeaderBox(
                    team: event.awayTeam,
                    leader: leaderItem.away,
                    fallbackTeam: 'Visitante',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              key: const ValueKey('basketball-view-players-btn'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _section = 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Expanded(
                      child: Text(
                        'Ver estadísticas de jugadores',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderBox({
    required TeamModel? team,
    required BasketballPlayerLeader? leader,
    required String fallbackTeam,
  }) {
    const placeholder = Icon(
      Icons.sports_basketball_outlined,
      size: 16,
      color: AppColors.textMuted,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: team?.logoUrl == null || team!.logoUrl!.isEmpty
                    ? placeholder
                    : Image.network(
                        team.logoUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, error, stack) => placeholder,
                      ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  team?.name ?? fallbackTeam,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Camiseta / Icono de dorsal
              Container(
                width: 32,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  leader?.number != null && leader!.number!.isNotEmpty
                      ? leader.number!
                      : '#',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leader?.name ?? 'Jugador',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      leader?.value ?? '—',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: JUGADORES
  // =========================================================================
  Widget _buildPlayersTab(EventModel event, BasketballDetailModel? detail) {
    final homePlayers = detail?.homePlayers ?? [];
    final awayPlayers = detail?.awayPlayers ?? [];

    if (homePlayers.isEmpty && awayPlayers.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.people_outline,
                size: 40,
                color: AppColors.textMuted,
              ),
              SizedBox(height: 12),
              Text(
                'Estadísticas de jugadores no disponibles',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'No se han recibido datos individuales de jugadores para este encuentro.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final selectedPlayers = _playerTeamIndex == 0 ? homePlayers : awayPlayers;
    final selectedTeam = _playerTeamIndex == 0 ? event.homeTeam : event.awayTeam;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selector de equipo
            Row(
              children: [
                Expanded(
                  child: _buildTeamSwitchButton(
                    team: event.homeTeam,
                    fallback: 'Local',
                    isSelected: _playerTeamIndex == 0,
                    onTap: () => setState(() => _playerTeamIndex = 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTeamSwitchButton(
                    team: event.awayTeam,
                    fallback: 'Visitante',
                    isSelected: _playerTeamIndex == 1,
                    onTap: () => setState(() => _playerTeamIndex = 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (selectedPlayers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Sin alineación registrada para ${selectedTeam?.name ?? 'este equipo'}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              )
            else ...[
              _buildPlayerGroup('Titulares', selectedPlayers.where((p) => p.isStarter).toList()),
              const SizedBox(height: 16),
              _buildPlayerGroup('Suplentes', selectedPlayers.where((p) => !p.isStarter).toList()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSwitchButton({
    required TeamModel? team,
    required String fallback,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          team?.shortName ?? team?.name ?? fallback,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerGroup(String title, List<BasketballPlayer> players) {
    if (players.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2.8),
            1: FlexColumnWidth(0.9),
            2: FlexColumnWidth(0.9),
            3: FlexColumnWidth(0.9),
            4: FlexColumnWidth(1.1),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.cardBorderDark, width: 1),
                ),
              ),
              children: [
                _buildTableHeaderCell('Jugador', alignLeft: true),
                _buildTableHeaderCell('PTS', isHighlight: true),
                _buildTableHeaderCell('REB'),
                _buildTableHeaderCell('AST'),
                _buildTableHeaderCell('MIN'),
              ],
            ),
            for (final player in players)
              TableRow(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.cardBorderDark, width: 0.5),
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        if (player.number != null && player.number!.isNotEmpty) ...[
                          Text(
                            '#${player.number}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            player.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (player.position != null && player.position!.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text(
                            player.position!,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildScoreCell(player.points, isBold: true, isHighlight: true),
                  _buildScoreCell(player.rebounds),
                  _buildScoreCell(player.assists),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      player.minutes ?? '—',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

}
