import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/event_status_chip.dart';
import '../../../../models/event_model.dart';
import '../../../../models/event_status.dart';
import '../../../../models/sport_type.dart';
import '../../../../models/ufc_card_model.dart';
import '../../../match_detail/presentation/screens/ufc_fight_detail_screen.dart';
import '../../../match_detail/presentation/widgets/ufc_fight_card_tile.dart';

class UfcUpcomingCardsView extends StatefulWidget {
  final List<EventModel> allEvents;
  final VoidCallback? onRefresh;

  const UfcUpcomingCardsView({
    super.key,
    required this.allEvents,
    this.onRefresh,
  });

  @override
  State<UfcUpcomingCardsView> createState() => _UfcUpcomingCardsViewState();
}

class _UfcUpcomingCardsViewState extends State<UfcUpcomingCardsView> {
  // Guarda el cardId de las carteleras expandidas (por defecto la primera está expandida)
  final Set<String> _expandedCardIds = {};

  @override
  void initState() {
    super.initState();
  }

  void _navigateToFightDetail(UfcCardModel card, UfcFightModel fight, EventModel event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UfcFightDetailScreen(
          card: card,
          fight: fight,
          event: event,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final upcomingCards = UfcCardModel.groupUpcomingCards(widget.allEvents);

    if (upcomingCards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_busy_rounded,
                  size: 48,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No hay próximas carteleras',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Actualmente no hay veladas de UFC programadas en el calendario oficial.',
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
                  label: const Text('Actualizar'),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: upcomingCards.length,
      itemBuilder: (context, index) {
        final card = upcomingCards[index];
        final isFirst = index == 0;
        final isExpanded = _expandedCardIds.contains(card.cardId) ||
            (_expandedCardIds.isEmpty && isFirst);

        // Evento de referencia de la velada para navegación
        final refEvent = widget.allEvents.firstWhere(
          (e) =>
              e.ufcCard?.cardId == card.cardId ||
              e.league.trim().toLowerCase() == card.name.trim().toLowerCase(),
          orElse: () => EventModel(
            id: card.cardId,
            sport: SportType.ufc,
            league: card.name,
            startTime: card.date ?? DateTime.now(),
            status: card.isLive ? EventStatus.live : EventStatus.scheduled,
          ),
        );

        return _buildCardItem(card, isExpanded, refEvent);
      },
    );
  }

  Widget _buildCardItem(UfcCardModel card, bool isExpanded, EventModel refEvent) {
    final liveFight = card.liveFight;
    final mainEvent = card.mainEvent;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: card.isLive
              ? AppColors.ufcRed.withValues(alpha: 0.6)
              : AppColors.borderDark,
          width: card.isLive ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner de evento en vivo si la cartelera tiene combate activo
          if (card.isLive && liveFight != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.ufcRed,
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sensors_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'EN VIVO: ${liveFight.fighter1.name} vs. ${liveFight.fighter2.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () => _navigateToFightDetail(card, liveFight, refEvent),
                    child: const Text(
                      'Ver combate >',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Cabecera interactiva para expandir/colapsar
          InkWell(
            onTap: () {
              setState(() {
                if (_expandedCardIds.contains(card.cardId)) {
                  _expandedCardIds.remove(card.cardId);
                } else {
                  _expandedCardIds.add(card.cardId);
                }
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          card.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      EventStatusChip(
                        status: card.isLive ? EventStatus.live : EventStatus.scheduled,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Fecha y hora
                  if (card.formattedDate != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          card.formattedDate!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                  // Sede y ubicación
                  if (card.venue != null && card.venue!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            [
                              card.venue,
                              if (card.city != null && card.city!.trim().isNotEmpty) card.city,
                              if (card.country != null && card.country!.trim().isNotEmpty) card.country,
                            ].join(', '),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Combate estelar destacado si la tarjeta está colapsada
                  if (!isExpanded && mainEvent != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Estelar: ${mainEvent.fighter1.name} vs. ${mainEvent.fighter2.name} (${mainEvent.weightClass})',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Contenido desplegado: lista ordenada de combates y segmentos
          if (isExpanded) ...[
            const Divider(height: 1, color: AppColors.borderDark),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cartelera principal
                  if (card.mainFights.isNotEmpty) ...[
                    _buildSegmentHeader('CARTELERA PRINCIPAL', card.mainFights.length),
                    const SizedBox(height: 8),
                    for (final fight in card.mainFights)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: UfcFightCardTile(
                          fight: fight,
                          onTap: () => _navigateToFightDetail(card, fight, refEvent),
                        ),
                      ),
                  ],

                  // Preliminares
                  if (card.prelimFights.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildSegmentHeader('PRELIMINARES', card.prelimFights.length),
                    const SizedBox(height: 8),
                    for (final fight in card.prelimFights)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: UfcFightCardTile(
                          fight: fight,
                          onTap: () => _navigateToFightDetail(card, fight, refEvent),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSegmentHeader(String label, int fightCount) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.ufcRed,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          '$fightCount combates',
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
