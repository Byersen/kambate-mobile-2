import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/event_model.dart';
import '../../../../models/event_status.dart';
import '../../../../models/lol_detail_model.dart';

class LolDetailView extends StatefulWidget {
  final EventModel event;

  const LolDetailView({super.key, required this.event});

  @override
  State<LolDetailView> createState() => _LolDetailViewState();
}

class _LolDetailViewState extends State<LolDetailView> {
  int _selectedTab = 0; // 0: Resumen, 1: Partidas, 2: Jugadores
  int? _selectedGameNumber;
  int _playerTeamIndex = 0; // 0: Home, 1: Away

  @override
  void initState() {
    super.initState();
    _initActiveGame();
  }

  @override
  void didUpdateWidget(covariant LolDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final detail = _getDetail(widget.event);
    if (detail != null && _selectedGameNumber != null) {
      final exists = detail.games.any((g) => g.gameNumber == _selectedGameNumber);
      if (!exists) {
        _initActiveGame();
      }
    } else {
      _initActiveGame();
    }
  }

  void _initActiveGame() {
    final detail = _getDetail(widget.event);
    if (detail != null && detail.games.isNotEmpty) {
      _selectedGameNumber ??= detail.activeGame?.gameNumber ?? detail.games.first.gameNumber;
    }
  }

  LolDetailModel? _getDetail(EventModel event) {
    final parsed = LolDetailModel.parse(
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

    if (detail == null || detail.games.isEmpty) {
      return _buildEmptyOrPartialState(event);
    }

    // Asegurar que la partida seleccionada exista
    final selectedGame = detail.games.firstWhere(
      (g) => g.gameNumber == _selectedGameNumber,
      orElse: () => detail.activeGame ?? detail.games.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTabs(),
        const SizedBox(height: 14),
        _buildGamePills(detail, selectedGame),
        const SizedBox(height: 16),
        switch (_selectedTab) {
          0 => _buildSummaryTab(event, detail, selectedGame),
          1 => _buildGamesTab(event, detail, selectedGame),
          _ => _buildPlayersTab(event, detail, selectedGame),
        },
      ],
    );
  }

