import 'package:flutter/material.dart';
import '../../../../models/event_model.dart';
import 'ufc_cartelera_view.dart';

/// Vista de cartelera y combates de UFC dentro del detalle de evento.
/// Elimina cualquier resultado ficticio de ejemplo y delega a la vista
/// oficial de cartelera con filtros, combates ordenados y navegación al detalle.
class UfcDetailView extends StatelessWidget {
  final EventModel event;

  const UfcDetailView({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return UfcCarteleraView(event: event);
  }
}
