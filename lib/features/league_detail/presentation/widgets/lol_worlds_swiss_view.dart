import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/lol_worlds_stage_model.dart';

/// Vista especializada para la competición Worlds de League of Legends y su formato suizo.
/// Renderiza dinámicamente la etapa activa, calendario, rondas, tabla suiza y avance.
class LolWorldsSwissView extends StatefulWidget {
  final LolWorldsStageModel stageData;
  final VoidCallback onRefresh;

  const LolWorldsSwissView({
    super.key,
    required this.stageData,
    required this.onRefresh,
  });

  @override
  State<LolWorldsSwissView> createState() => _LolWorldsSwissViewState();
}

class _LolWorldsSwissViewState extends State<LolWorldsSwissView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _selectedRoundNumber;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Seleccionar por defecto la ronda activa si existe, o null (todas)
    _selectedRoundNumber = widget.stageData.stage?.currentRoundNumber;
  }

  @override
  void didUpdateWidget(covariant LolWorldsSwissView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stageData != widget.stageData) {
      if (_selectedRoundNumber == null &&
          widget.stageData.stage?.currentRoundNumber != null) {
        _selectedRoundNumber = widget.stageData.stage?.currentRoundNumber;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.stageData;

    // Si la fuente no tiene cobertura o requiere credenciales
    if (!data.hasCoverage || data.isUnconfigured) {
      return _buildNoCoverageView(data);
    }

    return Column(
      children: [
        _buildStageHeaderBanner(data),
        TabBar(
          controller: _tabController,
          indicatorColor: AppColors.lol,
          labelColor: AppColors.lol,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Partidos y Rondas'),
            Tab(text: 'Tabla Suiza'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMatchesTab(data),
              _buildStandingsTab(data),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStageHeaderBanner(LolWorldsStageModel data) {
    final stage = data.stage;
    final stageName = stage?.name ?? 'Etapa Actual';
    final seasonName = data.season.name;
    final isSwiss = stage?.isSwiss ?? true;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorderDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.lol.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.sports_esports_rounded,
              color: AppColors.lol,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stageName.toUpperCase(),
                  key: const ValueKey('lol-worlds-stage-title'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$seasonName${isSwiss ? ' • Formato Suizo' : ''}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (stage != null) _buildStageStatusBadge(stage.status),
        ],
      ),
    );
  }

  Widget _buildStageStatusBadge(String status) {
    final s = status.toLowerCase();
    final bool isLive = s == 'in_progress' || s == 'live';
    final bool isFinished = s == 'completed' || s == 'finished';

    final text = isLive
        ? 'EN CURSO'
        : isFinished
            ? 'FINALIZADA'
            : 'PROGRAMADA';

    final color = isLive
        ? AppColors.error
        : isFinished
            ? AppColors.textMuted
            : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesTab(LolWorldsStageModel data) {
    final allMatches = data.matches;
    final rounds = data.rounds;

    final filteredMatches = _selectedRoundNumber == null
        ? allMatches
        : allMatches
            .where((m) => m.roundNumber == _selectedRoundNumber)
            .toList();

    return Column(
      children: [
        if (rounds.isNotEmpty) _buildRoundSelector(rounds),
        Expanded(
          child: filteredMatches.isEmpty
              ? _buildEmptyMatchesState()
              : RefreshIndicator(
                  onRefresh: () async => widget.onRefresh(),
                  color: AppColors.lol,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    itemCount: filteredMatches.length,
                    itemBuilder: (context, index) {
                      return _buildSwissMatchCard(filteredMatches[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildRoundSelector(List<LolWorldsRoundModel> rounds) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              key: const ValueKey('lol-round-chip-all'),
              label: const Text('Todas'),
              selected: _selectedRoundNumber == null,
              onSelected: (_) {
                setState(() => _selectedRoundNumber = null);
              },
              selectedColor: AppColors.lol.withValues(alpha: 0.2),
              backgroundColor: AppColors.surfaceDark,
              labelStyle: TextStyle(
                color: _selectedRoundNumber == null
                    ? AppColors.lol
                    : AppColors.textMuted,
                fontWeight: _selectedRoundNumber == null
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: 12,
              ),
              side: BorderSide(
                color: _selectedRoundNumber == null
                    ? AppColors.lol
                    : AppColors.cardBorderDark,
              ),
            ),
          ),
          ...rounds.map((round) {
            final isSelected = _selectedRoundNumber == round.roundNumber;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                key: ValueKey('lol-round-chip-${round.roundNumber}'),
                label: Text(round.name),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _selectedRoundNumber = round.roundNumber);
                },
                selectedColor: AppColors.lol.withValues(alpha: 0.2),
                backgroundColor: AppColors.surfaceDark,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.lol : AppColors.textMuted,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.lol : AppColors.cardBorderDark,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSwissMatchCard(LolWorldsMatchModel match) {
    final home = match.homeTeam;
    final away = match.awayTeam;
    final isFinished = match.isFinished;
    final isLive = match.isLive;

    return Container(
      key: ValueKey('lol-match-card-${match.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLive
              ? AppColors.error.withValues(alpha: 0.6)
              : AppColors.cardBorderDark,
        ),
      ),
      child: Column(
        children: [
          // Sub-cabecera con número de ronda, formato y estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.cardBorderDark),
              ),
            ),
            child: Row(
              children: [
                if (match.roundName != null && match.roundName!.isNotEmpty) ...[
                  Text(
                    match.roundName!.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else if (match.roundNumber != null) ...[
                  Text(
                    'RONDA ${match.roundNumber}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const Spacer(),
                if (match.format != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      match.format!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (isLive) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'EN VIVO',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ] else if (isFinished) ...[
                  const Text(
                    'FINAL',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ] else ...[
                  Text(
                    _formatTime(match.startTime),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Filas de los equipos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              children: [
                _buildTeamRow(
                  participant: home,
                  isWinner: isFinished && match.winnerTeamId == home.id,
                  score: home.score,
                ),
                const SizedBox(height: 8),
                _buildTeamRow(
                  participant: away,
                  isWinner: isFinished && match.winnerTeamId == away.id,
                  score: away.score,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamRow({
    required LolWorldsParticipantModel participant,
    required bool isWinner,
    required int? score,
  }) {
    return Row(
      children: [
        if (participant.logoUrl != null &&
            participant.logoUrl!.trim().isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              participant.logoUrl!,
              width: 22,
              height: 22,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.shield_outlined,
                size: 20,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ] else ...[
          const Icon(
            Icons.shield_outlined,
            size: 20,
            color: AppColors.textMuted,
          ),
        ],
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  participant.name,
                  style: TextStyle(
                    color: isWinner
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: isWinner ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (participant.code != null &&
                  participant.code!.isNotEmpty &&
                  participant.code != participant.name) ...[
                const SizedBox(width: 6),
                Text(
                  participant.code!,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
              if (participant.record != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    participant.record!,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (score != null) ...[
          Text(
            '$score',
            style: TextStyle(
              color: isWinner ? AppColors.lol : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ] else ...[
          const Text(
            '—',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStandingsTab(LolWorldsStageModel data) {
    final standings = data.swissStandings;

    if (standings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.table_chart_outlined,
                size: 40,
                color: AppColors.textMuted.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'Sin registro de posiciones',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'El proveedor oficial aún no ha publicado el registro de la etapa suiza.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      color: AppColors.lol,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorderDark),
            ),
            child: Column(
              children: [
                _buildStandingsHeader(),
                ...standings.map(_buildStandingRow),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandingsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorderDark)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '#',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'EQUIPO',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              'RÉCORD',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            width: 34,
            child: Text(
              'DIF',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandingRow(LolSwissStandingEntryModel entry) {
    final hasAdvancement = entry.advancementStatus != null ||
        (entry.advancementText != null && entry.advancementText!.isNotEmpty);

    Color? rowAccentColor;
    if (entry.isQualified) {
      rowAccentColor = const Color(0xFF10B981); // Emerald
    } else if (entry.isEliminated) {
      rowAccentColor = AppColors.error;
    }

    return Container(
      key: ValueKey('lol-standing-row-${entry.position}'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorderDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 22,
                child: Text(
                  '${entry.position}',
                  style: TextStyle(
                    color: rowAccentColor ?? AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (entry.teamLogo != null && entry.teamLogo!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    entry.teamLogo!,
                    width: 20,
                    height: 20,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(width: 20),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.teamName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.teamCode != null &&
                        entry.teamCode!.isNotEmpty &&
                        entry.teamCode != entry.teamName) ...[
                      const SizedBox(width: 6),
                      Text(
                        entry.teamCode!,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  entry.record,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: rowAccentColor ?? AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              SizedBox(
                width: 34,
                child: Text(
                  entry.diff != null
                      ? (entry.diff! > 0 ? '+${entry.diff}' : '${entry.diff}')
                      : '—',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          // Avance a la siguiente fase solo si la fuente lo entregó
          if (hasAdvancement) ...[
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 4),
              child: _buildAdvancementBadge(entry),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancementBadge(LolSwissStandingEntryModel entry) {
    final text = entry.advancementText ??
        (entry.isQualified
            ? 'Clasificado a Cuartos'
            : entry.isEliminated
                ? 'Eliminado'
                : 'En competencia');

    final color = entry.isQualified
        ? const Color(0xFF10B981)
        : entry.isEliminated
            ? AppColors.error
            : AppColors.primary;

    return Container(
      key: ValueKey('lol-advancement-badge-${entry.position}'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildEmptyMatchesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 40,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'No hay partidos en esta ronda',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'La fase o ronda seleccionada no cuenta con encuentros programados en el proveedor oficial.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCoverageView(LolWorldsStageModel data) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.lol.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 44,
                color: AppColors.lol,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Cobertura oficial no disponible',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              data.message ??
                  'La fuente oficial de Worlds requiere credenciales de API (LOL_ESPORTS_API_KEY o PANDASCORE_API_KEY) no configuradas en el entorno.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorderDark),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_outlined, size: 16, color: AppColors.textMuted),
                  SizedBox(width: 8),
                  Text(
                    'Sin datos simulados ni fixtures inventados',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: widget.onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Comprobar disponibilidad'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.lol,
                side: const BorderSide(color: AppColors.lol),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
