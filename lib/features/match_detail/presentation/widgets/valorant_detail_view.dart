import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../models/event_model.dart';
import '../../../../models/event_status.dart';
import '../../../../models/team_model.dart';
import '../../../../models/valorant_detail_model.dart';

class ValorantDetailView extends StatefulWidget {
  final EventModel event;

  const ValorantDetailView({super.key, required this.event});

  @override
  State<ValorantDetailView> createState() => _ValorantDetailViewState();
}

class _ValorantDetailViewState extends State<ValorantDetailView> {
  int _selectedTab = 0; // 0: Resumen, 1: Mapas, 2: Jugadores
  int? _selectedMapNumber;
  int _playerTeamIndex = 0; // 0: Home, 1: Away

  @override
  void initState() {
    super.initState();
    _initSelectedMap(widget.event);
  }

  @override
  void didUpdateWidget(covariant ValorantDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final detail = _getDetail(widget.event);
    if (detail != null && _selectedMapNumber != null) {
      final exists = detail.maps.any((m) => m.mapNumber == _selectedMapNumber);
      if (!exists) {
        _initSelectedMap(widget.event);
      }
    } else {
      _initSelectedMap(widget.event);
    }
  }

  void _initSelectedMap(EventModel event) {
    final detail = _getDetail(event);
    if (detail != null && detail.maps.isNotEmpty) {
      final active = detail.activeMap ?? detail.maps.first;
      _selectedMapNumber = active.mapNumber;
    } else {
      _selectedMapNumber = null;
    }
  }

