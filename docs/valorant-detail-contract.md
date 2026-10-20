# Detalle de Valorant: contrato del cliente v1

Estado: implementado y probado en el cliente para la tarea kambate-mobile#6.
Define la estructura esperada en `EsportsStats.extraStats.detail` (y `extra_stats.detail`),
sin exigir migraciones de esquema en la base de datos. Se preserva en caché local
y reacciona a eventos en tiempo real.

## Estructura del bloque `detail`

| Campo | Tipo y significado |
| --- | --- |
| `version` | Entero `1`; versiones desconocidas o ausentes se ignoran |
| `homeParticipantId`, `awayParticipantId` | UUID de Participant en Supabase, distintos entre sí |
| `format` | String opcional (`Bo1`, `Bo3`, `Bo5` u otro formato específico); si no viene, no se inventa |
| `activeMapNumber` | Entero opcional que indica el mapa activo/seleccionado |
| `maps` | Lista de mapas individuales (`ValorantMapDetail`) que componen la serie |

### Estructura de cada mapa en `maps`

| Campo | Tipo y significado |
| --- | --- |
| `mapNumber` | Entero positivo (`1`, `2`, `3`, ...) |
| `mapName` | String con el nombre del mapa (ej. `Bind`, `Haven`, `Ascent`, `Lotus`, `Sunset`) |
| `status` | String opcional (`live`, `finished`, `scheduled`); deducible según ganador o rondas |
| `duration` | String opcional con la duración formateada o tiempo transcurrido (ej. `42:10`) |
| `winnerParticipantId` | UUID opcional del equipo ganador del mapa individual |
| `homeScore`, `awayScore` | Enteros opcionales con las rondas ganadas en este mapa (ej. `13` y `9`); se distinguen estrictamente del marcador de mapas de la serie |
| `currentRound` | Entero opcional con la ronda en disputa (ej. `19`) |
| `homeSide`, `awaySide` | Strings opcionales con el rol táctico actual (`Defensa`, `Ataque`, `DEF`, `ATK`) |
| `rounds` | Lista opcional de historial ronda a ronda (`ValorantRoundDetail`) |
| `stats` | Objeto opcional de métricas comparativas del mapa (`ValorantMapStats`) |
| `homePlayers`, `awayPlayers` | Listas opcionales de jugadores y agentes (`ValorantPlayerStats`) |

### Estructura de `ValorantRoundDetail`

| Campo | Tipo y significado |
| --- | --- |
| `roundNumber` | Entero positivo de la ronda (ej. `13`, `14`, ..., `19`) |
| `winnerParticipantId` | UUID del participante que se adjudicó la ronda |
| `winType` | String opcional con el método de victoria (`elimination`, `defuse`, `detonation`, `time`) |
| `winningSide` | String opcional con el bando ganador (`attack`, `defense`) |

Solo se renderizan las rondas efectivamente reportadas (en la vista de resumen se destacan las últimas 6 rondas disputadas).

### Estructura de `ValorantMapStats`

| Campo | Tipo y significado |
| --- | --- |
| `homeFirstBloods`, `awayFirstBloods` | Enteros opcionales de primeras bajas por bando |
| `homePlants`, `awayPlants` | Enteros opcionales de spikes plantadas |
| `homeDefuses`, `awayDefuses` | Enteros opcionales de spikes desactivadas |

Solo se renderizan métricas presentes en el objeto (`hasFirstBloods`, `hasPlants`, `hasDefuses`). Si el proveedor no cubre spikes o primeras sangres, no se inventan valores ficticios ni ceros engañosos.

### Estructura de `ValorantPlayerStats`

| Campo | Tipo y significado |
| --- | --- |
| `name` | String con el apodo del jugador (ej. `keznit`, `aspas`, `Mazino`) |
| `agent` | String opcional con el agente seleccionado (ej. `Jett`, `Sova`, `Omen`, `Killjoy`) |
| `role` | String opcional con el rol competitivo (`Duelista`, `Iniciador`, `Controlador`, `Centinela`) |
| `combatScore` / `acs` | Entero opcional con el Average Combat Score (ej. `245`) |
| `kills`, `deaths`, `assists` | Enteros opcionales con el desempeño KDA |
| `firstKills` | Entero opcional de primeras bajas conseguidas |
| `plants` | Entero opcional de spikes plantadas |
| `defuses` | Entero opcional de spikes desactivadas |
| `rating` | Decimal opcional con la valoración del jugador (ej. `1.24`) |

