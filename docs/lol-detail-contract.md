# Detalle de League of Legends (LoL): contrato del cliente v1

Estado: implementado y probado en el cliente para la tarea kambate-mobile#5.
Define la estructura esperada en `EsportsStats.extraStats.detail` (y `extra_stats.detail`),
sin exigir migraciones de esquema en la base de datos. Se preserva en caché local
y reacciona a eventos en tiempo real.

## Estructura del bloque `detail`

| Campo | Tipo y significado |
| --- | --- |
| `version` | Entero `1`; versiones desconocidas o ausentes se ignoran |
| `homeParticipantId`, `awayParticipantId` | UUID de Participant en Supabase, distintos entre sí |
| `format` | String opcional (`Bo1`, `Bo3`, `Bo5` u otro formato específico); si no viene, no se inventa |
| `games` | Lista de partidas individuales (`LolGameDetail`) que componen la serie |

### Estructura de cada partida en `games`

| Campo | Tipo y significado |
| --- | --- |
| `gameNumber` | Entero positivo (`1`, `2`, `3`, ...) |
| `status` | String opcional (`live`, `finished`, `scheduled`); si se omite, se deduce según ganador o kills |
| `winnerParticipantId` | UUID opcional del equipo ganador de la partida individual |
| `durationSeconds` | Entero opcional con la duración en segundos (ej. `2142` -> `35:42`) |
| `mapName` | String opcional (ej. `Grieta del Invocador` o `Summoner's Rift`) |
| `homeKills`, `awayKills` | Enteros opcionales con los asesinatos de la partida; se distinguen estrictamente del marcador de serie |
| `homeObjectives`, `awayObjectives` | Objetos opcionales de recursos/objetivos (`LolGameObjectives`) |
| `homePlayers`, `awayPlayers` | Listas opcionales de jugadores (`LolPlayerStats`) |

### Estructura de `LolGameObjectives`

| Campo | Tipo y significado |
| --- | --- |
| `gold` | Entero opcional (oro total acumulado, formateado como `68.4k`) |
| `towers` | Entero opcional (torretas destruidas) |
| `dragons` | Entero opcional (dragones asegurados) |
| `barons` | Entero opcional (barones derrotados) |

Solo se renderizan métricas que vengan presentes en el JSON (`hasGold`, `hasTowers`, `hasDragons`, `hasBarons`). Si el proveedor no cubre dragones o barones, no se inventan valores ficticios ni ceros engañosos.

### Estructura de `LolPlayerStats`

| Campo | Tipo y significado |
| --- | --- |
| `name` | String con el apodo del jugador (ej. `Faker`, `Chovy`) |
| `role` | String opcional con el rol (`TOP`, `JGL`, `MID`, `BOT`, `SUP`) |
| `champion` | String opcional con el campeón jugado (ej. `Azir`, `Yone`) |
| `kills`, `deaths`, `assists` | Enteros opcionales con el desempeño KDA |
| `cs` | Entero opcional de súbditos/farm (Creep Score) |

## Criterios del contrato y manejo de datos

1. **Separación estricta entre Serie y Partidas**:
   - El encabezado del partido (`LolMatchHeader`) muestra el resultado general de la serie (`PARTIDAS GANADAS`, ej. `1 — 1`).
   - La partida seleccionada (`LolDetailView`) muestra los asesinatos de esa partida individual (`ASESINATOS`, ej. `18 — 12`).
   - Se elimina cualquier confusión entre juegos ganados en la serie y bajas del mapa.

2. **Pestañas y navegación entre partidas**:
   - Se ofrecen 3 pestañas: `Resumen`, `Partidas` y `Jugadores`.
   - En la parte superior de la vista de detalle se incluye una botonera de píldoras (`Partida 1 ✓`, `Partida 2 ✓`, `Partida 3 •`).
   - Por defecto, la pantalla selecciona automáticamente la partida activa (`EN VIVO`), o la última partida finalizada si la serie terminó, o la partida 1 si está por comenzar.
   - Si el usuario selecciona manualmente una partida finalizada anterior (ej. Partida 1) y llega una actualización en tiempo real o refresco del feed, la selección se mantiene intacta para no interrumpir la inspección.

3. **Formatos de serie**:
   - Formatos soportados: `Bo1`, `Bo3`, `Bo5` (visualizados como `Al mejor de 1`, `Al mejor de 3`, `Al mejor de 5`).
   - Si el formato no se reporta en la API/proveedor, no se asume Bo3 ni Bo5; la barra superior y tarjetas muestran únicamente la liga/torneo sin sufijos ficticios.