  // --- TABS (Resumen / Partidas / Jugadores) ---
  Widget _buildTabs() {
    const tabs = ['Resumen', 'Partidas', 'Jugadores'];
    return Row(
      children: [
        for (final (index, label) in tabs.indexed)
          Expanded(
            child: InkWell(
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

  // --- SELECTOR DE PARTIDAS (Pills) ---
  Widget _buildGamePills(LolDetailModel detail, LolGameDetail selectedGame) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final game in detail.games)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildGamePill(game, game.gameNumber == selectedGame.gameNumber),
            ),
        ],
      ),
    );
  }

  Widget _buildGamePill(LolGameDetail game, bool isSelected) {
    final isFinished = game.isFinished;
    final isLive = game.isLive;

    Color bg;
    Color fg;
    BorderSide border = BorderSide.none;

    if (isSelected) {
      bg = AppColors.primary;
      fg = AppColors.onPrimary;
    } else {
      bg = AppColors.surfaceMuted;
      fg = AppColors.textPrimary;
    }

    return InkWell(
      key: ValueKey('lol-game-pill-${game.gameNumber}'),
      onTap: () {
        setState(() {
          _selectedGameNumber = game.gameNumber;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.fromBorderSide(border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Partida ${game.gameNumber}',
              style: TextStyle(
                color: fg,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            if (isFinished) ...[
              const SizedBox(width: 5),
              Icon(
                Icons.check_rounded,
                size: 14,
                color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
              ),
            ] else if (isLive) ...[
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.onPrimary : AppColors.liveRed,
                ),
              ),
            ],
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
    LolDetailModel detail,
    LolGameDetail selectedGame,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSelectedGameCard(event, selectedGame),
        const SizedBox(height: 16),
        _buildSeriesSummaryCard(event, detail),
      ],
    );
  }

  Widget _buildSelectedGameCard(EventModel event, LolGameDetail game) {
    final durationText = game.duration != null && game.duration!.isNotEmpty
        ? ' · ${game.duration}'
        : '';
    final title = 'Partida ${game.gameNumber}$durationText';

    final homeName = event.homeTeam?.name ?? 'Equipo 1';
    final awayName = event.awayTeam?.name ?? 'Equipo 2';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              game.mapName,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            // Marcador de asesinatos (Kills)
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _teamSmallColumn(event.homeTeam, homeName),
                ),
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      Text(
                        '${game.homeKills ?? '—'} — ${game.awayKills ?? '—'}',
                        key: const ValueKey('lol-game-kills'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'ASESINATOS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: _teamSmallColumn(event.awayTeam, awayName),
                ),
              ],
            ),
            if (game.objectives != null && game.objectives!.hasAny) ...[
              const Divider(color: AppColors.border, height: 28),
              _buildObjectivesSection(event, game.objectives!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _teamSmallColumn(dynamic team, String fallback) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: team?.logoUrl == null || team.logoUrl.isEmpty
              ? const Icon(
                  Icons.sports_esports_outlined,
                  size: 26,
                  color: AppColors.textMuted,
                )
              : Image.network(
                  team.logoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, error, stack) => const Icon(
                    Icons.sports_esports_outlined,
                    size: 26,
                    color: AppColors.textMuted,
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          team?.shortName ?? team?.name ?? fallback,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildObjectivesSection(EventModel event, LolGameObjectives obj) {
    final homeName = event.homeTeam?.shortName ?? event.homeTeam?.name ?? 'Local';
    final awayName = event.awayTeam?.shortName ?? event.awayTeam?.name ?? 'Visitante';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Objetivos y recursos',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              homeName,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              awayName,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (obj.hasGold)
          _buildObjectiveRow(
            label: 'Oro',
            icon: Icons.monetization_on_outlined,
            homeVal: obj.displayHomeGold(),
            awayVal: obj.displayAwayGold(),
          ),
        if (obj.hasTowers)
          _buildObjectiveRow(
            label: 'Torres',
            icon: Icons.fort_outlined,
            homeVal: '${obj.homeTowers}',
            awayVal: '${obj.awayTowers}',
          ),
        if (obj.hasDragons)
          _buildObjectiveRow(
            label: 'Dragones',
            icon: Icons.local_fire_department_outlined,
            homeVal: '${obj.homeDragons}',
            awayVal: '${obj.awayDragons}',
          ),
        if (obj.hasBarons)
          _buildObjectiveRow(
            label: 'Barones',
            icon: Icons.shield_outlined,
            homeVal: '${obj.homeBarons}',
            awayVal: '${obj.awayBarons}',
          ),
      ],
    );
  }

  Widget _buildObjectiveRow({
    required String label,
    required IconData icon,
    required String homeVal,
    required String awayVal,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              homeVal,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Expanded(
            child: Text(
              awayVal,
              textAlign: TextAlign.right,
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

  Widget _buildSeriesSummaryCard(EventModel event, LolDetailModel detail) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen de la serie',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            for (final (index, game) in detail.games.indexed) ...[
              if (index > 0) const Divider(color: AppColors.border, height: 18),
              _buildSeriesGameRow(event, game),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSeriesGameRow(EventModel event, LolGameDetail game) {
    String middleText;
    Widget? winnerLogo;

    if (game.isFinished) {
      final isHomeWinner = game.winnerParticipantId == event.homeTeam?.id;
      final winnerTeam = isHomeWinner ? event.homeTeam : event.awayTeam;
      final winnerName = winnerTeam?.name ??
          (isHomeWinner ? 'Local' : 'Visitante');
      middleText = '$winnerName ganó';

      if (winnerTeam?.logoUrl != null && winnerTeam!.logoUrl!.isNotEmpty) {
        winnerLogo = Image.network(
          winnerTeam.logoUrl!,
          width: 16,
          height: 16,
          fit: BoxFit.contain,
          errorBuilder: (_, error, stack) => const SizedBox.shrink(),
        );
      }
    } else if (game.isLive) {
      middleText = 'En juego';
    } else {
      middleText = 'Por jugar';
    }

    return InkWell(
      onTap: () {
        setState(() {
          _selectedGameNumber = game.gameNumber;
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          spacing: 8,
          runSpacing: 6,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 2,
              children: [
                Text(
                  'Partida ${game.gameNumber}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ?winnerLogo,
                Text(
                  middleText,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: game.isLive
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                if (game.duration != null && game.duration!.isNotEmpty)
                  Text(
                    game.duration!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                _buildGameStatusBadge(game.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameStatusBadge(LolGameStatus status) {
    switch (status) {
      case LolGameStatus.live:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
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
      case LolGameStatus.finished:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'FINALIZADA',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        );
      case LolGameStatus.scheduled:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'PROGRAMADA',
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
  // TAB 1: PARTIDAS
  // =========================================================================
  Widget _buildGamesTab(
    EventModel event,
    LolDetailModel detail,
    LolGameDetail selectedGame,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final game in detail.games) ...[
          _buildDetailedGameCard(event, game),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildDetailedGameCard(EventModel event, LolGameDetail game) {
    final homeName = event.homeTeam?.name ?? 'Equipo 1';
    final awayName = event.awayTeam?.name ?? 'Equipo 2';
    final isHomeWinner = game.winnerParticipantId == event.homeTeam?.id;
    final winnerName = game.isFinished
        ? (isHomeWinner ? homeName : awayName)
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Partida ${game.gameNumber}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                _buildGameStatusBadge(game.status),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  game.mapName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (game.duration != null && game.duration!.isNotEmpty) ...[
                  const Text(' · ', style: TextStyle(color: AppColors.textSecondary)),
                  Text(
                    'Duración: ${game.duration}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    ),
                  ),
                  Text(
                    '${game.homeKills ?? '—'}  -  ${game.awayKills ?? '—'}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    awayName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (game.objectives != null && game.objectives!.hasAny) ...[
              const SizedBox(height: 12),
              _buildObjectivesSection(event, game.objectives!),
            ],
            if (game.homePlayers != null || game.awayPlayers != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedGameNumber = game.gameNumber;
                      _selectedTab = 2; // Ir a pestaña jugadores
                    });
                  },
                  icon: const Icon(Icons.people_outline, size: 16),
                  label: const Text(
                    'Ver jugadores de esta partida',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 2: JUGADORES
  // =========================================================================
  Widget _buildPlayersTab(
    EventModel event,
    LolDetailModel detail,
    LolGameDetail selectedGame,
  ) {
    final homeTeam = event.homeTeam;
    final awayTeam = event.awayTeam;

    final homePlayers = selectedGame.homePlayers ?? [];
    final awayPlayers = selectedGame.awayPlayers ?? [];

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
                'Alineaciones y estadísticas de jugadores no disponibles para la Partida ${selectedGame.gameNumber}',
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
        // Selector de equipo
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
                  'Jugadores · $activeTeamName (Partida ${selectedGame.gameNumber})',
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

  Widget _buildPlayerRow(LolPlayerStats p) {
    return Row(
      children: [
        if (p.role != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              p.role!,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (p.champion != null)
                Text(
                  p.champion!,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              p.kdaString,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (p.kdaRatio != null)
                  Text(
                    'KDA ${p.kdaRatio}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (p.cs != null) ...[
                  const Text(' · ', style: TextStyle(color: AppColors.textMuted)),
                  Text(
                    '${p.cs} CS',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }

  // --- ESTADO VACÍO O PARCIAL ---
  Widget _buildEmptyOrPartialState(EventModel event) {
    final status = event.status;
    final stats = event.esportsStats;
    final mapName = stats?.map;
    final format = stats?.format;

    String title;
    String subtitle;

    if (status == EventStatus.scheduled) {
      title = 'Encuentro programado';
      subtitle =
          'El detalle de partidas, objetivos y jugadores estará disponible al comenzar la serie.';
    } else if (status == EventStatus.live) {
      title = 'Serie en vivo';
      subtitle =
          'Sincronizando partidas en juego y objetivos elementales de la serie.';
    } else {
      title = 'Encuentro finalizado';
      subtitle =
          'La información desglosada por partida no se encuentra disponible para esta serie.';
    }

    final hasPartialInfo =
        (mapName != null && mapName.isNotEmpty) ||
        (format != null && format.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasPartialInfo) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'INFORMACIÓN DE LA SERIE',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (format != null && format.isNotEmpty) ...[
                    Text(
                      'Formato: $format',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (mapName != null && mapName.isNotEmpty) ...[
                    Text(
                      'Mapa / Fase: $mapName',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    'Competición: ${event.league}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              children: [
                const Icon(
                  Icons.sports_esports_outlined,
                  size: 40,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sin proveedor de estadísticas en tiempo real ni desglose de partidas activo para esta competición.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
