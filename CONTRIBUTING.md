# Flujo de desarrollo de Kambate

## Ramas y publicación

- Trabajar directamente en `develop`, según la decisión del propietario.
- Preparar commits locales pequeños y relacionados con un issue.
- Antes de cada commit, revisar el diff y seleccionar archivos explícitamente; conservar aparte los cambios previos que no pertenezcan a la tarea.
- Comunicar los hashes, el alcance y las verificaciones de los commits preparados.
- No hacer push ni publicar código por herramientas alternativas sin autorización expresa del propietario.
- El propietario decide cuándo integrar `develop` en `main`. No hacer ese merge por iniciativa propia.

## Issues y commits

El seguimiento central está en https://github.com/Byersen/kambate-mobile/issues/9.
Referenciar el issue en el mensaje del commit. Usar un asunto breve en español:
`feat(inicio): incorporar filtros por estado (refs #2)`.
Separar interfaz, integración de datos y correcciones cuando cada cambio sea verificable.
No cerrar un issue solo por tener código escrito: registrar comprobaciones y limitaciones pendientes.

## Datos y diseño

La dirección visual aprobada es B: interfaz clara, acento azul y datos fáciles de comparar.
La aplicación no incluye noticias. Las imágenes propuestas contienen datos ilustrativos.
La información deportiva procede de proveedores y se almacena en Supabase.
No sustituir fallos o datos ausentes por partidos ni estadísticas ficticias.
No incluir archivos .env ni credenciales en los commits.
Confirmar el entorno antes de aplicar migraciones o modificar datos remotos.

## Verificación

En el móvil: análisis de `lib` y `test`, pruebas relevantes y revisión de la interfaz.
En el backend: análisis, compilación y pruebas pertinentes al cambio.
Si una comprobación falla por el entorno, comunicar el motivo; no reportarla como aprobada.
