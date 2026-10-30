# Integración con la UTB APP

El tour está hecho para abrirse como un módulo más de la app oficial de la UTB y copia su lenguaje visual (ver `PRODUCT.md`). Que la integración llegue a hacerse no depende de este equipo, y tampoco la decisión entre datos locales e infraestructura en la nube. Este documento deja las dos cosas preparadas: describe qué se incrusta, cómo se abre y qué tiene que poner la UTB del otro lado.

## Qué se incrusta

| Carpeta | Qué es |
|---|---|
| `packages/tour_virtual/` | **El módulo.** Un paquete Flutter con todo el tour: pantallas, mapa, visor 360, narraciones, 11 idiomas, ajustes de accesibilidad y su propio acceso a datos. Es lo que la UTB APP agrega como dependencia. |
| `apps/mobile/` | **App de demostración.** Una app mínima que abre el módulo igual que lo haría la UTB APP. Con ella se compila el APK y se corren las pruebas. No contiene código del tour. |

El módulo expone muy poco. Todo lo que hace falta está en `package:tour_virtual/tour_virtual.dart`:

| Símbolo | Para qué |
|---|---|
| `TourVirtual` | El widget que se abre como una pantalla. |
| `ConfiguracionTour` | Lo que la app anfitriona le dice al módulo al abrirlo. |
| `ContenidoRemoto`, `ContenidoLocal` | De dónde salen los datos (ver «Nube o local»). |
| `Audiencia` | `externo`, `estudiante`, `docente` o `admin`. |
| `FuenteMedio` | Constantes para los medios del contenido local. |

## Paso 1: agregar la dependencia

En el `pubspec.yaml` de la UTB APP:

```yaml
dependencies:
  tour_virtual:
    git:
      url: https://github.com/ISCOUTB/Tour-Virtual-UTB
      path: packages/tour_virtual
      ref: master   # mejor un commit o una etiqueta fija; ver «Versiones»
```

Luego `flutter pub get`. Las fuentes, el plano del campus y los textos vienen dentro del paquete. No hay que declarar ningún asset en la app anfitriona.

## Paso 2: abrir el módulo

```dart
import 'package:tour_virtual/tour_virtual.dart';

void abrirTour(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (context) => TourVirtual(
      configuracion: ConfiguracionTour(
        fuente: const ContenidoRemoto(urlApi: 'https://api.tour.utb.edu.co'),
        audiencia: Audiencia.estudiante,
        alSalir: () => Navigator.of(context).pop(),
      ),
    ),
  ));
}
```

Desde un menú, una tarjeta o un enlace profundo, lo que haga la UTB APP para abrir sus otros módulos.

### Opciones de `ConfiguracionTour`

| Campo | Obligatorio | Qué hace |
|---|---|---|
| `fuente` | sí | `ContenidoRemoto(urlApi: ...)` o `ContenidoLocal(medios: ...)`. |
| `lugarId` | no, `1` | La sede. `1` es el Campus Tecnológico de Ternera, la única cargada. |
| `audiencia` | no | Quién usa el módulo, si la UTB APP lo sabe. Elige el recorrido curado para su perfil. Nulo equivale a visitante externo. Ver «Audiencia y seguridad». |
| `alSalir` | no | Qué hacer cuando el usuario sale desde la pantalla principal del módulo, normalmente `Navigator.pop`. Sin él, la flecha de volver solo aparece cuando hay algo que cerrar dentro del módulo. |

La configuración se lee una vez, al abrir el módulo.

## Nube o local

Los dos modos están implementados. Se elige uno al construir `ConfiguracionTour`; el resto del módulo no cambia.

### `ContenidoRemoto`: la API en la nube

El módulo pide lugares, escenas, hotspots y medios a la API de `services/api` por HTTP. Los medios llegan con URL firmadas de Supabase Storage.

- **Ventaja:** el contenido se edita desde el panel de administración (`apps/admin`) sin publicar una versión nueva de la UTB APP.
- **Necesita:** la API desplegada con HTTPS, su base de datos y su almacenamiento. Configuración en `README.md` («Backend»).
- **Sin conexión:** el módulo muestra el error y ofrece reintentar.

### `ContenidoLocal`: todo dentro de la app

El catálogo de lugares, las escenas y los hotspots van en el código del módulo (`lib/datos/repositorio_demo.dart`, copia de `services/api/Data/ContenidoInicial.cs`). No hace falta servidor. El parámetro `medios` dice de dónde salen las panorámicas, narraciones y subtítulos:

| `medios` | Resultado |
|---|---|
| `''` (por defecto) | Sin medios: mapa, fichas y textos, pero sin 360 ni audio. |
| una URL, p. ej. `https://medios.utb.edu.co/tour` | Los medios en una carpeta servida por HTTP, con los mismos nombres de archivo que genera `scripts/preparar_apk_demo.py`. |
| `FuenteMedio.empaquetados` | Los medios dentro de la app, sin red. |

