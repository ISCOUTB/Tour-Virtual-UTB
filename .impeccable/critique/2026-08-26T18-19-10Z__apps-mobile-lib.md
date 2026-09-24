---
target: toda la app movil
total_score: 15
max_score: 40
na_heuristics: 
p0_count: 2
p1_count: 3
timestamp: 2026-08-26T18-19-10Z
slug: apps-mobile-lib
---
**Method: dual-agent** (A: revision de diseno · B: evidencia determinista y de dispositivo real, emulador Android 411x914 dp)

## Design Health Score

| # | Heuristica | Puntaje | Hallazgo clave |
|---|---|---|---|
| 1 | Visibilidad del estado del sistema | 2 | Splash de 4 s sin que nada cargue; el visor 360 no dice que POI es ni cuantas escenas hay |
| 2 | Correspondencia con el mundo real | 2 | Hoja de ruta interna mostrada al usuario; tildes ausentes en la interfaz |
| 3 | Control y libertad | 1 | Flecha atras muerta en las tres pestanas; el mapa se arrastra fuera de pantalla sin recentrado |
| 4 | Consistencia y estandares | 1 | Splash nativo de Flutter antes del propio; PNG 1x escalados hasta 6x; etiqueta duplicada |
| 5 | Prevencion de errores | 2 | Objetivo tactil 25% bajo el minimo; sin estado para lista vacia |
| 6 | Reconocer antes que recordar | 1 | Marcadores sin rotulo; sin lista, conteo ni estado de visitado |
| 7 | Flexibilidad y eficiencia | 0 | Un unico camino rigido: mapa -> pin -> 360 |
| 8 | Estetico y minimalista | 3 | El mapa domina sin ruido; verde neon contra los prados del render |
| 9 | Recuperacion de errores | 3 | FalloApp es lo mejor del codigo; FalloSinContenido deja la pantalla sin salida |
| 10 | Ayuda y documentacion | 0 | Ni un Tooltip; nada ensena que en el 360 hay que arrastrar |
| **Total** | | **15/40 (37,5%)** | **Poor - revision mayor de UX** |

## Veredicto de especificidad

Lo unico especifico del producto en pantalla lo entrego la universidad. El resto es cascaron generico de Flutter. La tipografia de marca aparece una sola vez, 4 s en el splash. Tres azules sin sistema, sin archivo de tokens. El diferenciador -curaduria por audiencia, recorrido oficial- es invisible en la interfaz.

Escaneo determinista NO APLICABLE: detect.mjs devolvio [] con codigo 0 pero no analizo ningun archivo (no soporta .dart). Pasos de navegador no aplicables: Flutter pinta con Impeller sobre SurfaceView, no hay DOM. Sin overlays.

Correccion verificada: las etiquetas de la barra inferior NO estan cortadas. Fue artefacto de captura de escritorio.

## Problemas prioritarios

- **[P0]** El recorrido es inalcanzable por su propio nombre, y la ficha de POI no existe pese a que PoiDetalle/poiDetalleProvider/Medio estan construidos y sin consumir. Arreglo: invertir roles Recorrido/Explorar + bottom sheet de ficha. Comando: shape.
- **[P0]** El marcador -unico control del mapa- mide 36x36 dp medidos (minimo 48) por HitTestBehavior.deferToChild en main.dart:438, y contrasta 1,82:1 sobre blanco (minimo 3:1). Comando: audit.
- **[P1]** WCAG 2.2 AA comprometido e incumplido en cuatro frentes: etiquetas rasterizadas sin escalado de texto, Semantics sin button/selected, cero consultas a disableAnimationsOf, barra de estado a 2,02:1 en la pantalla de carga. Comando: audit.
- **[P1]** Arranque: splash nativo de Flutter + 4 s fijos insalteables sin que nada cargue. Comando: onboard.
- **[P1]** Flecha atras muerta en las tres pestanas (IconButton con callback vacio). Comando: clarify.
- **[P2]** El mapa no responde cuantos, cuales ni cuales vi; 254 dp muertos en Explorar (28% de pantalla). Comando: layout.

## Banderas rojas por persona

- **Marcela (presentadora de admisiones)**: no puede saltar el splash, no puede enunciar los 5 lugares, no puede recentrar el mapa, y sin panoramica no le queda nada que ensenar.
- **Andres (estudiante ubicandose)**: mapa sin busqueda, nombres, norte ni "donde estoy". lat/lng modelados y sin usar. Cuatro puntos anonimos sobre 16 edificios nombrados.
- **Casey (movil distraida)**: cambiar de pestana destruye _MapaCampusState y pierde el zoom. imagenUrlBaja modelado y nunca leido; cached_network_image sin importar.
- **Sam (accesibilidad)**: marcadores no enfocables, nada alcanzable por teclado o conmutador. Flecha blanca del visor sobre panoramica clara desaparece.

## Observaciones menores

Etiqueta duplicada en placeholders. Costura de barra de estado gris contra cabecera navy. Visor 360 sin area segura: etiqueta a 14 dp de la pildora de gestos. Boton Reintentar a 40 dp. ColorScheme.fromSeed declarado y casi no consumido. Sin darkTheme.

## Preguntas para pensar

Por que mapa y 360 comparten modelo de navegacion. Como se veria si el mapa cambiara al declarar quien eres. Donde esta el momento del quinto POI. Puede el producto ser util con cero panoramicas. Que son los otros once edificios.
