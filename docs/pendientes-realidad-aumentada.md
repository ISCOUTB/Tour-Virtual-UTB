# Realidad aumentada: lo que falta para terminarla

Estado al 19 de noviembre de 2026: **trabajo en desarrollo; falta terminarlo**.
La rama `frontend/realidad-aumentada-pendiente` conserva el avance para
retomarlo. El alcance y los criterios de aceptación están en
[el plan de realidad aumentada](plan-realidad-aumentada.md).

Este documento tiene tres partes:

1. [El plan de campo](#1-el-plan-de-campo-ir-a-la-u-con-la-app-de-levantamiento):
   ir a la universidad y confirmar los puntos con la app secundaria
   `apps/levantamiento`.
2. [Las pruebas en teléfonos reales](#2-pruebas-en-teléfonos-reales) de la app
   del tour.
3. [Lo que falta en el código](#3-lo-que-falta-en-el-código), encontrado al
   revisar la rama, más allá del trabajo de campo.

Al final, [cuándo está terminada](#4-cuándo-está-terminada).

## Avance guardado

- Navegación a pie desde «Cómo llegar», con cálculo de rutas (A* sobre el
  grafo), seguimiento, recálculo y guía por voz.
- Vista del plano y flecha sobre la cámara, usando GPS y brújula.
- Permisos de ubicación y cámara, traducciones y pruebas de navegación.
- Grafo peatonal inicial sacado de OSM: 194 nodos, 207 tramos, 27 entradas,
  **ninguna verificada**.
- App de levantamiento separada (`apps/levantamiento`) para el trabajo de
  campo, con la misma lógica de navegación que la app.

---

## 1. El plan de campo: ir a la U con la app de levantamiento

Ninguna línea de código puede saber dónde está de verdad cada puerta, qué
camino tiene escalones o cuánto se equivoca la brújula junto a los edificios.
Por eso la fase 0 del plan es ir al campus. Para eso está la app secundaria
`apps/levantamiento`: mide, guarda en el teléfono y exporta un JSON que el
script convierte en el grafo de la app. Cómo instalarla está en su
[README](../apps/levantamiento/README.md).

Lo que hay que confirmar y cómo se sabe que quedó bien:

| Qué | Pestaña | Criterio | Requisito |
|---|---|---|---|
| Las 27 entradas del grafo y las que falten | Entradas | Dos medidas de días distintos, cada una con ±5 m o mejor, a 5 m o menos entre sí | H2, RF-30, AD-03 |
| Tipo de cada tramo, escalones, techo | Tramos | Todos los tramos que usan las rutas a las 5 paradas, marcados | H1, RF-27, ruta «sin escaleras» |
| Caminos que faltan: puente A3–A5, pasillos techados, entradas | Tramos → grabar recorrido | Grabados de punta a punta y agregados en OSM | H1 |
| Norte de las 5 panorámicas | Norte | 2 o 3 objetos por parada, con su yaw en la panorámica | `rumbo_norte` |
| Error de la brújula y declinación | Brújula | Al menos 8 comprobaciones en sitios distintos; p95 ≤ 10° tras corregir el sesgo | RNF-27 |
| Guía hasta cada parada | Guía | La app da la llegada a 10 m o menos de la puerta real y ninguna indicación sale mal | RF-29 a RF-31, AD-03 |

### Antes de ir

- **Teléfonos:** al menos dos Android con GPS y brújula. Con las dos apps
  instaladas: la del tour (`apps/mobile`) y la de levantamiento. En la de
  levantamiento, pestaña **Datos**, escribir **Quién mide**.
- **Ajustes del teléfono:** ubicación en alta precisión; **tiempo de espera
  de la pantalla en 2 min o más** (si la pantalla se apaga durante una medida
  de 60 s, el GPS se corta y la app la rechaza); batería cargada y una batería
  externa.
- **Brújula:** calibrarla al llegar (mover el teléfono en forma de 8) y cada
  vez que la app diga «calibra en 8».
- **Yaw de los objetos:** antes de ir, abrir cada panorámica en el visor 360 y
  anotar el yaw de 2 o 3 objetos fáciles de reconocer (una puerta, una
  columna, una esquina). En el campus se mide su rumbo. Si no se alcanza, el
  yaw se completa después en el JSON.
- **Hora:** de mañana y con cielo despejado: el GPS es mejor y hace menos
  calor para caminar el campus.
- **Carné:** se va a caminar por todo el campus mirando el teléfono y midiendo
  puertas; mejor llevarlo por si seguridad pregunta.

### Día 1 (unas 3 horas)

Repartirse por zonas. Con tres personas, por ejemplo:

1. **Entradas** (una persona): las 27 de la lista, más las que no estén
   («Entrada que no está en la lista»). De pie donde la persona llega de
   verdad, al aire libre, 60 s quieto. Si una entrada está bajo techo, medir
   en el último punto a cielo abierto antes de ella y anotarlo en el nombre.
2. **Tramos y recorridos** (una persona): caminar todos los caminos del grafo
   que llevan a las 5 paradas y marcar cada tramo. Grabar como recorrido lo
   que falta en el mapa, empezando por el **puente A3–A5**.
3. **Norte y brújula** (una persona): las 5 panorámicas y al menos 8
   comprobaciones de la brújula sobre caminos rectos de 20 m o más, lejos de
   carros, rejas y columnas de metal.

Al terminar, cada uno copia su JSON (pestaña **Datos**) y lo manda al grupo.

### Día 2 (otro día, unas 2 horas)

1. **Segunda medida de todas las entradas.** Sin ella ninguna queda aceptada.
   La pestaña **Entradas** dice cuáles faltan y cuáles quedaron a más de 5 m
   (esas se miden una tercera vez).
2. **Prueba de la guía** (pestaña **Guía**) hasta las 5 paradas, desde al
   menos dos sitios distintos cada una (la portería, otra parada, un
   edificio), y una por parada con **ruta sin escaleras**. Al llegar a la
   puerta real, «Estoy en la puerta». Si una indicación no corresponde con el
   camino, «Indicación equivocada» y qué pasa.
3. **La app del tour en el campus:** la lista de la
   [parte 2](#2-pruebas-en-teléfonos-reales), con la flecha sobre la cámara y
   la voz.

### Después de cada día

Desde la raíz del repo, con los JSON del grupo:

```sh
# Qué falta: entradas aceptadas y pendientes, norte, brújula, pruebas
python -I scripts/grafo_campus.py --informe --geojson recorridos.geojson levantamiento-*.json

# Actualizar el grafo de la app con lo medido
python -I scripts/grafo_campus.py levantamiento-*.json
```

- Una entrada **aceptada** entra al grafo con `verificado: true`. Una medida
  que aún no pasa el criterio también se usa (con `verificado: false` y la app
  avisando que la llegada es aproximada): es mejor que el centro del edificio.
- Los tramos marcados cambian el tipo, los escalones y el techo del tramo de
  OSM más cercano. Si el informe dice que uno quedó lejos de cualquier tramo,
  ese camino falta en OSM.
- Si el sesgo de la brújula pasa de 3°, cambiar `DECLINACION` en
  `scripts/grafo_campus.py` por la sugerida y volver a generar el grafo.
- Los recorridos (`recorridos.geojson`) se abren en geojson.io o JOSM para
  agregar a OSM, desde lo observado en el campus, el puente A3–A5 y lo demás
  que falte. Después `scripts/mapa_campus.py` y `scripts/grafo_campus.py` lo
  recogen.
- El `rumbo_norte` de cada escena sale de la tabla del informe; se carga
  cuando el backend tenga el campo (ver la parte 3).
- **Los JSON no se suben al repo** (están en `.gitignore`): tienen recorridos
  de personas. Se sube el grafo que sale de ellos y el informe, si sirve.

---

## 2. Pruebas en teléfonos reales

En la app del tour, con la rama compilada en un APK (`flutter build apk` en
`apps/mobile`). Al menos un teléfono con Android 8, el mínimo del SRS, y un
iPhone si alguien del equipo tiene (iOS 13 o superior).

**Permisos**

- [ ] Conceder la ubicación «solo mientras se usa la app».
- [ ] Negarla una vez: la guía lo explica y ofrece el 360 (RF-33).
- [ ] Negarla para siempre: ofrece abrir los ajustes.
- [ ] Ubicación del teléfono apagada: lo dice y ofrece reintentar.
- [ ] Negar la cámara: la guía sigue en el plano sin perder la ruta.

**Guía**

- [ ] Las 5 paradas desde la portería, en el plano y con la flecha.
- [ ] Ruta sin escaleras hasta una parada que tenga escaleras en la ruta normal.
- [ ] Salirse del camino a propósito: recalcula (y lo dice).
- [ ] Pasar bajo un tramo techado: la señal débil se avisa y no da llegadas
      falsas.
- [ ] La flecha apunta al camino con el teléfono vertical; el aviso «mira el
      camino» no tapa el centro.
- [ ] Brújula junto a metal (una reja, un carro): sale el aviso de calibrar.

**Voz y accesibilidad**

- [ ] Voz en español y en inglés; con un idioma sin voz instalada, sigue con
      el texto en pantalla.
- [ ] Con TalkBack (y VoiceOver en iPhone): las indicaciones se anuncian por
      el lector y no por la voz encima de él; todos los botones tienen nombre.
- [ ] Texto grande (200 %): la indicación y los botones se leen completos.
- [ ] Completar la sección de la guía en [ACCESIBILIDAD.md](ACCESIBILIDAD.md).

**Ciclo de vida y batería**

- [ ] Bloquear la pantalla y volver durante la guía.
- [ ] Cambiar a otra app y volver; recibir una llamada.
- [ ] Perder la señal (entrar a un edificio) y salir.
- [ ] Batería: cuánto baja en 15 minutos de guía con cámara.

---

## 3. Lo que falta en el código

Encontrado al revisar la rama. Lo marcado **(campo)** depende de lo que salga
del levantamiento.

### App del tour (`packages/tour_virtual`)

1. **Fuera del campus.** `GrafoCampus.ruta` engancha la posición al tramo más
   cercano, esté donde esté. Desde la casa de alguien calcula una ruta, sale
   «fuera de ruta» y recalcula sin parar. Falta un estado «estás fuera del
   campus» (por ejemplo, a más de 150 m del grafo) que ofrezca el mapa o el
   360, como pide RF-33.
2. **La pantalla se apaga durante la guía.** No hay nada que la mantenga
   encendida mientras se guía; con el tiempo de espera normal (30 s) se apaga
   a mitad de camino. Falta mantenerla encendida solo en la guía (un paquete
   tipo `wakelock_plus`, verificando versión y licencia).
3. **La flecha usa solo la brújula.** El plan dice que cuando la persona
   camina se use el rumbo del GPS, que no se descalibra con el metal. Hoy el
   plano lo usa solo si no hay brújula, y la flecha sobre la cámara nunca: con
   la brújula descalibrada la flecha apunta mal. **(campo:** la pestaña Brújula
   dice cuánto pasa.**)**
4. **Ciclo de vida de la guía.** La cámara se libera al salir de la app, pero
   el GPS y la voz no se pausan ni se reanudan explícitamente. Revisar con la
   lista de la parte 2 y, si hace falta, pausar al ir al fondo y retomar la
   ruta al volver.
5. **Analítica de la guía.** RN-10 permite registrar «llegó a la parada N»
   sin coordenadas, y sirve para la métrica de uso de la realidad aumentada.
   Hoy no se registra nada de la guía.
6. **Declinación y radio.** La declinación (−7,7°) y el radio de llegada
   (10 m) están fijos; se confirman con el levantamiento. **(campo)**
7. **Tipos de tramo.** `TipoTramo` ya acepta `rampa` y `pasillo`, que marca
   la app de levantamiento. El plano de la ruta no los distingue; opcional:
   dibujar distinto las escaleras y las rampas.

### Backend (`services/api`) y datos

Nada del [modelo de datos del plan](plan-realidad-aumentada.md#modelo-de-datos-propuesto)
existe todavía en la API ni en la base:

8. `Poi`: `ar_habilitado`, `ar_radio_m`, `ar_orden`.
9. Tabla `accesos` (`poi_id`, `nombre`, `lat`, `lng`, `nodo_id`,
   `principal`). Hoy las entradas solo viven en el JSON del grafo.
10. `Escena.rumbo_norte`, y que el visor 360 lo use (hotspots alineados con el
    mundo real y el norte visible). **(campo)**
11. **RF-34:** el grafo va empaquetado en el APK. Falta servirlo con versión
    desde el Storage, a través de la API, y que la app lo guarde en caché y
    use el más nuevo (AD-06, DT-03). Mientras tanto, cada cambio del grafo
    exige un APK nuevo.

### Panel de administración (`apps/admin_flutter`)

12. Activar o desactivar la realidad aumentada por lugar y editar sus
    entradas, cuando el backend tenga los campos de los puntos 8 y 9.

### Documentación y legal

13. **Aviso de privacidad (Ley 1581):** debe explicar para qué se usa la
    ubicación en la guía y que no se guarda ni se envía (RN-10). La sección 7
    de [arquitectura.md](arquitectura.md) habla de las panorámicas, no de la
    ubicación de quien usa la app.
14. [arquitectura.md](arquitectura.md) todavía decía que la realidad
    aumentada era una fase posterior; ya apunta al plan y a este documento.

---

## 4. Cuándo está terminada

- [ ] Las entradas de las 5 paradas (con las dos de la Biblioteca)
      **aceptadas**; las demás, al menos medidas.
- [ ] Los tramos de las rutas a las 5 paradas marcados; el puente A3–A5 en
      OSM y en el grafo.
- [ ] Norte de las 5 panorámicas.
- [ ] Brújula: p95 ≤ 10° (RNF-27) y declinación ajustada.
- [ ] Prueba de la guía que pasa en las 5 paradas, también sin escaleras.
- [ ] La lista de la parte 2 completa en al menos dos teléfonos.
- [ ] Los puntos 1 a 4 de la parte 3 resueltos.
- [ ] Revisión contra las fases 0 a 3 y los criterios del plan.

Los puntos 8 a 13 son trabajo del backend, del panel y del aviso legal; se
coordinan con quien lleve cada parte.

## Comprobación de este avance

Desde `apps/mobile`, pasaron las 43 pruebas de:

```sh
flutter test --no-pub test/navegacion_test.dart test/navegacion_pantalla_test.dart test/textos_test.dart
```

Desde `apps/levantamiento`, la lógica de la app de campo (criterio de las
entradas, brújula, prueba de la guía):

```sh
flutter test
```

Y el script, que sin levantamientos genera el mismo grafo de antes:

```sh
python -I scripts/grafo_campus.py --informe levantamiento-*.json
```

Nada de esto incluye todavía una validación en el campus ni en un dispositivo
físico: para eso es la parte 1.
