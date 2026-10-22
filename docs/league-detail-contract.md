# Detalle de Ligas: Contrato y Cobertura Real v1

Estado: Implementado y probado en cliente (`kambate-mobile`) y backend (`kambate-backend`) en la rama `feature/kambate-detalle-ligas-real`.

Reemplaza por completo los datos de demostración fijos ("Equipo A", "Jugador 1", disclaimers de maqueta) de `lib/features/league_detail/presentation/screens/league_detail_screen.dart` por clasificaciones y goleadores reales obtenidos del proveedor autorizado (ESPN), asociando IDs reales de liga, temporada y equipos.

---

## 1. Investigación del Proveedor

### 1.1. Endpoints de ESPN

* **Tabla de Posiciones / Standings:**
  * Fútbol: `https://site.api.espn.com/apis/v2/sports/soccer/{leagueSlug}/standings`
  * NBA: `https://site.api.espn.com/apis/v2/sports/basketball/nba/standings`
  * Parámetro opcional: `?season={seasonYear}`
  * Headers: Soporta `Access-Control-Allow-Origin: *` directamente.

* **Estadísticas y Líderes / Goleadores:**
  * Fútbol: `https://site.api.espn.com/apis/site/v2/sports/soccer/{leagueSlug}/statistics`
  * NBA: `https://site.api.espn.com/apis/site/v2/sports/basketball/nba/statistics`
  * Categorías: `goalsLeaders` (goleadores), `assistsLeaders` (asistencias), `pointsLeaders`.

### 1.2. Hallazgos de Cobertura por Disciplina y Competición

1. **Ligas con tabla regular única (1 grupo):**
   * Ejemplos: `esp.1` (LaLiga), `eng.1` (Premier League), `ger.1` (Bundesliga), `ita.1` (Serie A), `fra.1` (Ligue 1), `ned.1` (Eredivisie), `por.1`, `tur.1`, `bra.1`, `chi.1`, `mex.1`, `usa.1`.
   * Cobertura: Completa. Entrega posiciones, puntos, partidos jugados (PJ), ganados, empatados, perdidos, goles a favor, goles en contra, diferencia de gol (DIF) y notas de clasificación continental o descenso.
   * Goleadores: Top 50 goleadores con atleta, equipo, goles, partidos y asistencias.

2. **Ligas / Torneos con múltiples grupos o conferencias:**
   * `nba`: 2 grupos (Eastern Conference y Western Conference) de 15 equipos cada uno.
   * `arg.1` (Liga Profesional Argentina): 2 zonas (Group A y Group B).
   * `conmebol.libertadores` / `uefa.champions` (fase de grupos): 8 grupos (Group A – Group H).
   * Cobertura: Soportada mediante la lista `groups` dentro del contrato.

3. **Competiciones y Disciplinas sin tabla de posiciones o goleadores:**
   * Torneos a partido único o eliminatoria directa (ej. `uefa.super_cup`): `children: []`.
   * UFC (`ufc`): no tiene tabla de liga ni goleadores (clasificación por divisiones de peso, no formato de liga).
   * Esports (`lol`, `valorant`): sin tablas de liga en ESPN (`400 Bad Request`).
   * **Política de negocio:** Se activa `hasStandingsCoverage: false` y/o `hasLeadersCoverage: false`. La aplicación presenta un estado claro y amigable de "Posiciones no disponibles" y "Goleadores no disponibles", sin inventar datos ni mostrar filas ficticias.

---

## 2. Definición del Contrato v1

```json
{
  "version": 1,
  "leagueId": "4e0f7103-58a0-442d-b8db-75bc53ff3f7e",
  "leagueSlug": "esp.1",
  "leagueName": "Spanish LALIGA",
  "seasonId": "f81d08a8-4a6b-40cc-86f2-fd4c33903eac",
  "seasonSlug": "2024-2025",
  "seasonName": "Temporada 2024-2025",
  "hasStandingsCoverage": true,
  "hasLeadersCoverage": true,
  "groups": [
    {
      "name": "General",
      "entries": [
        {
          "position": 1,
          "teamId": "83",
          "participantId": "uuid-barcelona",
          "teamName": "Barcelona",
          "teamLogo": "https://a.espncdn.com/i/teamlogos/soccer/500/83.png",
          "playedGames": 9,
          "points": 27,
          "won": 9,
          "drawn": 0,
          "lost": 0,
          "goalsFor": 39,
          "goalsAgainst": 9,
          "goalDifference": 30,
          "note": "Champions League",
          "isPromotion": true
        }
      ]
    }
  ],
  "topScorers": [
    {
      "rank": 1,
      "athleteId": "231050",
      "playerName": "Raphinha",
      "playerPhoto": "https://a.espncdn.com/i/headshots/soccer/players/full/231050.png",
      "teamId": "83",
      "teamName": "Barcelona",
      "teamLogo": "https://a.espncdn.com/i/teamlogos/soccer/500/83.png",
      "participantId": "uuid-barcelona",
      "goals": 12,
      "playedGames": 8,
      "assists": 3
    }
  ]
}
```