  ValorantDetailModel? _getDetail(EventModel event) {
    final parsed = ValorantDetailModel.parse(
      event.esportsStats?.extraStats?['detail'],
    );
    if (parsed == null) return null;
    if (event.homeTeam != null &&
        event.awayTeam != null &&
        (parsed.homeParticipantId != event.homeTeam!.id ||
            parsed.awayParticipantId != event.awayTeam!.id)) {
      return null;
    }
    return parsed;
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final detail = _getDetail(event);

    if (detail == null || detail.maps.isEmpty) {
      return _buildEmptyOrPartialState(event);
    }

    final selectedMap = detail.maps.firstWhere(
      (m) => m.mapNumber == _selectedMapNumber,
      orElse: () => detail.activeMap ?? detail.maps.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTabs(),
        const SizedBox(height: 14),
        _buildMapCards(detail, selectedMap),
        const SizedBox(height: 16),
        switch (_selectedTab) {
          0 => _buildSummaryTab(event, detail, selectedMap),
          1 => _buildMapsTab(event, detail, selectedMap),
          _ => _buildPlayersTab(event, detail, selectedMap),
        },
      ],
    );
  }

  // --- TABS (Resumen / Mapas / Jugadores) ---
  Widget _buildTabs() {
    const tabs = ['Resumen', 'Mapas', 'Jugadores'];
    return Row(
      children: [
        for (final (index, label) in tabs.indexed)
          Expanded(
            child: InkWell(
              key: ValueKey('valorant-tab-$index'),
              onTap: () => setState(() => _selectedTab = index),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTab == index
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: _selectedTab == index
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: _selectedTab == index
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // --- SELECTOR DE MAPAS (Cards horizontales) ---
  Widget _buildMapCards(ValorantDetailModel detail, ValorantMapDetail selectedMap) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final map in detail.maps)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _buildMapCard(map, map.mapNumber == selectedMap.mapNumber),
            ),
        ],
      ),
    );
  }

  Widget _buildMapCard(ValorantMapDetail map, bool isSelected) {
    final bg = isSelected ? AppColors.primary : AppColors.surface;
    final titleColor = isSelected ? AppColors.onPrimary : AppColors.textPrimary;
    final subColor = isSelected ? AppColors.onPrimary.withValues(alpha: 0.9) : AppColors.textSecondary;

    return InkWell(
      key: ValueKey('valorant-map-card-${map.mapNumber}'),
      onTap: () {
        setState(() {
          _selectedMapNumber = map.mapNumber;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minWidth: 108),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? null : Border.all(color: AppColors.border),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              map.mapName,
              style: TextStyle(
                color: titleColor,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            if (map.hasScore)
              Text(
                '${map.homeScore} — ${map.awayScore}',
                style: TextStyle(
                  color: titleColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(height: 2),
            if (map.isLive)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppColors.onPrimary : AppColors.liveRed,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'EN VIVO',
                    style: TextStyle(
                      color: isSelected ? AppColors.onPrimary : AppColors.liveRed,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              )
            else if (map.isFinished)
              Text(
                'Finalizado',
                style: TextStyle(
                  color: subColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              Text(
                'Programado',
                style: TextStyle(
                  color: subColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 0: RESUMEN
  // =========================================================================
  Widget _buildSummaryTab(
    EventModel event,
    ValorantDetailModel detail,
    ValorantMapDetail selectedMap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSelectedMapCard(event, selectedMap),
        if (selectedMap.recentRounds.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildRecentRoundsCard(event, selectedMap),
        ],
        if (selectedMap.stats != null && selectedMap.stats!.hasAnyMetric) ...[
          const SizedBox(height: 14),
          _buildMapComparisonCard(event, selectedMap),
        ],
        const SizedBox(height: 14),
        _buildViewPlayersActionTile(),
      ],
    );
  }

  // Tarjeta de información del mapa seleccionado
  Widget _buildSelectedMapCard(EventModel event, ValorantMapDetail map) {
    final homeTeam = event.homeTeam;
    final awayTeam = event.awayTeam;

    String subtitle = '';
    if (map.isLive) {
      subtitle = map.currentRound != null
          ? 'Ronda ${map.currentRound}'
          : 'En juego';
    } else if (map.isFinished) {
      subtitle = map.duration != null && map.duration!.isNotEmpty
          ? 'Finalizado · ${map.duration}'
          : 'Finalizado';
    } else {
      subtitle = 'Por disputar';
    }

    final homeRounds = map.homeScore ?? 0;
    final awayRounds = map.awayScore ?? 0;
    final scoreText = map.hasScore ? '$homeRounds  —  $awayRounds' : '—';

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          children: [
            Text(
              map.mapName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: _teamMapColumn(homeTeam, 'Local', map.homeSide),
                ),
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          scoreText,
                          key: const ValueKey('valorant-map-rounds-score'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'RONDAS GANADAS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: _teamMapColumn(awayTeam, 'Visitante', map.awaySide),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _teamMapColumn(TeamModel? team, String fallback, String? side) {
    const placeholder = Icon(
      Icons.shield_outlined,
      size: 36,
      color: AppColors.textMuted,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: team?.logoUrl == null || team!.logoUrl!.isEmpty
              ? placeholder
              : Image.network(
                  team.logoUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, error, stack) => placeholder,
                ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            team?.name ?? fallback,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (side != null && side.trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            side.trim(),
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ],
    );
  }

  // Tarjeta: "Últimas 6 rondas"
  Widget _buildRecentRoundsCard(EventModel event, ValorantMapDetail map) {
    final recent = map.recentRounds;
    final homeTeam = event.homeTeam;
    final awayTeam = event.awayTeam;

    final homeName = homeTeam?.shortName ?? homeTeam?.name ?? 'Local';
    final awayName = awayTeam?.shortName ?? awayTeam?.name ?? 'Visitante';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                const Text(
                  'Últimas 6 rondas',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      homeName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      awayName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final r in recent)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildRoundBox(event, r),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundBox(EventModel event, ValorantRoundDetail round) {
    final isHomeWinner = round.winnerParticipantId == event.homeTeam?.id;
    final winnerTeam = isHomeWinner ? event.homeTeam : event.awayTeam;
    final winnerLabel = winnerTeam?.shortName ?? winnerTeam?.name ?? (isHomeWinner ? 'L' : 'V');

    final bg = isHomeWinner
        ? AppColors.primary.withValues(alpha: 0.12)
        : AppColors.surfaceMuted;
    final labelColor = isHomeWinner ? AppColors.primary : AppColors.textSecondary;

    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHomeWinner
              ? AppColors.primary.withValues(alpha: 0.25)
              : AppColors.border,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${round.roundNumber}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 20,
            height: 20,
            child: winnerTeam?.logoUrl != null && winnerTeam!.logoUrl!.isNotEmpty
                ? Image.network(
                    winnerTeam.logoUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, error, stack) => Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: labelColor,
                    ),
                  )
                : Icon(
                    Icons.shield_outlined,
                    size: 16,
                    color: labelColor,
                  ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              winnerLabel,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: labelColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tarjeta: "Comparativa del mapa"
  Widget _buildMapComparisonCard(EventModel event, ValorantMapDetail map) {
    final stats = map.stats;
    if (stats == null) return const SizedBox.shrink();

    final homeTeam = event.homeTeam;
    final awayTeam = event.awayTeam;

    final homeName = homeTeam?.shortName ?? homeTeam?.name ?? 'Local';
    final awayName = awayTeam?.shortName ?? awayTeam?.name ?? 'Visitante';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Comparativa del mapa',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            // Encabezado con nombres y logos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMiniLogo(homeTeam?.logoUrl),
                    const SizedBox(width: 6),
                    Text(
                      homeName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      awayName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildMiniLogo(awayTeam?.logoUrl),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (stats.hasFirstBloods) ...[
              _buildMetricBarRow(
                label: 'Primeras bajas',
                homeVal: stats.homeFirstBloods!,
                awayVal: stats.awayFirstBloods!,
              ),
            ],
            if (stats.hasPlants) ...[
              const SizedBox(height: 12),
              _buildMetricBarRow(
                label: 'Plantadas',
                homeVal: stats.homePlants!,
                awayVal: stats.awayPlants!,
              ),
            ],
            if (stats.hasDefuses) ...[
              const SizedBox(height: 12),
              _buildMetricBarRow(
                label: 'Desactivaciones',
                homeVal: stats.homeDefuses!,
                awayVal: stats.awayDefuses!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniLogo(String? url) {
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        width: 18,
        height: 18,
        fit: BoxFit.contain,
        errorBuilder: (_, error, stack) => const Icon(
          Icons.shield_outlined,
          size: 16,
          color: AppColors.textMuted,
        ),
      );
    }
    return const Icon(
      Icons.shield_outlined,
      size: 16,
      color: AppColors.textMuted,
    );
  }

  Widget _buildMetricBarRow({
    required String label,
    required int homeVal,
    required int awayVal,
  }) {
    final total = homeVal + awayVal;
    final homeFraction = total > 0 ? (homeVal / total).clamp(0.1, 0.9) : 0.5;
    final awayFraction = 1.0 - homeFraction;

    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            '$homeVal',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          flex: (homeFraction * 100).toInt(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 7,
              color: AppColors.primary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: (awayFraction * 100).toInt(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 7,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 28,
          child: Text(
            '$awayVal',
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // Botón directo para pasar a la pestaña de Jugadores
  Widget _buildViewPlayersActionTile() {
    return InkWell(
      key: const ValueKey('valorant-view-players-action'),
      onTap: () {
        setState(() {
          _selectedTab = 2; // Cambia a pestaña Jugadores
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 20,
              color: AppColors.primary,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ver estadísticas de jugadores',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 1: MAPAS
  // =========================================================================
  Widget _buildMapsTab(
    EventModel event,
    ValorantDetailModel detail,
    ValorantMapDetail selectedMap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final map in detail.maps) ...[
          _buildDetailedMapCard(event, map),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildDetailedMapCard(EventModel event, ValorantMapDetail map) {
    final homeName = event.homeTeam?.name ?? 'Equipo 1';
    final awayName = event.awayTeam?.name ?? 'Equipo 2';
    final isHomeWinner = map.winnerParticipantId == event.homeTeam?.id;
    final winnerName = map.isFinished
        ? (isHomeWinner ? homeName : awayName)
        : null;

    return Card(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMapNumber = map.mapNumber;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mapa ${map.mapNumber} · ${map.mapName}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  _buildMapStatusBadge(map.status),
                ],
              ),
              if (map.duration != null && map.duration!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Duración: ${map.duration}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (winnerName != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Ganador: $winnerName',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      homeName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      map.hasScore
                          ? '${map.homeScore} — ${map.awayScore}'
                          : (map.isLive ? 'En juego' : 'Por jugar'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      awayName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
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

  Widget _buildMapStatusBadge(ValorantMapStatus status) {
    switch (status) {
      case ValorantMapStatus.live:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.liveRed.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.liveRed,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'EN VIVO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.liveRed,
                ),
              ),
            ],
          ),
        );
      case ValorantMapStatus.finished:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'FINALIZADO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        );
      case ValorantMapStatus.scheduled:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'PROGRAMADO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
        );
    }
  }

  // =========================================================================
  // TAB 2: JUGADORES
  // =========================================================================
  Widget _buildPlayersTab(
    EventModel event,
    ValorantDetailModel detail,
    ValorantMapDetail selectedMap,
  ) {
    final homeTeam = event.homeTeam;
    final awayTeam = event.awayTeam;

    final homePlayers = selectedMap.homePlayers ?? [];
    final awayPlayers = selectedMap.awayPlayers ?? [];

    if (homePlayers.isEmpty && awayPlayers.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(
                Icons.people_outline,
                size: 36,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 10),
              Text(
                'Alineaciones y estadísticas de jugadores no disponibles para ${selectedMap.mapName}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final activePlayers = _playerTeamIndex == 0 ? homePlayers : awayPlayers;
    final activeTeamName = _playerTeamIndex == 0
        ? (homeTeam?.name ?? 'Local')
        : (awayTeam?.name ?? 'Visitante');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTeamToggleOption(
                label: homeTeam?.name ?? 'Local',
                isSelected: _playerTeamIndex == 0,
                onTap: () => setState(() => _playerTeamIndex = 0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTeamToggleOption(
                label: awayTeam?.name ?? 'Visitante',
                isSelected: _playerTeamIndex == 1,
                onTap: () => setState(() => _playerTeamIndex = 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jugadores · $activeTeamName (${selectedMap.mapName})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                if (activePlayers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'Sin datos de jugadores para este equipo',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    ),
                  )
                else
                  for (final (i, p) in activePlayers.indexed) ...[
                    if (i > 0) const Divider(color: AppColors.border, height: 16),
                    _buildPlayerRow(p),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamToggleOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerRow(ValorantPlayerStats p) {
    return Row(
      children: [
        if (p.agent != null && p.agent!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              p.agent!,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                p.name,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (p.role != null && p.role!.isNotEmpty)
                Text(
                  p.role!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (p.acsDisplay != null)
              Text(
                p.acsDisplay!,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            Text(
              p.kdaString,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- ESTADO VACÍO O COBERTURA PARCIAL ---
  Widget _buildEmptyOrPartialState(EventModel event) {
    final isScheduled = event.status == EventStatus.scheduled;
    final timeStr = AppDateFormatter.formatFullDate(event.startTime);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              isScheduled
                  ? Icons.calendar_today_outlined
                  : Icons.track_changes_outlined,
              size: 38,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              isScheduled ? 'Serie programada' : 'Cobertura en tiempo real',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isScheduled
                  ? 'La serie comenzará el $timeStr. Los mapas, rondas y jugadores se sincronizarán al iniciar la transmisión.'
                  : 'El detalle de mapas y rondas no está disponible en este momento. El marcador general se mantiene sincronizado.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
