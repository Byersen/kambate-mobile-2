import 'package:flutter/material.dart';
import '../../models/event_status.dart';

class EventStatusChip extends StatelessWidget {
  const EventStatusChip({super.key, required this.status});

  final EventStatus status;

  @override
  Widget build(BuildContext context) {
    final icon = switch (status) {
      EventStatus.live => Icons.circle,
      EventStatus.scheduled => Icons.schedule_rounded,
      EventStatus.finished => Icons.check_rounded,
      EventStatus.postponed => Icons.pause_circle_outline,
      EventStatus.canceled => Icons.cancel_outlined,
      EventStatus.archived => Icons.inventory_2_outlined,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: status == EventStatus.live ? 8 : 13,
            color: status.color,
          ),
          const SizedBox(width: 5),
          Text(
            status.displayName,
            style: TextStyle(
              color: status.color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
