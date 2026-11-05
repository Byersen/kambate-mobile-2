# OmniScore

Aplicacion movil nativa desarrollada en Flutter (Dart) para el seguimiento unificado de resultados en tiempo real, calendarios mensuales y estadisticas de 5 disciplinas deportivas: Futbol, NBA, UFC, League of Legends y Valorant. 

Disenada bajo una filosofia Guest-First (sin registro obligatorio) para acceder inmediatamente a toda la informacion deportiva con almacenamiento y personalizacion local persistente, conectandose directamente a traves de Supabase Realtime WebSockets.

---

## Comenzando

Estas instrucciones te permitiran obtener una copia del proyecto en funcionamiento en tu maquina local para propositos de desarrollo y pruebas de UI/UX.

Mira **Despliegue** para conocer como compilar y distribuir la aplicacion en dispositivos fisicos o tiendas de aplicaciones.

---

## Pre-requisitos

Para ejecutar este proyecto necesitas tener instalado en tu entorno local:

1. **Flutter SDK:** Version 3.x o superior.
2. **Dart SDK:** Incluido con Flutter.
3. **Android Studio / Xcode:** Para la emulacion y compilacion nativa en Android e iOS.
4. **Cuenta en Supabase:** (Opcional, unicamente si usas un entorno propio en vez de produccion).

## Instalacion

Sigue esta serie de pasos para configurar y tener tu entorno de desarrollo en funcionamiento:

### 1. Clonar el repositorio
Descarga el codigo fuente en tu maquina local:
```bash
git clone https://github.com/Byersen/kambate-mobile.git
cd kambate-mobile
```

### 2. Obtener dependencias
Descarga e instala los paquetes y modulos de Flutter:
```bash
flutter pub get
```

### 3. Configurar variables de entorno
Crea un archivo `.env` en la raiz del proyecto o usa las constantes para la conexion con Supabase (URL y Anon Key del backend).

### 4. Ejecutar la aplicacion en modo desarrollo
Inicia la aplicacion en tu emulador (iOS/Android) o dispositivo fisico conectado:
```bash
flutter run
```

---

## Experiencia de Usuario y Navegacion Principal

El proyecto esta construido en base a flujos optimizados para el consumo rapido de datos:

* **Onboarding de Bienvenida:** Seleccion rapida de disciplinas favoritas en el primer inicio.
* **Feed de Partidos (En Vivo):** Marcadores en vivo agrupados cronologicamente (hora local) con filtros por deporte y jerarquia de ligas.
* **Favoritos (Siguiendo):** Buscador de equipos/atletas y seguimiento instantaneo persistido en cache local.
* **Calendario Mensual:** Agenda interactiva con desglose diario de partidos globales y de favoritos.
* **Vista de Detalle Polimorfica:** Interfaces y estadisticas exclusivas adaptadas a cada deporte (Linea de tiempo, Box Score, Tale of the Tape, Mapas Bo3/Bo5).

---

## Ejecutando las pruebas

El proyecto cuenta con suites de pruebas de widgets y pruebas unitarias para garantizar el comportamiento esperado de la logica y la interfaz.

Para ejecutar todas las pruebas automatizadas:
```bash
flutter test
```

### Analisis de estilo de codificacion

Verifica el cumplimiento de las buenas practicas y convenciones de Dart estricto:

```bash
flutter analyze
```

---

## Despliegue

La aplicacion esta preparada para compilarse en los entornos moviles nativos (Android/iOS):

1. **Android (APK o App Bundle):**
   ```bash
   flutter build apk --release
   # o para la Google Play Store:
   flutter build appbundle --release
   ```
2. **iOS (Requiere entorno macOS y Xcode):**
   ```bash
   flutter build ios --release
   ```

---

## Construido con

* [Flutter](https://flutter.dev/) - Framework de UI nativa de Google.
* [Dart](https://dart.dev/) - Lenguaje optimizado para UI multiplataforma.
* [Flutter Riverpod](https://riverpod.dev/) - Gestion de estado reactivo y seguro en tiempo de compilacion.
* [Supabase Flutter](https://supabase.com/docs/reference/dart/introduction) - Cliente oficial de DB y WebSockets en tiempo real.
* [GoRouter](https://pub.dev/packages/go_router) - Enrutamiento declarativo para la navegacion interna.
* [SharedPreferences](https://pub.dev/packages/shared_preferences) - Cache-First y persistencia local sin conexion.

---

## Versionado

Usamos [SemVer](http://semver.org/) para el versionado. Para consultar las versiones disponibles, revisa los tags y releases en este repositorio.

---

## Autores

* **Byersen** - *Trabajo Inicial, Arquitectura Movil, UI/UX* - [Byersen](https://github.com/Byersen)

---

## Licencia

Este proyecto esta bajo la Licencia MIT - mira el archivo [LICENSE](LICENSE) para mas detalles.