## Criterios del contrato y manejo de datos

1. **Separación estricta entre Serie y Mapas**:
   - El encabezado del partido (`ValorantMatchHeader`) muestra el resultado general de la serie (`MAPAS GANADOS`, ej. `1 — 1`).
   - El mapa seleccionado (`ValorantDetailView`) muestra las rondas ganadas en dicho mapa (`RONDAS GANADAS`, ej. `10 — 8`).
   - Se elimina cualquier confusión entre mapas ganados en la serie y rondas conseguidas en el mapa en juego.

2. **Pestañas y navegación entre mapas**:
   - Se ofrecen 3 pestañas: `Resumen`, `Mapas` y `Jugadores`.
   - Debajo de las pestañas se incluye un selector de mapas en tarjetas compactas horizontales (`Bind: 13 — 9 Finalizado`, `Haven: 8 — 13 Finalizado`, `Ascent: ● EN VIVO`).
   - Por defecto, la pantalla selecciona automáticamente el mapa activo (`EN VIVO`), o el último mapa finalizado si la serie terminó, o el mapa 1 si está por comenzar.
   - Si el usuario selecciona manualmente un mapa anterior (ej. `Bind`) y llega una actualización en tiempo real o refresco del feed, la selección se mantiene intacta para no interrumpir la inspección.

3. **Formatos de serie**:
   - Formatos soportados: `Bo1`, `Bo3`, `Bo5` (visualizados como `Al mejor de 3`, `Al mejor de 5`, `Partida única`).
   - Si el formato no se reporta en la API/proveedor, no se asume Bo3 ni Bo5; el AppBar y tarjetas muestran únicamente la liga/torneo sin sufijos ficticios.

4. **Historial de rondas ("Últimas 6 rondas")**:
   - En la pestaña `Resumen` se presenta el carrusel/fila de las últimas 6 rondas disputadas en el mapa actual con el número de ronda, ícono/logo del equipo ganador y nombre abreviado.
   - Si el mapa no reporta historial de rondas, la sección se oculta limpiamente sin crear datos simulados.

5. **Comparativa del mapa condicional**:
   - La tarjeta de comparativa (`Primeras bajas`, `Plantadas`, `Desactivaciones`) se oculta automáticamente si ningún equipo reporta métricas.
   - Cada métrica se renderiza con barras de proporción únicamente si viene presente en los datos.
   - Se incluye un botón de acción directo `Ver estadísticas de jugadores` que conmuta inmediatamente a la pestaña de `Jugadores`.

6. **Alineaciones y jugadores**:
   - La pestaña `Jugadores` agrupa el quinteto por equipo (Local y Visitante) con selector toggle.
   - Para cada jugador se muestra su agente, KDA formateado (`K / D / A`), ACS (`Average Combat Score`) y ratio K/D o rating.
   - Si no hay reporte de jugadores para el mapa seleccionado, se muestra un estado informativo claro sin errores ni bloqueos.

7. **Resolución de participantes y sincronización**:
   - `homeParticipantId` y `awayParticipantId` garantizan la correspondencia correcta de los equipos local y visitante sin depender del orden en que los participantes fueron recibidos.
   - Si los identificadores no corresponden con los participantes del evento, las secciones detalladas se desactivan de forma segura.
   - La suscripción a tiempo real en `RealtimeService` abarca las tablas `EsportsStats` y `esports_stats`.
   - Los datos de ejemplo o mocks (`val-1`, `mock_`) muestran un pie explícito de `Datos de ejemplo`.

## Verificación local (Cierre mobile #6)

- `flutter analyze lib test`: sin advertencias ni errores.
- `flutter test`: suite completa con pruebas para el contrato de Valorant, parseo de mapas, separación de marcador serie vs rondas, navegación entre pestañas, persistencia de selección, formato ausente, adaptación responsiva (320px y accesibilidad x2) y eventos en tiempo real.
- Fidelidad visual verificada frente al prototipo de referencia `01a10501-9872-7090-87ed-5ca135e89f6e/exec-64d7bfa5-fc06-4d75-95e3-ec305fe769a3.png`.
