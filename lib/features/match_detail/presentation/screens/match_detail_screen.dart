import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/event_model.dart';
import '../../../../models/event_status.dart';
import '../../../feed/presentation/widgets/live_badge.dart';

class MatchDetailScreen extends StatelessWidget {
  final EventModel event;

  const MatchDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'es_ES');

    return Scaffold(
      appBar: AppBar(
        title: Text(event.league),
        actions: [
          IconButton(
            icon: Icon(
              event.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: event.isFavorite ? AppColors.warning : AppColors.textPrimary,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Main Scoreboard Card
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Status
                  if (event.isLive)
                    LiveBadge(text: event.currentPeriod ?? 'EN VIVO')
                  else if (event.status == EventStatus.finished)
                    const Text('FINALIZADO', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold))
                  else
                    Text(
                      '${dateFormat.format(event.startTime)} • ${timeFormat.format(event.startTime)}',
                      style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600),
                    ),

                  const SizedBox(height: 20),

                  if (event.isCombat)
                    _buildCombatScoreboard()
                  else
                    _buildTeamScoreboard(),

                  if (event.venue != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          event.venue!,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Event Info & Details Section
          const Text(
            'DETALLES DEL ENCUENTRO',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),

          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDetailRow('Disciplina', event.sport.displayName),
                  const Divider(color: AppColors.cardBorderDark),
                  _buildDetailRow('Torneo / Liga', event.league),
                  const Divider(color: AppColors.cardBorderDark),
                  _buildDetailRow('Estado', event.status.displayName),
                  if (event.currentPeriod != null) ...[
                    const Divider(color: AppColors.cardBorderDark),
                    _buildDetailRow('Tiempo / Periodo', event.currentPeriod!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamScoreboard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Home
        Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.surfaceDark,
                child: Text(
                  event.homeTeam?.shortName ?? 'LOC',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                event.homeTeam?.name ?? 'Local',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
        ),

        // Score
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            event.homeScore != null && event.awayScore != null
                ? '${event.homeScore} - ${event.awayScore}'
                : 'VS',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
        ),

        // Away
        Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.surfaceDark,
                child: Text(
                  event.awayTeam?.shortName ?? 'VIS',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                event.awayTeam?.name ?? 'Visitante',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCombatScoreboard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.surfaceDark,
                child: Text(
                  event.fighter1?.name.substring(0, 1) ?? '1',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.ufc),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                event.fighter1?.name ?? 'Peleador 1',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              if (event.fighter1?.record != null)
                Text(event.fighter1!.record!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            event.fightResult ?? 'VS',
            style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.surfaceDark,
                child: Text(
                  event.fighter2?.name.substring(0, 1) ?? '2',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.ufc),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                event.fighter2?.name ?? 'Peleador 2',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              if (event.fighter2?.record != null)
                Text(event.fighter2!.record!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
