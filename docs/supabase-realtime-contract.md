# Contrato y Configuración de Supabase Realtime

Este documento define el contrato de sincronización en tiempo real vía **Supabase Realtime (PostgreSQL CDC / Logical Replication)** entre la base de datos PostgreSQL/Prisma y el cliente `kambate-mobile`.

---

## 1. Tablas Monitoreadas y Publicación PostgreSQL

El esquema de base de datos relacional de Prisma define sus modelos en formato **PascalCase** sin directivas `@@map` (ej. `model Event`, `model FootballStats`). Por consiguiente, las tablas en PostgreSQL son identificadores con distinción de mayúsculas y minúsculas:
* `"Event"`
* `"FootballStats"`
* `"NbaStats"`
* `"EsportsStats"`
* `"UfcStats"`

Las tablas en formato `snake_case` (`event`, `football_stats`, `nba_stats`, `esports_stats`, `ufc_stats`) **no existen** en la base de datos y han sido removidas de las suscripciones de mobile para evitar bindings duplicados y tráfico nulo.

### Resumen del Conjunto Exacto de Tablas:

| Tabla PostgreSQL | Propósito en Realtime | Carga en Mobile |
| :--- | :--- | :--- |
| `"Event"` | Cambios de estado (`status`), marcador global (`score`), fecha de inicio (`startDate`). | Actualización directa en memoria y caché (`requiresRefresh: false`). |
| `"FootballStats"` | Goles (`homeGoals`, `awayGoals`), tarjetas (`homeCards`, `awayCards`), `extraStats`. | Refresco de detalle completo vía `getEventById` (`requiresRefresh: true`). |
| `"NbaStats"` | Puntos (`homePoints`, `awayPoints`), período/cuarto (`quarter`). | Refresco de detalle completo vía `getEventById` (`requiresRefresh: true`). |
| `"EsportsStats"` | Puntuación de mapas (`homeScore`, `awayScore`), mapa actual (`map`). | Refresco de detalle completo vía `getEventById` (`requiresRefresh: true`). |
| `"UfcStats"` | Método de victoria (`method`), round (`round`), tiempo (`time`). | Refresco de detalle completo vía `getEventById` (`requiresRefresh: true`). |

> **Nota:** Tablas estáticas o de metadatos como `Sport`, `League`, `Season`, `Participant`, `UserPreference` **no** forman parte de la suscripción de Realtime para preservar el ancho de banda y la réplica lógica.

---

## 2. Script SQL Idempotente para Publicación (`supabase_realtime`)

Para habilitar estas tablas sin afectar tablas previamente publicadas ni modificar proyectos remotos automáticamente, se proporciona el siguiente script SQL ejecutable en el SQL Editor de Supabase o en migraciones:

```sql
DO $$
DECLARE
    tbl text;
    target_tables text[] := ARRAY['Event', 'FootballStats', 'NbaStats', 'EsportsStats', 'UfcStats'];
BEGIN
    -- 1. Asegurar la existencia de la publicación supabase_realtime
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime'
    ) THEN
        CREATE PUBLICATION supabase_realtime;
        RAISE NOTICE 'Publicación supabase_realtime creada.';
    END IF;

    -- 2. Añadir tablas requeridas preservando las ya existentes
    FOREACH tbl IN ARRAY target_tables LOOP
        IF NOT EXISTS (
            SELECT 1 
            FROM pg_publication_tables 
            WHERE pubname = 'supabase_realtime' 
              AND schemaname = 'public' 
              AND tablename = tbl
        ) THEN
            EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', tbl);
            RAISE NOTICE 'Tabla public."%" añadida a supabase_realtime.', tbl;
        ELSE
            RAISE NOTICE 'Tabla public."%" ya está en supabase_realtime (preservada).', tbl;
        END IF;

        -- 3. Configurar REPLICA IDENTITY FULL para que UPDATE y DELETE incluyan todos los campos
        EXECUTE format('ALTER TABLE public.%I REPLICA IDENTITY FULL', tbl);
        RAISE NOTICE 'REPLICA IDENTITY FULL habilitado para public."%".', tbl;
    END LOOP;
END $$;
```

### Consulta de Verificación:
```sql
SELECT pubname, schemaname, tablename 
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime' 
ORDER BY tablename;
```

---

## 3. Instrucción en Supabase Dashboard

Si se prefiere activar mediante la interfaz gráfica de Supabase:
1. Ir a **Database** > **Publications**.
2. Seleccionar la publicación `supabase_realtime`.
3. Activar el interruptor (Enable Realtime) para las tablas:
   - `Event`
   - `FootballStats`
   - `NbaStats`
   - `EsportsStats`
   - `UfcStats`
4. Mantener activas las demás tablas que ya estuvieran seleccionadas.
5. Guardar la configuración.

---

## 4. Arquitectura en Mobile (`RealtimeService`)

* **Verificación de Estado:**
  - `isSubscribed`: Devuelve `true` únicamente si el canal está activo y en estado `connected`.
  - `verifySubscription()`: Evalúa conectividad real y recupera el canal si detecta desconexión.
* **Prevención de Suscripciones Duplicadas:**
  - Candado `_isSubscribing` para llamadas concurrentes.
  - Limpieza y desvinculación previa mediante `client.removeChannel` antes de reasignar.
  - Cancelación de temporizadores de reconexión activos al suscribirse o desuscribirse.
* **Recuperación tras Desconexión:**
  - Captura de estados terminales: `closed`, `channelError` y `timedOut`.
  - Reconexión con backoff acotado (5s, 10s, 15s... max 30s) sin duplicación de temporizadores.
  - Reset del contador de intentos al reconectar exitosamente (`subscribed`).