4. **Objetivos y recursos condicionales**:
   - La tarjeta de recursos de partida (`ORO TOTAL`, `TORRES`, `DRAGONES`, `BARONES`) se oculta automáticamente si ningún equipo reporta métricas.
   - Cada objetivo se renderiza únicamente si está presente en los datos.

5. **Alineaciones y jugadores**:
   - La pestaña `Jugadores` agrupa el quinteto por equipo (Local y Visitante).
   - Para cada jugador se muestra su rol, campeón, KDA formateado (`K / D / A`) y ratio KDA (`(K + A) / D`).
   - Si no hay reporte de jugadores para la partida seleccionada, se muestra un estado informativo claro sin errores.

6. **Resolución de participantes y sincronización**:
   - `homeParticipantId` y `awayParticipantId` garantizan la correspondencia correcta de los equipos local y visitante sin depender del orden en que los participantes fueron recibidos.
   - Si los identificadores no corresponden con los participantes del evento, las secciones detalladas se desactivan de forma segura.
   - La suscripción a tiempo real en `RealtimeService` abarca las tablas `EsportsStats` y `esports_stats`.
   - Los datos de ejemplo o mocks (`lol-1`, `mock_`) muestran un pie explícito de `Datos de ejemplo`.

## Auditoría de Proveedores, Límites y Cobertura (Tarea 19)

### 1. Estado de Proveedores e Ingesta
- **Servicio Backend**: \`EsportsScraperService\` consulta actualmente \`vlr.gg\` para obtener datos de Valorant.
- **Fuentes de LoL investigadas**:
  * *LoL Esports API* (\`esports-api.lolesports.com\`): responde HTTP 403 Forbidden sin token/llave rotativa interna de AWS API Gateway.
  * *Cargo / Leaguepedia* (\`lol.fandom.com\`): responde con error de rate-limiting inmediato (\`ratelimited\`) en peticiones automatizadas sin credenciales registradas de bot.
  * *Riot Games Developer API* (\`developer.riotgames.com\`): llaves efímeras de 24h limitadas a partidas de cliente individual (PUUID), sin soporte de torneos pro estructurados.
  * *Proveedores B2B* (PandaScore, Strafe, Abios): exigen contrato comercial de pago.
- **Conclusión de cobertura**: No existe un proveedor viable, gratuito y desatendido sin cuotas para League of Legends en este momento.

### 2. Criterios de Integridad y Ausencia de Datos
1. **Cero Datos Ficticios**:
   - Nunca se inventan eventos, mapas ni estadísticas simuladas.
   - En ausencia de proveedor o detalle, la interfaz móvil presenta un estado explícito y transparente sin invenciones.
2. **Soporte de Información Parcial**:
   - Si la serie cuenta con datos generales en \`EsportsStats\` (\`format\`, \`map\`, \`score\`), se renderiza una tarjeta con la información disponible.
   - Si la serie no cuenta con desglose por partida, se muestra un estado informativo claro: *"Sin proveedor de estadísticas en tiempo real ni desglose de partidas activo para esta competición"*.
   - Los marcadores ausentes o no disputados en partidos en vivo/finalizados nunca se fuerzan a \`0 — 0\`; se muestran como \`— — —\` o el valor textual recibido.
3. **Resolución de Disciplina**:
   - En eventos persistidos bajo la categoría global \`esports\` de Supabase, la app resuelve \`SportType.lol\` cuando la competición (\`League.slug\`, \`League.name\`, ej. \`lol\`, \`lck\`, \`lec\`, \`lpl\`, \`lcs\`, \`worlds\`) o el identificador externo corresponden a League of Legends.

## Verificación local (Cierre mobile #5 y Tarea 19)

- `flutter analyze lib test`: sin advertencias ni errores.
- `flutter test`: suite completa con pruebas para el contrato de LoL, parseo de partidas, separación de marcador serie vs kills, navegación entre pestañas, persistencia de selección, formato ausente, adaptación responsiva (320px y accesibilidad x2), eventos en tiempo real, manejo de información parcial y ausencia de detalle.
- Fidelidad visual verificada frente al prototipo de referencia `01a10501-9872-7090-87ed-5ca135e89f6e/exec-64d7bfa5-fc06-4d75-95e3-ec305fe769a3.png`.
