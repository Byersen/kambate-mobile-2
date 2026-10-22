# Cartelera y combates UFC: contrato del cliente v1

Estado: implementado y probado en el cliente para la tarea kambate-mobile#7.
Define la estructura esperada en `UfcStats.extraStats.card` (y `extra_stats.card`)
o en el modelo de evento UFC, sin exigir migraciones forzadas en el backend ni
romper compatibilidad con combates individuales existentes. Se preserva en caché
local y reacciona a eventos en tiempo real.

## 1. Estructura del bloque `card` (Cartelera)

La entidad de cartelera agrupa los combates de una velada de UFC (ej. UFC 308, UFC Fight Night).

| Campo | Tipo y significado |
| --- | --- |
| `version` | Entero `1`; versiones desconocidas o ausentes se ignoran |
| `cardId` | Identificador único de la cartelera en el proveedor o base de datos |
| `name` | Nombre del evento o velada (ej. `UFC 308: Topuria vs. Holloway`, `UFC Fight Night: Santiago`) |
| `subtitle` | Subtítulo descriptivo o zona horaria (ej. `Cartelera principal • Hora de Chile`, `Abu Dhabi • Hora local`) |
| `venue` | Recinto o sede del evento (ej. `Etihad Arena, Abu Dhabi`, `Movistar Arena, Santiago`) |
| `city`, `country` | Ciudad y país sede del evento |
| `date` | Fecha y hora oficial de la velada en formato ISO 8601 (ej. `2024-10-26T14:00Z`) |
| `status` | Estado general de la velada (`scheduled`, `live`, `finished`) |
| `fights` | Lista ordenada de combates individuales (`UfcFightModel`) |

## 2. Estructura de cada combate (`fights`)

Cada combate representa un enfrentamiento individual dentro de la cartelera.

| Campo | Tipo y significado |
| --- | --- |
| `id` | Identificador único del combate (UUID o slug) |
| `order` | Entero positivo con el orden del combate en la cartelera (preserva la secuencia oficial) |
| `segment` | Segmento de la cartelera: `main` (Cartelera principal), `prelims` (Preliminares) o `early_prelims` (Primeras preliminares) |
| `isMainEvent` | Booleano; `true` para el combate estelar de la velada |
| `isCoMainEvent` | Booleano; `true` para el combate co-estelar |
| `weightClass` | Categoría de peso (ej. `Peso pluma`, `Peso ligero`, `Peso wélter`, `Peso mosca`, `Peso semipesado`, `Peso medio`) |
| `titleFight` | Booleano; `true` si es una pelea de campeonato mundial |
| `roundsScheduled` | Entero; asaltos programados (generalmente `5` para campeonato/estelar y `3` para combates estándar) |
| `status` | Estado del combate (`scheduled`, `live`, `finished`, `canceled`) |
| `currentRound` | Asalto en disputa si está en vivo o asalto final si terminó |
| `clock` | Tiempo en el asalto (ej. `03:12` o tiempo de finalización) |
| `scheduledTime` | Hora individual confirmada; si no existe, la interfaz muestra estrictamente `A continuación` |
| `fighter1`, `fighter2` | Datos de los contendientes (`UfcFighterModel`) |
| `result` | Objeto opcional con el resultado oficial confirmado (`UfcFightResultModel`) |
| `taleOfTheTape` | Objeto opcional con la ficha comparativa física (`UfcTaleOfTheTapeModel`) |
| `stats` | Objeto opcional con estadísticas de golpeo, derribos y asaltos (`UfcFightStatsModel`) |

## 3. Estructura de contendientes (`UfcFighterModel`)

| Campo | Tipo y significado |
| --- | --- |
| `id` | Identificador único del peleador |
| `name` | Nombre completo (ej. `Ilia Topuria`, `Max Holloway`) |
| `nickname` | Apodo de combate (ej. `El Matador`, `Blessed`) |
| `photoUrl` | URL de la imagen del peleador o avatar oficial |
| `record` | Récord MMA oficial (ej. `15-0-0`, `26-7-0`) |
| `country` | País de representación |
| `ranking` | Puesto en el ranking de la división (ej. `Campeón`, `#1`, `#2`) |
| `corner` | Esquina asignada (`red`, `blue`) |

## 4. Estructura de resultado oficial (`UfcFightResultModel`)

No se inventan resultados ni métodos si el combate está en vivo o programado.

| Campo | Tipo y significado |
| --- | --- |
| `winnerId` | ID del peleador ganador (nulo en empate o sin decisión) |
| `winnerName` | Nombre del peleador ganador |
| `method` | Método de victoria (ej. `KO / TKO`, `Sumisión`, `Decisión unánime`, `Decisión dividida`, `Decisión mayoritaria`, `Empate`, `Sin decisión`) |
| `methodDetail` | Detalle específico de la finalización (ej. `High Kick`, `Golpes`, `Mataleón`, `Guillotina`) |
| `round` | Asalto en que concluyó la pelea (`1`, `2`, `3`, `4`, `5`) |
| `time` | Minuto y segundo exacto de la finalización (ej. `01:48`, `04:32`) |

