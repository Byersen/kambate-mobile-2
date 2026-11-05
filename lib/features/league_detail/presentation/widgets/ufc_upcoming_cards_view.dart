import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/event_model.dart';
import '../../../../models/event_status.dart';
import '../../../../models/sport_type.dart';
import '../../../../models/ufc_card_model.dart';
import '../../../match_detail/presentation/screens/ufc_fight_detail_screen.dart';
import '../../../match_detail/presentation/widgets/ufc_cartelera_view.dart';

class UfcUpcomingCardsView extends StatelessWidget {
  final List<EventModel> allEvents;
  final VoidCallback? onRefresh;

  const UfcUpcomingCardsView({
    super.key,
    required this.allEvents,
    this.onRefresh,
  });

  void _navigateToCardFights(
    BuildContext context,
    UfcCardModel card,
    EventModel refEvent,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'UFC',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                fontSize: 26,
                letterSpacing: 1.2,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: UfcCarteleraView(
              event: refEvent,
              card: card,
              allEvents: allEvents,
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToFightDetail(
    BuildContext context,
    UfcCardModel card,
    UfcFightModel fight,
    EventModel event,
  ) {
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
    final upcomingCards = UfcCardModel.groupUpcomingCards(allEvents);

    if (upcomingCards.isEmpty) {
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
              if (onRefresh != null) ...[
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: onRefresh,
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

        final refEvent = allEvents.firstWhere(
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

        return _buildCardItem(context, card, refEvent);
      },
    );
  }

  Widget _buildCardItem(
    BuildContext context,
    UfcCardModel card,
    EventModel refEvent,
  ) {
    final liveFight = card.liveFight;
    final headline = _resolveHeadline(card);
    final dateLine = card.date != null ? _formatSimpleCardDate(card.date!) : null;
    final locationLines = _resolveLocationLines(card);

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                    onTap: () =>
                        _navigateToFightDetail(context, card, liveFight, refEvent),
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
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey('ufc-card-${card.cardId}'),
              onTap: () => _navigateToCardFights(context, card, refEvent),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: _buildBrandLogo(card)),
                    const SizedBox(height: 18),
                    Text(
                      headline,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: Color(0xFF111111),
                      ),
                    ),
                    if (dateLine != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        dateLine,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ],
                    if (locationLines.venue != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        locationLines.venue!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (locationLines.cityCountry != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        locationLines.cityCountry!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandLogo(UfcCardModel card) {
    final lower = card.name.toLowerCase();
    final isFightNight =
        lower.contains('fight night') || lower.contains('noche de combates');

    if (isFightNight) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'UFC',
            style: TextStyle(
              color: Color(0xFF111111),
              fontSize: 28,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.0,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                'FIGHT ',
                style: TextStyle(
                  color: Color(0xFF111111),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.6,
                ),
              ),
              Container(
                padding: const EdgeInsets.only(bottom: 1),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF111111), width: 2.2),
                  ),
                ),
                child: const Text(
                  'NIGHT',
                  style: TextStyle(
                    color: Color(0xFF111111),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return const Text(
      'UFC',
      style: TextStyle(
        color: Color(0xFF111111),
        fontSize: 30,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        letterSpacing: 1.2,
        height: 1.0,
      ),
    );
  }

  String _resolveHeadline(UfcCardModel card) {
    final raw = card.name.trim();
    if (raw.contains(':')) {
      final afterColon = raw.split(':').sublist(1).join(':').trim();
      if (afterColon.isNotEmpty) {
        return afterColon
            .replaceAll(RegExp(r'\bvs\b\.?', caseSensitive: false), 'VS')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim()
            .toUpperCase();
      }
    }

    final main = card.mainEvent;
    if (main != null) {
      String lastName(String fullName) {
        final parts = fullName.trim().split(RegExp(r'\s+'));
        return parts.isNotEmpty ? parts.last : fullName.trim();
      }

      final f1 = lastName(main.fighter1.name);
      final f2 = lastName(main.fighter2.name);
      if (f1.isNotEmpty && f2.isNotEmpty) {
        return '$f1 VS $f2'.toUpperCase();
      }
    }

    return raw
        .replaceAll(RegExp(r'\bvs\b\.?', caseSensitive: false), 'VS')
        .toUpperCase();
  }

  String _formatSimpleCardDate(DateTime date) {
    final local = date.toLocal();
    const weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    final dayName = weekdays[local.weekday - 1];
    final monthName = months[local.month - 1];
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$dayName, $monthName ${local.day} / $hour:$minute CHI / Cartelera Estelar';
  }

  ({String? venue, String? cityCountry}) _resolveLocationLines(UfcCardModel card) {
    final rawVenue = card.venue?.trim();
    final rawCity = card.city?.trim();
    final rawCountry = card.country?.trim();

    final hasExplicitCityCountry =
        (rawCity != null && rawCity.isNotEmpty) ||
        (rawCountry != null && rawCountry.isNotEmpty);

    if (hasExplicitCityCountry) {
      final cityCountry = [rawCity, rawCountry]
          .where((s) => s != null && s.isNotEmpty)
          .join(' ');
      String? cleanVenue = rawVenue;
      if (cleanVenue != null && cleanVenue.contains(',')) {
        cleanVenue = cleanVenue.split(',').first.trim();
      }
      return (
        venue: (cleanVenue != null && cleanVenue.isNotEmpty) ? cleanVenue : null,
        cityCountry: cityCountry.isNotEmpty ? cityCountry : null,
      );
    }

    if (rawVenue != null && rawVenue.isNotEmpty) {
      if (rawVenue.contains(',')) {
        final parts = rawVenue.split(',');
        final v = parts.first.trim();
        final loc = parts.sublist(1).join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
        return (
          venue: v.isNotEmpty ? v : null,
          cityCountry: loc.isNotEmpty ? loc : null,
        );
      }
      return (venue: rawVenue, cityCountry: null);
    }

    return (venue: null, cityCountry: null);
  }
}
