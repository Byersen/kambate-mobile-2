# Detalle de fútbol: contrato del cliente v1

Estado: implementado y probado en el cliente. El productor fue integrado en
Byersen/kambate-backend#6 y persiste el bloque desde respuestas de ESPN. Esto no
acredita cobertura completa del proveedor ni cierra kambate-mobile#3.

El cliente lee el bloque opcional FootballStats.extraStats.detail, sin migración
de esquema. Tanto extraStats como extra_stats se conservan en la caché.

Campos:

| Campo | Tipo y significado |
| --- | --- |
| version | Entero 1; versiones desconocidas se ignoran |
| homeParticipantId, awayParticipantId | UUID de Participant en Supabase, distintos entre sí |
| statistics | Lista de {key, home, away}; valores numéricos no negativos o null |
| timeline | null si no hay cobertura; lista en orden cronológico si existe |
| homeLineup, awayLineup | null o {formation, starters, substitutes} |

Las claves de estadísticas admitidas son possession (0–100), shots,
shotsOnTarget, corners, fouls, yellowCards, redCards y offsides.
Un cero recibido es un dato válido; null, valores inválidos y campos ausentes
se muestran como “—”. No se dibuja una proporción para valores incompletos
ni para dos ceros. Las tarjetas se cuentan únicamente desde eventos recibidos;
la ausencia de cobertura detallada no se sustituye por datos de ejemplo.

Cada incidencia contiene kind (goal, yellowCard, redCard o substitution),
side (home o away), minute (texto de visualización, incluida prórroga),
player y secondaryPlayer opcionales. En cambios, player es quien entra y
secondaryPlayer quien sale; en goles, secondaryPlayer es quien asiste.
El productor debe conservar el orden real y omitir clases no soportadas.

Cada alineación contiene formation opcional y listas starters/substitutes
con {name, number, position}. No se inventan jugadores ni formaciones.
Las listas pueden ser parciales; no se exige que tengan once jugadores.

Los identificadores resuelven los equipos sin depender del orden de la relación
participants. Si los equipos del detalle no coinciden con los del evento,
las secciones se muestran como no disponibles. Sin este bloque se mantiene el
comportamiento anterior de identificación de participantes.

Actualizaciones: el marcador y el estado usan el feed observado por la pantalla.
Un refresco del feed renueva el bloque completo y conserva la pestaña elegida.
La suscripción Realtime cubre Event y FootballStats; cuando cambia el detalle,
el cliente vuelve a consultar el evento relacionado y conserva favoritos.

No se han modificado datos remotos. La forma de scoreboard y summary se validó
con consultas de solo lectura a ESPN; falta validar el flujo completo en el
proyecto Supabase autorizado. Las capturas de pruebas son ilustrativas y se
guardan en build/previews, fuera de Git.

## Verificación local (2026-10-15)

- flutter analyze --no-pub lib test: sin issues.
- flutter test --no-pub: 26 pruebas aprobadas, incluidas la traducción de
  eventId/event_id y la recarga de FootballStats conservando favoritos.
- Capturas revisadas de Inicio, resumen, estadísticas y alineaciones, cargando
  Inter y MaterialIcons con CAPTURE_PREVIEW=true.
- Comprobados: navegación de ida y vuelta, marcador actualizado desde el feed,
  pestaña conservada, cuatro estados del encuentro, datos parciales, equipos
  invertidos/no coincidentes y 320 px con texto al doble.
- No validado aún: cobertura ni actualizaciones de detalles contra Supabase real.