### Especificación de Campos

| Campo | Tipo | Descripción |
|---|---|---|
| `version` | `int` | Entero 1 según versión del contrato. |
| `leagueId` | `String?` | UUID de `League` en la base de datos Supabase / PostgreSQL. |
| `leagueSlug` | `String` | Slug unívoco de la competición (ej. `esp.1`, `eng.1`, `nba`). |
| `leagueName` | `String` | Nombre canónico de la competición. |
| `seasonId` | `String?` | UUID de `Season` activa en la base de datos. |
| `seasonSlug` | `String?` | Slug de la temporada (ej. `2024-2025`). |
| `hasStandingsCoverage` | `bool` | `true` si el proveedor entrega tabla de posiciones con al menos 1 grupo válido. |
| `hasLeadersCoverage` | `bool` | `true` si el proveedor entrega estadísticas individuales de goleadores. |
| `groups` | `List<LeagueStandingGroupModel>` | Lista de zonas o tabla general de posiciones. |
| `topScorers` | `List<LeagueScorerModel>` | Lista ordenada de los máximos anotadores reales. |

---

## 3. Integración en Backend (`kambate-backend`)

* Endpoint: `GET /scrapers/leagues/:slug/standings`
* Métodos del scraper: `fetchLeagueStandings(slug)` y `fetchLeagueStatistics(slug)` en `FootballScraperService`.
* Servicio: `getLeagueDetail(slug)` en `ScrapersService`, resuelve los UUIDs de `League`, `Season` y `Participant` (`football-team-${id}` / `nba-team-${id}`) desde la base de datos PostgreSQL, normaliza las tablas y líder de goleo, y entrega el contrato oficial.

---

## 4. Integración en Cliente (`kambate-mobile`)

* Modelo: `lib/models/league_detail_model.dart`
* Repositorio: `lib/features/league_detail/data/league_detail_repository.dart`
  * Consume el backend oficial (`$apiUrl/scrapers/leagues/$slug/standings`).
  * Cuenta con fallback directo a los endpoints de ESPN con `Access-Control-Allow-Origin: *` para funcionamiento autónomo local / web.
* Proveedor Riverpod: `leagueDetailProvider` en `lib/features/league_detail/providers/league_detail_provider.dart`.
* Pantalla: `LeagueDetailScreen`:
  * **Pestaña Partidos:** Conserva el filtro correcto por liga (ID, slug y coincidencia de nombre) y por temporada (`seasonId` / `seasonSlug`).
  * **Pestaña Tabla:** Muestra posiciones reales con `#`, escudo, nombre, PJ, DIF y PTS, además de notas de clasificación y colores de ascenso. Si no hay cobertura, muestra el estado "Posiciones no disponibles" sin filas ficticias.
  * **Pestaña Estadísticas:** Muestra ranking de goleadores reales con foto del jugador, nombre, equipo, escudo, PJ y cantidad de goles anotados. Si no hay cobertura, muestra "Goleadores no disponibles" sin filas ficticias.

---

## 5. Verificación y Pruebas

* `kambate-backend`:
  * 5 suites de pruebas aprobadas (`jest`): 41 tests totales aprobados, incluyendo `src/scrapers/league-detail.spec.ts`.
  * TypeScript compilado sin errores.
* `kambate-mobile`:
  * 175 pruebas aprobadas (`flutter test`), incluyendo 7 pruebas unitarias y de widgets dedicadas en `test/league_detail_test.dart`.
  * `flutter analyze` completado con 0 errores y 0 warnings.
