import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/event_model.dart';
import '../../../feed/providers/feed_provider.dart';
import 'ufc_cartelera_view.dart';

/// Vista de cartelera y combates de UFC dentro del detalle de evento.
/// Elimina cualquier resultado ficticio de ejemplo y delega a la vista
/// oficial de cartelera con filtros, combates ordenados y navegación al detalle.
class UfcDetailView extends ConsumerWidget {
  final EventModel event;

  const UfcDetailView({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedEvents = ref.watch(feedNotifierProvider).asData?.value;
    return UfcCarteleraView(
      event: event,
      allEvents: feedEvents,
    );
  }
}

