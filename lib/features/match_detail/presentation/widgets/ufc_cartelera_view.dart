import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/event_model.dart';
import '../../../../models/ufc_card_model.dart';
import '../screens/ufc_fight_detail_screen.dart';
import 'ufc_fight_card_tile.dart';

class UfcCarteleraView extends StatefulWidget {
  final EventModel event;
  final UfcCardModel? card;
  final List<EventModel>? allEvents;

  const UfcCarteleraView({
    super.key,
    required this.event,
    this.card,
    this.allEvents,
  });

  @override
  State<UfcCarteleraView> createState() => _UfcCarteleraViewState();
}

class _UfcCarteleraViewState extends State<UfcCarteleraView> {
  int _selectedTabIndex = 0; // 0: Cartelera, 1: Información
  int _selectedFilterIndex = 0; // 0: Todas, 1: Principal, 2: Preliminares

  UfcCardModel get _card =>
      widget.card ??
      UfcCardModel.fromEvent(widget.event, allEvents: widget.allEvents);

  void _navigateToFightDetail(UfcFightModel fight) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UfcFightDetailScreen(
          card: _card,
          fight: fight,
          event: widget.event,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = _card;
    final liveFight = card.liveFight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(card),
        const SizedBox(height: 14),

        if (liveFight != null) ...[
          _buildLiveFightBanner(liveFight),
          const SizedBox(height: 16),
        ],

        _buildTabBar(),
        const SizedBox(height: 16),

        if (_selectedTabIndex == 0) ...[
          _buildFilterPills(),
          const SizedBox(height: 18),
          _buildFightsContent(card),
        ] else ...[
          _buildInfoTab(card),
        ],
      ],
    );
  }

  Widget _buildHeader(UfcCardModel card) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'UFC',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          card.name,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        if (card.subtitle != null && card.subtitle!.trim().isNotEmpty) ...[
          Text(
            card.subtitle!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        _buildCardStatusBadge(card),
      ],
    );
  }

  Widget _buildCardStatusBadge(UfcCardModel card) {
    switch (card.status) {
      case UfcCardStatus.live:
        return Container(
          constraints: const BoxConstraints(maxWidth: 240),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.liveRed.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.liveRed,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Flexible(
                child: Text(
                  'EVENTO EN CURSO',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.liveRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        );

      case UfcCardStatus.finished:
        return Container(
          constraints: const BoxConstraints(maxWidth: 240),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_rounded, size: 13, color: AppColors.textPrimary),
              SizedBox(width: 5),
              Flexible(
                child: Text(
                  'FINALIZADO',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        );

      case UfcCardStatus.scheduled:
        return Container(
          constraints: const BoxConstraints(maxWidth: 240),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.primary),
              SizedBox(width: 5),
              Flexible(
                child: Text(
                  'PROGRAMADO',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildLiveFightBanner(UfcFightModel liveFight) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _navigateToFightDetail(liveFight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                const Icon(
                  Icons.sensors_rounded,
                  color: AppColors.liveRed,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ir al combate en vivo',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${liveFight.fighter1.name} vs ${liveFight.fighter2.name} (${liveFight.weightClass})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.primary,
                  size: 15,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
          _buildTabItem(0, 'Cartelera'),
          _buildTabItem(1, 'Información'),
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

  Widget _buildFilterPills() {
    return Row(
      children: [
        _buildPill(0, 'Todas'),
        const SizedBox(width: 8),
        _buildPill(1, 'Principal'),
        const SizedBox(width: 8),
        _buildPill(2, 'Preliminares'),
      ],
    );
  }

  Widget _buildPill(int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    return Expanded(
      child: InkWell(
        key: Key('filter-pill-$label'),
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _selectedFilterIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFightsContent(UfcCardModel card) {
    final showMain = _selectedFilterIndex == 0 || _selectedFilterIndex == 1;
    final showPrelims = _selectedFilterIndex == 0 || _selectedFilterIndex == 2;

    final mainFights = card.mainFights;
    final prelimFights = card.prelimFights;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showMain && mainFights.isNotEmpty) ...[
          const Text(
            'Cartelera principal',
            key: Key('section-header-main'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          for (final fight in mainFights)
            UfcFightCardTile(
              fight: fight,
              onTap: () => _navigateToFightDetail(fight),
            ),
          const SizedBox(height: 16),
        ],

        if (showPrelims && prelimFights.isNotEmpty) ...[
          const Text(
            'Preliminares',
            key: Key('section-header-prelims'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          for (final fight in prelimFights)
            UfcFightCardTile(
              fight: fight,
              onTap: () => _navigateToFightDetail(fight),
            ),
        ],

        if (card.fights.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No hay combates registrados para esta cartelera',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoTab(UfcCardModel card) {
    final dateStr = card.formattedDate ??
        (widget.event.startTime != null
            ? _formatFallbackDate(widget.event.startTime!)
            : null);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderDark),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DETALLES DE LA VELADA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          _buildInfoRow('Promoción', 'Ultimate Fighting Championship (UFC)'),
          const Divider(color: AppColors.cardBorderDark),
          _buildInfoRow('Evento', card.name),
          if (dateStr != null) ...[
            const Divider(color: AppColors.cardBorderDark),
            _buildInfoRow('Fecha y horario', dateStr),
          ],
          if (card.venue != null && card.venue!.isNotEmpty) ...[
            const Divider(color: AppColors.cardBorderDark),
            _buildInfoRow('Recinto / Sede', card.venue!),
          ],
          if (card.city != null || card.country != null) ...[
            const Divider(color: AppColors.cardBorderDark),
            _buildInfoRow(
              'Ubicación',
              [card.city, card.country].whereType<String>().join(', '),
            ),
          ],
          const Divider(color: AppColors.cardBorderDark),
          _buildInfoRow('Estado', card.status.displayName),
          const Divider(color: AppColors.cardBorderDark),
          _buildInfoRow('Total de combates', '${card.fights.length}'),
          if (card.mainFights.isNotEmpty) ...[
            const Divider(color: AppColors.cardBorderDark),
            _buildInfoRow(
              'Cartelera principal',
              '${card.mainFights.length} combates',
            ),
          ],
          if (card.prelimFights.isNotEmpty) ...[
            const Divider(color: AppColors.cardBorderDark),
            _buildInfoRow(
              'Preliminares',
              '${card.prelimFights.length} combates',
            ),
          ],
          if (card.mainEvent != null) ...[
            const Divider(color: AppColors.cardBorderDark),
            _buildInfoRow(
              'Combate estelar',
              '${card.mainEvent!.fighter1.name} vs ${card.mainEvent!.fighter2.name}',
            ),
          ],
          if (card.coMainEvent != null && card.coMainEvent != card.mainEvent) ...[
            const Divider(color: AppColors.cardBorderDark),
            _buildInfoRow(
              'Combate co-estelar',
              '${card.coMainEvent!.fighter1.name} vs ${card.coMainEvent!.fighter2.name}',
            ),
          ],
        ],
      ),
    );
  }

  String _formatFallbackDate(DateTime dt) {
    final local = dt.toLocal();
    final months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];
    final m = months[local.month - 1];
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '${local.day} de $m, ${local.year} • $h:$min';
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
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
