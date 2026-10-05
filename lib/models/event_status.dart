import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum EventStatus {
  live(id: 'live', displayName: 'EN VIVO', color: AppColors.liveRed),
  scheduled(
    id: 'scheduled',
    displayName: 'PROGRAMADO',
    color: AppColors.secondary,
  ),
  finished(
    id: 'finished',
    displayName: 'FINALIZADO',
    color: AppColors.textMuted,
  ),
  postponed(id: 'postponed', displayName: 'APLAZADO', color: AppColors.warning),
  canceled(
    id: 'canceled',
    displayName: 'CANCELADO',
    color: AppColors.textMuted,
  ),
  archived(
    id: 'archived',
    displayName: 'ARCHIVADO',
    color: AppColors.textMuted,
  );

  final String id;
  final String displayName;
  final Color color;

  const EventStatus({
    required this.id,
    required this.displayName,
    required this.color,
  });

  static EventStatus fromString(String? value) {
    if (value == null) return EventStatus.scheduled;
    switch (value.toLowerCase()) {
      case 'live':
      case 'in_progress':
      case 'en_vivo':
        return EventStatus.live;
      case 'finished':
      case 'ended':
      case 'finalizado':
        return EventStatus.finished;
      case 'postponed':
      case 'aplazado':
        return EventStatus.postponed;
      case 'canceled':
      case 'cancelled':
        return EventStatus.canceled;
      case 'archived':
        return EventStatus.archived;
      case 'scheduled':
      case 'upcoming':
      default:
        return EventStatus.scheduled;
    }
  }
}
