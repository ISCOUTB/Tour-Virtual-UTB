# Plan de realidad aumentada

La navegación con realidad aumentada en el campus (F-06, RF-26 a RF-34 del SRS v3.1) es el objetivo principal del proyecto. Este plan ordena el camino desde lo que ya existe hasta la flecha sobre la cámara. Lo primero son los datos de campo: sin ellos, ningún código de RA puede funcionar.

## Qué pide el SRS

| Requisito | Qué es | Decisión del SRS |
|---|---|---|
| RF-26 | Elegir un destino del campus | — |
| RF-27 | Calcular la ruta peatonal | A* sobre un grafo propio, no en línea recta (AD-02) |
| RF-28 | Flecha sobre la imagen de la cámara | `CameraPreview` + `CustomPainter`, **sin ARCore ni ARKit** (AD-01) |
| RF-29 | Recalcular la orientación | Rumbo GPS hacia el nodo menos rumbo de la brújula |
| RF-30, RF-31 | Detectar la llegada y avanzar en la ruta | Haversine, consulta del GPS cada 2 s, radio de 10 m (AD-03) |
| RF-32 | Mostrar la ficha al llegar | — |
| RF-33 | Modo degradado sin cámara o sin GPS | Ofrecer el mapa o el 360 (AD-05) |
| RF-34 | Descargar el grafo peatonal | JSON en almacenamiento, en caché (AD-06) |
| RNF-27 | Error de orientación de 10° como máximo | — |
| RN-08 | Un POI sin coordenadas no aparece en la RA | Sí aparece en el mapa y en el 360 |
| RN-10 | No guardar ni transmitir el rastro GPS del usuario | La posición solo vive en memoria |

El SRS también fija que la RA se usa al aire libre, que corre en Android 8 o superior e iOS 13 o superior con cámara trasera y GPS, y que la universidad entrega las coordenadas oficiales (hito H2) y el grafo levantado en campus (hito H1) antes del sprint de RA.

## Qué hay hoy

- **Los lugares ya tienen lat/lng:** los 26, en el modelo, en la API y en el plano ([mapa-osm.md](mapa-osm.md)). Sirven para el mapa, **pero no son las coordenadas de la RA**: son centros de edificio o estimaciones de unos 9 m.
- **OSM tiene una red de senderos del campus:** 1,66 km en un solo componente conexo, con 80 nodos y dos tramos de escalera. Es un buen punto de partida para el grafo. Le falta el puente A3–A5, no distingue rampas de escaleras y no tiene ningún dato de accesibilidad.
- **Las panorámicas no saben dónde está el norte.** Teleport escribe `PoseHeadingDegrees=0` en las cinco. Sin ese dato no se puede alinear una escena 360 con el mundo real.
- **El modo degradado ya existe en parte:** el plano, la lista y el 360 funcionan sin cámara ni GPS.

## Fase 0 — Datos de campo

Esta fase no lleva código y bloquea todo lo demás. Corresponde a los hitos H1 y H2.

**Puntos de llegada.** Para cada parada, y para **cada acceso** cuando hay varios (la biblioteca tiene dos):

1. Pararse donde la persona llega de verdad: la puerta, o el sitio desde donde se tomó la panorámica. No el centro del edificio.
2. Promediar el GPS durante unos 60 s con una app que muestre la precisión, y anotar lat, lng, precisión y hora.
3. Repetir otro día. El punto se acepta si las dos lecturas quedan a menos de 5 m entre sí y con precisión de 5 m o mejor.

**Norte de cada panorámica.** En el punto exacto de cada panorámica, medir con brújula el rumbo de algo que se vea en la escena. Con su yaw ya calibrado sale el yaw del norte de esa escena. Ese dato permite tres cosas: que los hotspots apunten a direcciones reales, mostrar el norte en el visor y alinear el 360 con la RA.

**Grafo peatonal.** Se parte de los senderos de OSM y se recorren a pie para:

- **agregar** lo que falta: el puente A3–A5, los pasillos techados y las entradas;
- **marcar cada tramo** como pasillo, rampa, escalera o exterior, e indicar si tiene escalones y si es techado (bajo techo el GPS empeora);
- **poner nodos** en cada cruce y en cada acceso.

**Devolverlo a OSM (recomendado).** Con la cuenta de OSM de alguien del equipo, y siempre desde lo observado en el campus, se puede:

- corregir A3/A4;
- agregar Enfermería, Centro Deportivo, el puente, las entradas, las rampas y las escaleras.

`scripts/mapa_campus.py` recoge esos cambios en la siguiente ejecución. El PDF institucional no puede ser la fuente de esas ediciones.

## Fase 1 — «Estás aquí» en el plano

Un punto azul con su círculo de precisión y un cono hacia donde mira el teléfono, sobre el plano que ya existe. Todavía sin cámara.

- Mide en el campus, con datos reales, la precisión del GPS y de la brújula antes de construir encima. Es la prueba de si RNF-27 y el radio de 10 m son alcanzables.
- La posición se pide «solo mientras se usa la app» y explicando para qué. Vive en memoria; nunca se guarda ni se envía (RN-10).
- **El escritorio no tiene GPS ni brújula**, igual que ya pasaba con el giroscopio, que en escritorio lanzaba `MissingPluginException` en bucle. Por eso la fuente de posición tiene que ir detrás de una interfaz, con una implementación simulada para Windows y para las pruebas.

## Fase 2 — Navegación sobre el plano

Es la RA sin cámara y, a la vez, el modo degradado de RF-33.

