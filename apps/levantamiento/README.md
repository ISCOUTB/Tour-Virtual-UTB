# App de levantamiento del campus

App secundaria del equipo, solo para Android, para ir a la universidad y
confirmar en el terreno lo que la realidad aumentada necesita y el código no
puede saber. No es para visitantes y no se publica. Se instala junto a la app
del tour (`co.edu.utb.tour.levantamiento`), así las dos están en el mismo
teléfono el día de campo.

Usa la lógica de navegación del módulo (`packages/tour_virtual/lib/navegacion`):
la prueba de la guía camina con el mismo grafo, la misma ruta A* y el mismo
seguimiento que la app.

El protocolo de la visita, qué medir y con qué criterio está en
[docs/pendientes-realidad-aumentada.md](../../docs/pendientes-realidad-aumentada.md).

## Instalar

```sh
cd apps/levantamiento
flutter pub get
flutter run                 # con el teléfono conectado por USB
flutter build apk           # o el APK para pasarlo a los demás teléfonos
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`.

## Pestañas

| Pestaña | Qué mide | Para qué |
|---|---|---|
| Entradas | GPS promediado 60 s en cada puerta; dice si ya pasa el criterio | `accesos` del grafo con `verificado: true` (H2, RF-30) |
| Tramos | Tipo, escalones y techo del tramo donde estás; graba los caminos que faltan | Ruta «sin escaleras», aviso bajo techo, grafo completo (H1, RF-27) |
| Norte | Rumbo de un objeto visible en cada panorámica | `rumbo_norte` de cada escena |
| Brújula | Error de la brújula contra el rumbo de un camino recto | RNF-27 (10° máx.) y la declinación |
| Guía | Camina a una parada con la lógica de la app; anota llegada, giros y recálculos | AD-03 (radio de 10 m), RF-29 a RF-31 |
| Datos | Resumen, quién mide y el JSON para el equipo | — |

## Pasar los datos al equipo

En **Datos**, «Copiar el JSON». Pégalo en un archivo
`levantamiento-<nombre>-<fecha>.json`. En el computador, desde la raíz del repo:

```sh
# Qué falta y qué pasó (no cambia nada)
python -I scripts/grafo_campus.py --informe --geojson recorridos.geojson levantamiento-*.json

# Actualizar el grafo de la app con lo aceptado
python -I scripts/grafo_campus.py levantamiento-*.json
```

## Pruebas

```sh
flutter test
```

Prueban la lógica (`lib/datos_levantamiento.dart`): el criterio de las
entradas, la brújula y la prueba de la guía. Lo que solo se ve en el campus
(GPS, brújula reales) lo mide la app misma.

## Privacidad

Esta app sí guarda posiciones y recorridos, a diferencia de la app del tour
(RN-10): son de quien mide, que sabe que está midiendo. Quedan en su teléfono
hasta que los copia. No subas los JSON con recorridos a un sitio público; el
repo solo necesita el grafo que sale de ellos.