**`FuenteMedio.empaquetados` no funciona con la dependencia git tal cual.** Los medios son material institucional y no se versionan, así que `packages/tour_virtual/assets/demo/` llega vacío. Para empaquetarlos hay que clonar el repositorio, ejecutar `python scripts/preparar_apk_demo.py --solo-copiar` y depender del módulo con `path:` en lugar de `git:`. Suman unos 16 MB.

**Ninguna panorámica puede salir a una app publicada sin pasar antes por el difuminado de caras** (`deface`, revisión manual, sin EXIF). Lo exige la Ley 1581 (ver `docs/arquitectura.md`, sección 7). Las del APK de demostración no están difuminadas.

### Qué cambia al pasar de uno a otro

Solo la línea de `fuente`. Para no recompilar, la UTB APP puede decidirla en tiempo de ejecución, por ejemplo con una bandera remota: es un valor como cualquier otro.

## Lo que el módulo trae consigo

- **Su propio `MaterialApp`.** Tema oscuro, idiomas y navegación (go_router) propios. Se ve igual sin importar el tema de la UTB APP, y sus rutas no se mezclan con las de ella.
- **Su propio estado.** Usa Riverpod en un contenedor aislado. Si la UTB APP también usa Riverpod, los dos no se ven: un `ProviderScope` anidado heredaría el de la anfitriona y el módulo leería su configuración. Lo fija `apps/mobile/test/integracion_test.dart`.
- **Su idioma.** El que el usuario elija dentro del módulo, o el primero del teléfono que el módulo tenga traducido, o inglés. Hoy la UTB APP no puede imponer uno.
- **Sus preferencias y su progreso**, en `shared_preferences` bajo claves `tourVirtual.*`, para no pisar las de la anfitriona.
- **Accesibilidad.** Lectores de pantalla, texto al 200 %, alto contraste, reducir movimiento y subtítulos. Detalles en `docs/ACCESIBILIDAD.md`.

## Lo que tiene que poner la UTB APP

- **Flutter con Dart 3.11 o superior.** Si la UTB APP no es Flutter, se puede incrustar como módulo Flutter nativo (*add-to-app*): `apps/mobile/lib/main.dart` ya es ese punto de entrada.
- **Versiones compatibles de las dependencias compartidas.** El módulo usa `flutter_riverpod` 2.x, `go_router` 17, `just_audio`, `video_player`, `shared_preferences` y `panorama_viewer`. Si la UTB APP fija otra versión mayor de alguno, `pub get` no resuelve y hay que alinearlas. Es el riesgo más probable de la integración.
- **Android:** permiso `INTERNET` (cualquier app con red ya lo tiene) y HTTPS en producción. El módulo no pide ubicación, cámara ni micrófono. El giroscopio del visor 360 no requiere permiso.
- **iOS:** no se ha probado.

## Audiencia y seguridad

Hoy `audiencia` viaja en la cabecera `X-UTB-Audiencia` y la API se la cree (`ContenidoController.AudienciaActual`). Sirve para la demostración, pero cualquiera puede mandar `estudiante` y ver el contenido curado para estudiantes.

En producción la audiencia debe salir de la sesión de la UTB APP, no del cliente:

1. La UTB APP pasa al módulo el token de su sesión. Hace falta un campo nuevo en `ConfiguracionTour`; el módulo lo enviaría en `Authorization`.
2. La API valida ese token contra el proveedor de identidad de la UTB y deduce el perfil, por dominio `@utb.edu.co` y por los datos institucionales.
3. La cabecera `X-UTB-Audiencia` deja de leerse.

Para esto hace falta conocer el mecanismo de sesión de la UTB APP. No está implementado.

## Versiones

`ref: master` sigue siempre lo último. Para que la UTB APP no cambie sin querer, conviene fijar un commit o una etiqueta. Cuando el módulo se entregue se puede marcar con, por ejemplo, `git tag tour_virtual-v1.0.0`. La versión del paquete está en `packages/tour_virtual/pubspec.yaml`.

## Probar la integración sin la UTB APP

`apps/mobile` es una anfitriona mínima:

```bash
cd apps/mobile
flutter pub get
flutter run --dart-define=DATOS=demo                         # contenido local, sin medios
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5209  # la API local, desde el emulador
flutter test                                                 # incluye integracion_test.dart
```

`integracion_test.dart` abre el módulo desde otra app con su propio `ProviderScope` y comprueba dos cosas: que el módulo usa su configuración y no la de la anfitriona, y que `alSalir` devuelve a la anfitriona.

## Pendiente, del lado de la UTB

| Decisión | Afecta a |
|---|---|
| Nube o local | La línea de `fuente`. Si es nube, quién aloja la API, la base y el almacenamiento. |
| Tecnología de la UTB APP | Dependencia Flutter directa o *add-to-app*. |
| Sesión e identidad | El campo de token y la validación en la API (ver «Audiencia y seguridad»). |
| Versiones de dependencias | Alinear Riverpod, go_router y demás si difieren. |
