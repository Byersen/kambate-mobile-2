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
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'live':
      case 'in_progress':
      case 'status_in_progress':
      case 'en_vivo':
        return EventStatus.live;
      case 'finished':
      case 'ended':
      case 'status_final':
      case 'finalizado':
        return EventStatus.finished;
      case 'postponed':
      case 'status_postponed':
      case 'aplazado':
      case 'suspendido':
      case 'suspended':
      case 'status_suspended':
        return EventStatus.postponed;
      case 'canceled':
      case 'cancelled':
      case 'status_canceled':
      case 'status_abandoned':
      case 'abandoned':
      case 'cancelado':
        return EventStatus.canceled;
      case 'archived':
      case 'archivado':
        return EventStatus.archived;
      case 'scheduled':
      case 'status_scheduled':
      case 'upcoming':
      case 'programado':
      default:
        return EventStatus.scheduled;
    }
  }
}
