import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/event_model.dart';
import '../../../../models/sport_type.dart';
import '../../../../models/ufc_card_model.dart';
import '../../../../models/ufc_rankings_model.dart';
import '../../../match_detail/presentation/screens/ufc_fight_detail_screen.dart';

class UfcRankingsView extends StatefulWidget {
  final UfcRankingsModel rankings;
  final List<EventModel> allEvents;
  final VoidCallback? onRefresh;

  const UfcRankingsView({
    super.key,
    required this.rankings,
    this.allEvents = const [],
    this.onRefresh,
  });

  @override
  State<UfcRankingsView> createState() => _UfcRankingsViewState();
}

class _UfcRankingsViewState extends State<UfcRankingsView> {
  String? _selectedCategoryId;

  // ignore: unused_element
  UfcRankingCategoryModel? get _currentCategory {
    final cats = widget.rankings.categories;
    if (cats.isEmpty) return null;
    if (_selectedCategoryId == null) return cats.first;
    return cats.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => cats.first,
    );
  }

  void _navigateToFighterFight(UfcRankingFighterModel fighter) {
    final fighterName = fighter.name.toLowerCase();

    // Buscar si el peleador tiene algún combate programado o en vivo en las carteleras
    for (final event in widget.allEvents) {
      if (event.sport != SportType.ufc) continue;

      final card = event.ufcCard ?? UfcCardModel.fromEvent(event, allEvents: widget.allEvents);
      for (final fight in card.fights) {
        final f1Name = fight.fighter1.name.toLowerCase();
        final f2Name = fight.fighter2.name.toLowerCase();

        if (f1Name.contains(fighterName) ||
            fighterName.contains(f1Name) ||
            f2Name.contains(fighterName) ||
            fighterName.contains(f2Name) ||
            (fighter.participantId != null &&
                (fight.fighter1.id == fighter.participantId ||
                    fight.fighter2.id == fighter.participantId))) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => UfcFightDetailScreen(
                card: card,
                fight: fight,
                event: event,
              ),
            ),
          );
          return;
        }
      }
    }

    // Si no tiene combate activo en la cartelera, mostrar aviso limpio
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${fighter.displayName} no tiene combate programado en las próximas carteleras.',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.surfaceDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.rankings.hasCoverage || widget.rankings.categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.format_list_numbered_rounded,
                  size: 48,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cobertura no disponible',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'No se pudieron cargar los rankings oficiales de UFC desde la fuente oficial.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              if (widget.onRefresh != null) ...[
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: widget.onRefresh,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Reintentar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ufcRed,
                    side: const BorderSide(color: AppColors.ufcRed),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: widget.rankings.categories.length,
      itemBuilder: (context, index) {
        final category = widget.rankings.categories[index];
        final expanded = _selectedCategoryId == category.id;
        return Card(
          color: AppColors.surfaceDark,
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(children: [
            ListTile(
              key: ValueKey('ufc-division-${category.id}'),
              dense: true,
              title: Text(category.translatedName, style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              subtitle: Text('${category.ranks.length} clasificados',
                style: const TextStyle(color: AppColors.textSecondary)),
              trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more,
                color: AppColors.textSecondary),
              onTap: () => setState(() =>
                _selectedCategoryId = expanded ? null : category.id),
            ),
            if (expanded) Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(children: [
                const Divider(color: AppColors.borderDark),
                _buildCategoryHeader(category),
                const SizedBox(height: 8),
                if (category.champion != null)
                  _buildChampionCard(category.champion!)
                else _buildNoBeltBanner(category),
                const SizedBox(height: 12),
                for (final fighter in category.ranks) _buildFighterRow(fighter),
              ]),
            ),
          ]),
        );
      },
    );
  }

  // ignore: unused_element
  Widget _buildCategoryChips() {
    return Container(
      color: AppColors.surfaceDark,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            for (final cat in widget.rankings.categories) ...[
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: (_selectedCategoryId ?? widget.rankings.categories.first.id) == cat.id,
                  label: Text(
                    cat.translatedName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: (_selectedCategoryId ?? widget.rankings.categories.first.id) == cat.id
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                  backgroundColor: AppColors.surfaceMuted,
                  selectedColor: AppColors.ufcRed,
                  checkmarkColor: Colors.white,
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: (_selectedCategoryId ?? widget.rankings.categories.first.id) == cat.id
                          ? AppColors.ufcRed
                          : Colors.transparent,
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategoryId = cat.id;
                      });
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(UfcRankingCategoryModel category) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.translatedName.toUpperCase(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
              if (category.name != category.translatedName)
                Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
        if (category.weightLimit != null && category.weightLimit!.trim().isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Text(
              category.weightLimit!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChampionCard(UfcRankingFighterModel champion) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToFighterFight(champion),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2E2208),
                AppColors.surfaceDark,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // Avatar del campeón
              _buildFighterAvatar(champion, isChampion: true),
              const SizedBox(width: 16),

              // Información del campeón
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.military_tech_rounded,
                          size: 16,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'CAMPEÓN DE LA DIVISIÓN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      champion.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (champion.nickname != null && champion.nickname!.trim().isNotEmpty)
                      Text(
                        '"${champion.nickname}"',
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (champion.record != null) ...[
                          Text(
                            'Récord: ${champion.record}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (champion.defenses != null && champion.defenses! > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${champion.defenses} ${champion.defenses == 1 ? "defensa" : "defensas"}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoBeltBanner(UfcRankingCategoryModel category) {
    final isP4P = category.id.contains('pound-for-pound');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isP4P
                  ? 'Ranking general Libra por Libra consensuado por periodistas oficiales.'
                  : 'Sin campeón de cinturón activo asignado en esta división.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFighterRow(UfcRankingFighterModel fighter) {
    final pos = fighter.position ?? 0;
    final isTop3 = pos >= 1 && pos <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTop3
              ? AppColors.ufcRed.withValues(alpha: 0.2)
              : AppColors.borderDark,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToFighterFight(fighter),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Posición / Puesto en el ranking
                Container(
                  width: 32,
                  alignment: Alignment.center,
                  child: Text(
                    '#$pos',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: isTop3 ? AppColors.ufcRed : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Avatar
                _buildFighterAvatar(fighter, isChampion: false),
                const SizedBox(width: 12),

                // Nombre, apodo y récord
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fighter.displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (fighter.record != null && fighter.record!.trim().isNotEmpty)
                            Text(
                              fighter.record!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            )
                          else
                            const Text(
                              'Récord no reportado',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          if (fighter.country != null && fighter.country!.trim().isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              '• ${fighter.country}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Indicador de tendencia (+1, -1, =)
                if (fighter.trend != null && fighter.trend!.trim().isNotEmpty)
                  _buildTrendBadge(fighter.trend!),

                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFighterAvatar(UfcRankingFighterModel fighter, {required bool isChampion}) {
    final size = isChampion ? 56.0 : 40.0;
    final photoUrl = fighter.photoUrl;

    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(
          photoUrl.trim(),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildAvatarFallback(fighter, size, isChampion),
        ),
      );
    }

    return _buildAvatarFallback(fighter, size, isChampion);
  }

  Widget _buildAvatarFallback(UfcRankingFighterModel fighter, double size, bool isChampion) {
    final initials = fighter.name.trim().isNotEmpty
        ? fighter.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isChampion
            ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
            : AppColors.surfaceMuted,
        shape: BoxShape.circle,
        border: Border.all(
          color: isChampion ? const Color(0xFFF59E0B) : AppColors.borderDark,
          width: isChampion ? 1.5 : 1.0,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          fontSize: isChampion ? 18 : 13,
          fontWeight: FontWeight.bold,
          color: isChampion ? const Color(0xFFF59E0B) : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTrendBadge(String trend) {
    final clean = trend.trim();
    Color color = AppColors.textMuted;
    IconData icon = Icons.remove_rounded;

    if (clean.startsWith('+')) {
      color = const Color(0xFF10B981);
      icon = Icons.arrow_drop_up_rounded;
    } else if (clean.startsWith('-') && clean != '-') {
      color = const Color(0xFFEF4444);
      icon = Icons.arrow_drop_down_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          if (clean != '-' && clean != '=')
            Text(
              clean,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}
