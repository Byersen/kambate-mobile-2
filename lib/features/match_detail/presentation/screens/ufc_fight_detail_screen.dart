import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/event_model.dart';
import '../../../../models/ufc_card_model.dart';
import '../widgets/stat_comparison_bar.dart';

class UfcFightDetailScreen extends StatefulWidget {
  final UfcCardModel card;
  final UfcFightModel fight;
  final EventModel? event;

  const UfcFightDetailScreen({
    super.key,
    required this.card,
    required this.fight,
    this.event,
  });

  @override
  State<UfcFightDetailScreen> createState() => _UfcFightDetailScreenState();
}

class _UfcFightDetailScreenState extends State<UfcFightDetailScreen> {
  int _selectedTabIndex = 0; // 0: Resumen, 1: Cara a cara, 2: Estadísticas

  UfcFightModel get fight => widget.fight;
  UfcCardModel get card => widget.card;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver a la cartelera',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              fight.categoryHeader,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              card.name.toUpperCase(),
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildFightHeaderHero(),
          const SizedBox(height: 18),
          _buildTabBar(),
          const SizedBox(height: 18),
          if (_selectedTabIndex == 0)
            _buildSummaryTab()
          else if (_selectedTabIndex == 1)
            _buildTaleOfTheTapeTab()
          else
            _buildStatsTab(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFightHeaderHero() {
    final isLive = fight.isLive;
    final f1 = fight.fighter1;
    final f2 = fight.fighter2;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLive ? AppColors.primary : AppColors.cardBorderDark,
          width: isLive ? 1.5 : 1.0,
        ),
        boxShadow: isLive
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  fight.categoryHeader.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: fight.isMainEvent
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              _buildStatusChip(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    _buildAvatar(f1, isWinner: fight.winnerId == f1.id),
                    const SizedBox(height: 8),
                    Text(
                      f1.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (f1.nickname != null && f1.nickname!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '"${f1.nickname}"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (f1.record != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        f1.record!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'VS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (fight.isScheduled) ...[
                      const SizedBox(height: 6),
                      Text(
                        fight.timeOrOrderLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    _buildAvatar(f2, isWinner: fight.winnerId == f2.id),
                    const SizedBox(height: 8),
                    Text(
                      f2.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (f2.nickname != null && f2.nickname!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '"${f2.nickname}"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (f2.record != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        f2.record!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (fight.hasConfirmedResult) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFF10B981),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ganador: ${fight.winnerName}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF047857),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          fight.result?.formattedSummary(
                                fallbackWinner: fight.winnerName,
                              ) ??
                              'Victoria confirmada',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    switch (fight.status) {
      case UfcFightStatus.live:
        final r = fight.currentRound != null
            ? 'Asalto ${fight.currentRound}'
            : 'En vivo';
        final c = fight.clock != null && fight.clock!.isNotEmpty
            ? ' • ${fight.clock}'
            : '';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.liveRed.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'EN VIVO • $r$c',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.liveRed,
            ),
          ),
        );
      case UfcFightStatus.finished:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'FINALIZADO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        );
      case UfcFightStatus.canceled:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'CANCELADO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
        );
      case UfcFightStatus.scheduled:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'PROGRAMADO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        );
    }
  }

  Widget _buildAvatar(UfcFighterModel fighter, {bool isWinner = false}) {
    final photo = fighter.photoUrl;
    final hasPhoto = photo != null && photo.trim().isNotEmpty;
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.surfaceMuted,
          backgroundImage: hasPhoto ? NetworkImage(photo.trim()) : null,
          onBackgroundImageError: hasPhoto ? (exception, stackTrace) {} : null,
          child: !hasPhoto
              ? Text(
                  _initials(fighter.name),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                )
              : null,
        ),
        if (isWinner)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 13,
              color: Colors.white,
            ),
          ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.isNotEmpty && parts[0].isNotEmpty
        ? parts[0][0].toUpperCase()
        : 'UF';
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorderDark, width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildTabItem(0, 'Resumen'),
          _buildTabItem(1, 'Cara a cara'),
          _buildTabItem(2, 'Estadísticas'),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryTab() {
    final result = fight.result;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (fight.hasConfirmedResult && result != null) ...[
          const Text(
            'RESULTADO OFICIAL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorderDark),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow('Ganador', fight.winnerName ?? 'No disponible'),
                if (result.method != null) ...[
                  const Divider(color: AppColors.cardBorderDark),
                  _buildInfoRow('Método de victoria', result.method!),
                ],
                if (result.methodDetail != null &&
                    result.methodDetail!.isNotEmpty) ...[
                  const Divider(color: AppColors.cardBorderDark),
                  _buildInfoRow('Detalle del método', result.methodDetail!),
                ],
                if (result.round != null) ...[
                  const Divider(color: AppColors.cardBorderDark),
                  _buildInfoRow('Asalto de finalización', 'Asalto ${result.round}'),
                ],
                if (result.time != null && result.time!.isNotEmpty) ...[
                  const Divider(color: AppColors.cardBorderDark),
                  _buildInfoRow('Tiempo oficial', result.time!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],

        const Text(
          'INFORMACIÓN DEL COMBATE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorderDark),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildInfoRow('Categoría', fight.weightClass),
              const Divider(color: AppColors.cardBorderDark),
              _buildInfoRow(
                'Asaltos programados',
                '${fight.roundsScheduled} asaltos',
              ),
              const Divider(color: AppColors.cardBorderDark),
              _buildInfoRow(
                'Combate por título',
                fight.titleFight ? 'Sí (Campeonato Mundial)' : 'No',
              ),
              if (fight.referee != null && fight.referee!.isNotEmpty) ...[
                const Divider(color: AppColors.cardBorderDark),
                _buildInfoRow('Árbitro principal', fight.referee!),
              ],
              const Divider(color: AppColors.cardBorderDark),
              _buildInfoRow('Cartelera / Evento', card.name),
              if (card.venue != null && card.venue!.isNotEmpty) ...[
                const Divider(color: AppColors.cardBorderDark),
                _buildInfoRow('Sede', card.venue!),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaleOfTheTapeTab() {
    final tape = fight.taleOfTheTape;
    final f1 = fight.fighter1;
    final f2 = fight.fighter2;

    if (tape == null || !tape.hasAnyData) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Text(
            'Datos físicos comparativos no reportados para este combate.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TALE OF THE TAPE • CARA A CARA',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorderDark),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (tape.division != null && tape.division!.isNotEmpty) ...[
                _buildTapeRow('División', tape.division!, tape.division!),
                const Divider(color: AppColors.cardBorderDark),
              ],
              if ((tape.record1 != null && tape.record1!.isNotEmpty) ||
                  (f1.record != null && f2.record != null)) ...[
                _buildTapeRow(
                  'Récord MMA',
                  tape.record1 ?? f1.record ?? '—',
                  tape.record2 ?? f2.record ?? '—',
                ),
                const Divider(color: AppColors.cardBorderDark),
              ],
              if (tape.height1 != null && tape.height2 != null) ...[
                _buildTapeRow('Estatura', tape.height1!, tape.height2!),
                const Divider(color: AppColors.cardBorderDark),
              ],
              if (tape.reach1 != null && tape.reach2 != null) ...[
                _buildTapeRow('Alcance', tape.reach1!, tape.reach2!),
                const Divider(color: AppColors.cardBorderDark),
              ],
              if (tape.stance1 != null && tape.stance2 != null) ...[
                _buildTapeRow('Guardia', tape.stance1!, tape.stance2!),
                const Divider(color: AppColors.cardBorderDark),
              ],
              if (tape.age1 != null && tape.age2 != null) ...[
                _buildTapeRow('Edad', '${tape.age1} años', '${tape.age2} años'),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsTab() {
    final stats = fight.stats;

    if (stats == null || !stats.hasStats) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            fight.isScheduled
                ? 'El combate está programado. Las estadísticas se publicarán en tiempo real una vez iniciada la pelea.'
                : 'Estadísticas oficiales no disponibles para este combate.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ESTADÍSTICAS DEL COMBATE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorderDark),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (stats.homeSigStrikes != null && stats.awaySigStrikes != null) ...[
                StatComparisonBar(
                  label: 'Golpes Significativos',
                  homeValueText: stats.homeSigStrikes!,
                  awayValueText: stats.awaySigStrikes!,
                  homeRatio: stats.homeSigStrikeRatio ?? 0.5,
                  accentColor: AppColors.primary,
                ),
              ],
              if (stats.homeSigStrikePct != null && stats.awaySigStrikePct != null) ...[
                StatComparisonBar(
                  label: 'Efectividad de Golpeo',
                  homeValueText: stats.homeSigStrikePct!,
                  awayValueText: stats.awaySigStrikePct!,
                  homeRatio: stats.homeSigStrikePctRatio ?? 0.5,
                  accentColor: AppColors.primary,
                ),
              ],
              if (stats.homeTakedowns != null && stats.awayTakedowns != null) ...[
                StatComparisonBar(
                  label: 'Derribos Completados',
                  homeValueText: stats.homeTakedowns!,
                  awayValueText: stats.awayTakedowns!,
                  homeRatio: stats.homeTakedownRatio ?? 0.5,
                  accentColor: AppColors.primary,
                ),
              ],
              if (stats.homeSubAttempts != null && stats.awaySubAttempts != null) ...[
                StatComparisonBar(
                  label: 'Intentos de Sumisión',
                  homeValueText: stats.homeSubAttempts!,
                  awayValueText: stats.awaySubAttempts!,
                  homeRatio: stats.homeSubAttemptRatio ?? 0.5,
                  accentColor: AppColors.primary,
                ),
              ],
              if (stats.homeControlTime != null && stats.awayControlTime != null) ...[
                StatComparisonBar(
                  label: 'Tiempo de Control',
                  homeValueText: stats.homeControlTime!,
                  awayValueText: stats.awayControlTime!,
                  homeRatio: stats.homeControlRatio ?? 0.5,
                  accentColor: AppColors.primary,
                ),
              ],
            ],
          ),
        ),

        if (stats.rounds.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text(
            'ESTADÍSTICAS POR ASALTO DISPONIBLES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          for (final round in stats.rounds) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorderDark),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Asalto ${round.roundNumber}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (round.homeSigStrikes != null && round.awaySigStrikes != null)
                    _buildRoundStatRow(
                      'Golpes significativos',
                      round.homeSigStrikes!,
                      round.awaySigStrikes!,
                    ),
                  if (round.homeTotalStrikes != null && round.awayTotalStrikes != null)
                    _buildRoundStatRow(
                      'Golpes totales',
                      round.homeTotalStrikes!,
                      round.awayTotalStrikes!,
                    ),
                  if (round.homeTakedowns != null && round.awayTakedowns != null)
                    _buildRoundStatRow(
                      'Derribos',
                      round.homeTakedowns!,
                      round.awayTakedowns!,
                    ),
                  if (round.homeControlTime != null && round.awayControlTime != null)
                    _buildRoundStatRow(
                      'Control',
                      round.homeControlTime!,
                      round.awayControlTime!,
                    ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildRoundStatRow(String label, String v1, String v2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              v1,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              v2,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTapeRow(String attribute, String f1Value, String f2Value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              f1Value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              attribute,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              f2Value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
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
}
