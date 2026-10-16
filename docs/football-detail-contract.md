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

## Verificación local (2026-10-16 - Cierre mobile #3)

- flutter analyze lib test: sin issues.
- flutter test: 28 pruebas aprobadas, cubriendo el contrato de detalle,
  actualizaciones en tiempo real, persistencia de favoritos y navegación.
- Diseño visual alineado al prototipo de referencia (exec-5fba49bd-7367-414a-b735-a709013f4f64.png):
  - AppBar centrado con liga y disciplina FÚTBOL, con botón de favoritos interactivo.
  - Header simétrico de 3 columnas con escudo y nombre local a la izquierda, badge
    EN VIVO / reloj / periodo y marcador al centro, y visitante a la derecha.
  - Pestaña Resumen con Momentos del partido (cronología con iconos dedicados de gol,
    tarjetas y cambios) y Estadísticas clave con enlace funcional a la pestaña Estadísticas.
  - Pestañas de Estadísticas y Alineaciones con presentación de datos reales y estados
    claros de datos no disponibles según contrato.
  - Soporte de RefreshIndicator y aviso informativo en caso de pérdida de conexión.
  - Verificado en 320 px con escala de texto x2 sin desbordamientos de layout.