- **Elegir destino (RF-26):** un botón «Cómo llegar» en la ficha.
- **Calcular la ruta (RF-27):** A* sobre el grafo, con la distancia Haversine como heurística. Opción **«sin escaleras»**, que descarta los tramos con escalones.
- **Seguir la ruta (RF-29 a RF-31):**
  - dibujarla sobre el plano;
  - calcular el rumbo al siguiente nodo;
  - consultar el GPS cada 2 s;
  - dar por alcanzado un nodo a 10 m, pero solo si la precisión de la lectura es igual o mejor que el radio, o si dos lecturas seguidas lo confirman. Sin eso, el ruido del GPS da llegadas falsas.
- **Al llegar (RF-32):** se abre la ficha del lugar.
- **Guía por voz y vibración:** «gira a la derecha, 20 metros», con la voz del propio teléfono en el idioma de la interfaz, y el mismo texto en pantalla. No son audios grabados: las frases cambian a cada paso.

## Fase 3 — Flecha sobre la cámara

Corresponde a RF-28, con la decisión AD-01: `CameraPreview` con un `CustomPainter` encima.

- **Cálculo:** la flecha apunta según el rumbo al nodo menos el rumbo de la brújula. Junto a ella, la distancia.
- **Inclinación:** el acelerómetro da la inclinación del teléfono, para dibujar la flecha sobre el suelo.
- **Respaldo:** si se niega la cámara, si no la hay o si la precisión es mala, se vuelve a la vista de la fase 2 sin perder la ruta.
- **Movimiento:** con «Reducir movimiento» la flecha no oscila ni late (`sinMovimiento()`).
- **Seguridad:** un aviso de no caminar mirando la pantalla, y la superposición nunca tapa el camino.

## Más adelante — ARCore y ARKit (DT-01)

Anclar marcadores en 3D de verdad. La API geoespacial de ARCore depende de la cobertura de Street View, y no se ha comprobado si la hay en el campus. Se evalúa cuando las fases 1 a 3 estén probadas.

## Modelo de datos propuesto

Es independiente del backend: sirve igual con la API actual que tras una migración a Firestore.

| Dónde | Campo | Para qué |
|---|---|---|
| `Poi` | `ar_habilitado`, `ar_radio_m` (10 por defecto), `ar_orden` | Los campos `ar_enabled`, `ar_radius_m` y `ar_order` del SRS (tabla 27) |
| `accesos` (tabla nueva) | `poi_id`, `nombre`, `lat`, `lng`, `nodo_id`, `principal` | Un lugar puede tener varias entradas. Sustituye al `graph_node_id` único del SRS |
| `Escena` | `rumbo_norte` (grados) | El yaw del norte geográfico en la panorámica |
| Grafo (JSON con versión) | nodos `{id, lat, lng}`; aristas `{desde, hasta, metros, tipo_camino, escalones, techado}` | Tablas 26 y 49 del SRS, más los dos atributos de accesibilidad |

El grafo se sirve como archivo estático: hoy desde S3 a través de la API; con Firestore, desde Cloud Storage. La app lo guarda en caché (DT-03).

**Licencia del grafo.** Si se deriva de OSM, es una base de datos derivada y va bajo ODbL, igual que el plano.

## Presupuesto de precisión

Son rangos habituales en teléfonos. **La fase 1 tiene que medirlos en el campus**; no se pueden dar por ciertos.

- **GPS:**
  - a cielo abierto, unos pocos metros;
  - junto a edificios y bajo techo empeora mucho, por los rebotes de la señal y el bloqueo.

  Las pasarelas techadas del campus son el peor caso. Por eso los puntos de llegada se miden al aire libre y la llegada exige buena precisión.
- **Brújula:**
  - se descalibra y se desvía cerca de estructuras metálicas;
  - RNF-27 (10° como máximo) es exigente.

  Se mitiga con un filtro de paso bajo, pidiendo calibrarla cuando el sistema avisa de baja precisión y usando el rumbo del GPS cuando la persona camina.

## Accesibilidad

- **Ceguera y baja visión:** la flecha es visual, así que la guía por voz y vibración no es opcional. Todo funciona con TalkBack y VoiceOver, y la ruta sobre el plano es la alternativa accesible.
- **Movilidad reducida:** ruta «sin escaleras». Para eso el grafo tiene que marcar escalones y rampas, que hoy OSM no marca.
- **Audición:** cada indicación de voz aparece también como texto.
- **Cognitiva:** una sola indicación a la vez, en lenguaje simple.

## Privacidad

- **RN-10:** la posición no sale del teléfono ni se guarda. La analítica registra a lo sumo «llegó a la parada N», nunca coordenadas.
- **Ley 1581:** la ubicación de una persona es un dato personal. Aunque no se almacene, el aviso de privacidad tiene que explicar su uso (ver [arquitectura.md](arquitectura.md), sección 7).

## Paquetes candidatos

Hay que verificar versiones y licencias al implementar.

- `geolocator`: posición y precisión.
- `flutter_compass` o `sensors_plus`: rumbo.
- `camera`
- `permission_handler`
- `flutter_tts`: guía por voz.

Ninguno se ha agregado todavía.

## Qué se decide y quién lo hace

- **Equipo, en el campus:** la fase 0, con fecha. Es trabajo de campo y no se puede hacer desde el código.
- **Equipo:** si se contribuye a OSM, con qué cuenta.
- **Backend:** dónde viven el grafo, los accesos y `rumbo_norte`, y si eso espera a la migración a Firestore que pide el SRS.
- **Frontend:** las fases 1 a 3, en ese orden.