Texto resumido en cartelera:
- Si finalizado y con ganador: `✔ Ganó [Ganador] • [Método] • A[Round] • [Tiempo]` (o `Decisión unánime` si se fue a las tarjetas sin tiempo específico).

## 5. Estructura de ficha física (`UfcTaleOfTheTapeModel`)

Solo se renderizan los atributos efectivamente provistos. Si un dato no existe, no se inventa:

| Campo | Tipo y significado |
| --- | --- |
| `division` | Nombre de la división o peso acordado |
| `record1`, `record2` | Récord MMA de cada peleador |
| `height1`, `height2` | Estatura (ej. `1.70 m (5'7")`, `1.80 m (5'11")`) |
| `reach1`, `reach2` | Alcance de brazos (ej. `175 cm (69")`, `180 cm (71")`) |
| `stance1`, `stance2` | Guardia (ej. `Ortodoxa`, `Zurda`, `Switch`) |
| `age1`, `age2` | Edad de cada contendiente |

## 6. Estructura de estadísticas (`UfcFightStatsModel`)

| Campo | Tipo y significado |
| --- | --- |
| `homeSigStrikes`, `awaySigStrikes` | Golpes significativos conectados / intentados |
| `homeSigStrikePct`, `awaySigStrikePct` | Porcentaje de efectividad de golpeo |
| `homeTakedowns`, `awayTakedowns` | Derribos completados / intentados |
| `homeTakedownPct`, `awayTakedownPct` | Porcentaje de derribos completados |
| `homeSubAttempts`, `awaySubAttempts` | Intentos de sumisión |
| `homeControlTime`, `awayControlTime` | Tiempo de control en el suelo o clinch (ej. `03:24 min`) |
| `rounds` | Lista opcional de métricas por asalto individual (`UfcRoundStatsModel`) |

Si las estadísticas no están disponibles para un combate, la pestaña informa limpiamente que no hay métricas oficiales reportadas, sin valores simulados ficticios.

## 7. Criterios de navegación e interfaz

1. **Filtros de Cartelera**:
   - Selector segmentado: `Todas`, `Principal`, `Preliminares`.
   - `Todas` presenta la cartelera principal seguida de las preliminares.
   - `Principal` aísla los combates de la tarjeta principal.
   - `Preliminares` aísla combates preliminares y primeras preliminares.

2. **Acceso al combate en vivo**:
   - Si la velada cuenta con una pelea activa (`live`), se destaca el banner superior: `((•)) Ir al combate en vivo >`.
   - Pulsar el banner abre directamente el detalle del combate en disputa.

3. **Combate estelar**:
   - Se destaca con la insignia `COMBATE ESTELAR` y la categoría de peso.

4. **Hora confirmada vs A continuación**:
   - Si no existe horario individual confirmado, se indica explícitamente `A continuación`.
   - Se preserva el orden estricto de la velada.

5. **Navegación y retorno ("conservar retorno")**:
   - Cada tarjeta de combate es interactiva y abre la vista completa del detalle de combate.
   - El botón de retroceso (`AppBar` y navegación nativa) regresa a la cartelera manteniendo el filtro seleccionado y la posición del usuario.

## 8. Estrategia de agrupación y persistencia

1. **Persistencia granular en backend**:
   - Cada combate se almacena como una entidad `Event` individual en PostgreSQL/Supabase con identificador externo determinista `ufc-{eventId}-{competitionId}`.
   - Esto preserva integridad relacional, compatibilidad con tablas de participantes, marcadores y suscripciones en tiempo real.
   - En la tabla satélite `UfcStats`, el campo `extraStats` alberga el bloque `card` (`UfcCardPayload`) con la velada completa consolidada.

2. **Agrupación en el cliente (`mobile`)**:
   - Cuando un evento cuenta con `ufcStats.extraStats.card`, se parsea directamente con `UfcCardModel.parse`.
   - Cuando se cargan combates individuales desde la base de datos sin `extraStats.card`, el cliente los agrupa mediante `UfcCardModel.fromEvent(event, allEvents: ...)` o `UfcCardModel.fromEvents(...)`, detectando el prefijo común en `externalId` (`ufc-{cardId}-`) o la combinación de liga y fecha de velada.
   - En ausencia de eventos hermanos, se construye de forma segura la cartelera monoevento preservando sus datos reales.

## 9. Regla estricta de estados parciales (Anti-hallucination)

- Récords MMA (`records`), apodos de combate (`nickname`), clasificaciones oficiales (`curatedRank`) y ficha física (`taleOfTheTape`) solo se pueblan si la fuente oficial (ESPN) los entrega explícitamente.
- Ante ausencia de métricas físicas o récord, el sistema mantiene los campos como `null` y la interfaz presenta indicadores limpios de ausencia de datos, sin generar valores inventados ni simulaciones ficticias.

