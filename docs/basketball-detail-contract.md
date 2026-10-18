# Detalle de básquetbol: contrato del cliente v1

Estado: implementado y probado en el cliente para la tarea kambate-mobile#4.
Define la estructura esperada en `NbaStats.extraStats.detail` (y `extra_stats.detail`),
sin exigir migraciones de esquema en la base de datos. Se preserva en caché local
y reacciona a eventos en tiempo real.

## Estructura del bloque `detail`

| Campo | Tipo y significado |
| --- | --- |
| `version` | Entero `1`; versiones desconocidas o ausentes se ignoran |
| `homeParticipantId`, `awayParticipantId` | UUID de Participant en Supabase, distintos entre sí |
| `periods` | Lista de `{period, home, away}`; `home`/`away` son enteros no negativos o `null` |
| `statistics` | Lista de `{key, home, away}`; métricas numéricas o porcentuales |
| `leaders` | Objeto opcional `{points: {home, away}}` con `{name, number, value}` |
| `homePlayers`, `awayPlayers` | Listas opcionales de `{name, number, position, isStarter, points, rebounds, assists, minutes, ...}` |
| `plays` | Lista opcional de jugadas `{id, text, clock, period, homeScore, awayScore, scoringPlay, scoreValue, side}` |

## Criterios del contrato y manejo de datos

1. **Parciales por cuarto y prórrogas**:
   - Cada periodo define su etiqueta `period` (`1`, `2`, `3`, `4`, `OT`, `OT2`, etc.).
   - Un cuarto pendiente o sin registrar se representa con `home: null` y/o `away: null`, mostrándose en pantalla con un guion (`—`).
   - Un cuarto disputado con cero puntos se representa con `0` y se muestra fielmente como `0`.
   - Se eliminan por completo los parciales ficticios calculados restando constantes del total acumulado.
   - El total del partido muestra el marcador global del evento o la suma exacta de los cuartos reportados.

2. **Comparativa de equipos**:
   - Claves reconocidas: `fieldGoalPct`, `threePointPct`, `freeThrowPct`, `rebounds`, `assists`, `turnovers`, `steals`, `blocks`, `pointsInPaint`, `fastBreakPoints`, `secondChancePoints`, `fouls`.
   - Las barras comparativas calculan su proporción dinámicamente (`home / (home + away)`). Si ambos valores son nulos o cero, la barra se muestra neutra sin inventar porcentajes fijos.
   - Si no se reciben estadísticas, se informa con un estado claro de datos no disponibles según la cobertura del proveedor.

3. **Líderes individuales**:
   - Muestra el jugador más destacado de cada equipo con su nombre, dorsal y puntuación (p. ej. `26 PTS`).
   - Ofrece un acceso directo interactivo (`Ver estadísticas de jugadores`) para alternar a la pestaña de `Jugadores`.
   - Si no existen líderes registrados, no se muestran nombres fijos del código ni jugadores ficticios.

4. **Estadísticas de jugadores**:
   - Organizado por equipo (Local y Visitante) distinguiendo `Titulares` y `Suplentes`.
   - Desglosa `PTS`, `REB`, `AST` y `MIN`.
   - Ante ausencia de cobertura de alineaciones, se muestra un mensaje informativo sin desbordamientos.

5. **Jugadas (Play-by-play)**:
   - Cronología de jugadas con reloj, periodo, descripción textual y actualización del marcador.
   - Indicador visual destacado para anotaciones (scoring plays).
   - Filtro por periodo si el partido tiene jugadas en múltiples cuartos.
   - Ante partidos programados o sin jugadas, se despliega un mensaje informativo.

6. **Resolución de participantes y sincronización**:
   - `homeParticipantId` y `awayParticipantId` garantizan la correspondencia correcta de los equipos local y visitante sin depender del orden en que los participantes fueron recibidos.
   - Si los identificadores no corresponden con los participantes del evento, las secciones detalladas se desactivan de forma segura.
   - La suscripción a tiempo real en `RealtimeService` abarca las tablas `NbaStats` y `nba_stats`, solicitando actualización completa del evento al recibir novedades.
   - Los datos de ejemplo o mocks (`nba-1`, `mock_`) muestran un pie explícito de `Datos de ejemplo`.

## Verificación local (Cierre mobile #4)

- `flutter analyze lib test`: sin advertencias ni errores.
- `flutter test`: pruebas exhaustivas cubriendo el contrato de básquetbol, tabla de cuartos, estados vacíos, prórrogas, comparativas, navegación entre pestañas y eventos en tiempo real.
- Fidelidad visual verificada frente al prototipo de referencia `01a10501-9872-7090-87ed-5ca135e89f6e/exec-5b727106-cc21-4430-bc72-3fa7d2952017.png`.
