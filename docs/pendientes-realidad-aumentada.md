# Realidad aumentada: lo que falta para terminarla

Estado al 22 de noviembre de 2026: **lista para la prueba en el campus del
lunes 23**, con la guía en **modo campo**: lo que salga mal se corrige allí
mismo desde el teléfono. El alcance y los criterios de aceptación están en
[el plan de realidad aumentada](plan-realidad-aumentada.md).

Este documento tiene estas partes:

0. [La prueba del lunes con el modo campo](#0-la-prueba-del-lunes-con-el-modo-campo):
   qué instalar, qué probar y cómo corregir en el momento.
1. [El plan de campo](#1-el-plan-de-campo-ir-a-la-u-con-la-app-de-levantamiento):
   cómo se midió el campus con la app secundaria `apps/levantamiento` (ya
   hecho; el lunes no hace falta).
2. [Las pruebas en teléfonos reales](#2-pruebas-en-teléfonos-reales) de la app
   del tour.
3. [Lo que falta en el código](#3-lo-que-falta-en-el-código).

Al final, [cuándo está terminada](#4-cuándo-está-terminada).

## Avance guardado

- Navegación a pie desde «Cómo llegar», con cálculo de rutas (A* sobre el
  grafo), seguimiento, recálculo y guía por voz.
- Vista del plano y flecha sobre la cámara, usando GPS y brújula.
- Permisos de ubicación y cámara, traducciones y pruebas de navegación.
- Grafo peatonal sacado de OSM y corregido con el levantamiento del 20 y 21
  de noviembre: 198 nodos, 211 tramos, **27 entradas verificadas** a mano
  sobre la foto satelital, escaleras y rampas marcadas en el campus. Detalle y
  lo que falta: [levantamiento/campo-2026-11.md](levantamiento/campo-2026-11.md).
- App de levantamiento separada (`apps/levantamiento`) para el trabajo de
  campo, con la misma lógica de navegación que la app.
- **23 de noviembre: validación con MAPSUTB**
  ([integracion-mapsutb.md](integracion-mapsutb.md)). Cambios:
  - grafo reparado: 7 cruces sin nodo y 3 puntas sueltas de OSM; 204 nodos,
    227 tramos; 8.978 rutas de prueba más cortas y ninguna más larga;
  - flecha estable: brújula con giroscopio, la brújula manda (RF-29) y la
    flecha mira 15 m adelante sobre la ruta;
  - filtro de lecturas del GPS y aviso sin señal;
  - ruta sin GPS con sus pasos;
  - «Cómo llegar» en los 26 lugares;
  - buscador de salones con el catálogo de MAPSUTB.

---

## 0. La prueba del lunes con el modo campo

### Qué es

La app del tour de siempre, con una barra naranja abajo en la guía y un
botón: **Corregir**. Se usa la app normalmente; si una indicación sale mal,
se toca **Corregir** y se dice qué está mal. El cambio se aplica al momento,
la ruta se recalcula y abajo sale un aviso con **Deshacer**. No hay nada que
medir aparte ni formularios: la app de levantamiento ya no hace falta.

En modo campo, **Cómo llegar** aparece en los 26 lugares, no solo en las
paradas. El visitante nunca ve nada de esto: la UTB APP no activa el modo.

### Instalar

```sh
python scripts/preparar_apk_demo.py --campo
```

El APK queda en `apps/mobile/build/app/outputs/flutter-apk/app-release.apk`.
En cada teléfono: ubicación en alta precisión y, en la guía,
**Corregir → Más → Quién corrige** (el nombre va en cada corrección).

### Ensayar antes, desde la casa

**Corregir → Más → Ensayo lejos del campus.** La posición camina sola por la
ruta desde la portería; la brújula y la cámara son las reales. Sirve para
practicar las correcciones sin ir a la U: se aplican igual, pero **no se
guardan ni se envían**, y al apagar el ensayo desaparecen. Se apaga solo al
cerrar la app, y mientras está activo la guía lo dice («UBICACIÓN SIMULADA»,
«ENSAYO» en la barra).

### Cuando algo sale mal

| Lo que pasa | Se toca |
|---|---|
| Dice que llegaste y la puerta está más allá, o nunca lo dice | Ir a la puerta real → **Corregir → Estoy en la puerta**. 10 s quieto; mueve allí la entrada más cercana del lugar. Si ya estaba bien, solo lo anota. |
| Manda por un camino cerrado, privado o que no existe | **Por aquí no se pasa**: cierra el tramo por el que manda la guía (se ve en naranja) y busca otro. |
| Da un rodeo y hay un camino más corto | **Hay un camino mejor** → caminarlo hasta llegar a otro camino → **Listo** en la barra. La guía ya lo usa. |
| La flecha de la cámara apunta mal estando quieto | **La flecha apunta mal** → sobre la línea naranja, teléfono vertical, cámara hacia donde sigue el camino → **Listo**. |
| Hay escalones donde la guía no lo sabe (o al revés) | **Aquí hay escaleras** / **Aquí no hay escaleras**, en el tramo por el que manda. |
| Cualquier otra cosa | **Otra cosa: anotarla**: queda con la posición. |

Todo se deshace con el aviso de abajo o desde **Más → Hechas**.

Casos menos comunes, en **Más**:

- **Otra entrada del lugar aquí**: una puerta que la guía no conocía.
- **Llega a N m de la puerta**: radio de llegada (el plan dice 10 m).
- **Detector de metal**: si la brújula marca lejos de 33 µT, la flecha
  desaparece estando quieto. Si pasa con el teléfono calibrado (dibujar un
  ocho) y lejos del metal, pasar a «amplio».

### La barra

Mientras guía: `GPS ±4 m · flecha por brújula · 33 µT · puerta a 42 m · 2
correcciones`. «Flecha por GPS» es caminando; «brújula con interferencia
(55 µT, normal 33)» es metal cerca o brújula sin calibrar. Al llegar, la
barra recuerda qué hacer si no es la puerta.

### Compartir entre teléfonos

**Corregir → Más → Enviar** copia todo; se pega en el grupo. En los otros
teléfonos: copiar el mensaje y **Recibir**. Se unen sin duplicar, y lo
deshecho también se deshace en los demás. La app de levantamiento tiene
**Pegar correcciones de la guía** si se quiere usar su prueba de la guía.

### Después: al grafo oficial

Guardar el texto de **un** teléfono que tenga todo recibido como
`scripts/datos/campo/correcciones-2026-11-23.json` y:

```sh
python -I scripts/grafo_campus.py --informe "scripts/datos/campo/*.json"   # resumen, pruebas y notas
python -I scripts/grafo_campus.py "scripts/datos/campo/*.json"             # grafo nuevo
python -I scripts/aplicar_pines.py scripts/datos/campo/ajustes-entradas.json scripts/datos/campo/correcciones-2026-11-23.json
```

Una entrada corregida en el campus manda sobre el ajuste de la foto
satelital. Los tramos y caminos se aplican por geometría, no por id. El
ajuste de brújula y el detector solo se informan: se pasan a `DECLINACION`
si varios teléfonos coinciden. Después, un APK nuevo para que el grafo
corregido llegue a todos.

### Calibración y pruebas hechas antes de ir

- **Declinación −8,5°** (era −7,7°): WMM2025 de NOAA/NGA en el campus para
  noviembre de 2026.
- **Campo magnético 33 µT**. La brújula se da por interferida si se aparta
  más del 35 %: con eso la flecha ya puede errar unos 25°, y más tolerancia
  dejaría errores de 45°. Antes valía cualquier cosa entre 20 y 75 µT.
- **Grafo**: las cinco paradas tienen ruta normal desde la portería y entre
  ellas, y ruta sin escaleras. Sin escaleras, entre Biblioteca y Puente hay
  un rodeo de 321 m frente a 88 m en línea recta, por las tres «rampas con
  escalones» sin confirmar. Edificio A2, Cafetería y Solo Café no tienen
  ruta sin escaleras. Portería → Cancha de fútbol (×3,3) y Zona T →
  Rectoría (×2,9) sugieren caminos que faltan.
- **Teléfono real** (Xiaomi, Android 16), el 22 de noviembre, en ensayo:
  guía, cámara con la flecha, cerrar un tramo y deshacerlo, grabar un
  camino, llegada y «Estoy en la puerta». Con el GPS real fuera del campus
  dice «Estás fuera del campus». En un escritorio, junto al computador, la
  brújula marcó 55 µT y la app la dio por interferida, que es lo correcto:
  el lunes hay que mirar qué marca a cielo abierto.

La prueba automática que recorre todo eso en un teléfono conectado:

```sh
cd apps/mobile
flutter drive --driver=test_driver/mapa_3d.dart --target=integration_test/guia_campo_test.dart -d <serial>
```

Imprime lo que mide la brújula y deja capturas en `.impeccable/review/`.
Instala una app de comprobación: después hay que reinstalar el APK.

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
- **Ajustes del teléfono:** ubicación en alta precisión; batería cargada y
  una batería externa. La app mantiene la pantalla encendida mientras mide.
  Si se cambia de app o se bloquea el teléfono, cancela la medida de 60 s:
  hay que repetirla completa al volver.
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

1. **Fuera del campus (corregido en PR #30).** A más de 150 m del grafo no
   se inventa una ruta: se ofrece la salida al 360 y se detienen los sensores.
   Confirmar el margen en campo.
2. **Pantalla encendida (corregido en PR #30).** La guía y la app de campo
   usan `wakelock_plus` 1.7.0 (BSD-3-Clause, compatible con Flutter 3.41).
   Liberan la pantalla al salir o pasar al fondo; la guía también al llegar.
3. **Rumbo fiable (corregido en PR #30).** Plano y flecha usan el GPS al
   caminar con buena precisión. Quieto, usan la brújula calibrada. Si falla
   la brújula y no hay rumbo GPS fiable, no se dibuja una dirección inventada.
   Confirmar el comportamiento con metal cerca en campo.
4. **Ciclo de vida (corregido en PR #30).** GPS, brújula y voz se pausan al
   ir al fondo; la guía retoma su ruta al volver. La app de campo cancela una
   medición interrumpida y guarda el recorrido en curso. Sigue pendiente
   comprobar en teléfonos reales la lista de la parte 2. Las aperturas y
   cierres de cámara se serializan, incluso si se sale mientras se inicializa.
5. **Analítica de la guía.** RN-10 permite registrar «llegó a la parada N»
   sin coordenadas, y sirve para la métrica de uso de la realidad aumentada.
   Hoy no se registra nada de la guía.
6. **Declinación y radio.** Declinación −8,5° (WMM2025) y radio de 10 m. En
   modo campo los dos se ajustan en el momento y quedan registrados.
   **(campo)**
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
    exige un APK nuevo. Para el equipo lo cubre el modo campo; para los
    visitantes sigue faltando.

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

La revisión del PR #30 añade regresiones de importación con comodines en
PowerShell, exportaciones acumuladas sin medidas duplicadas, norte recalculado
con la declinación vigente, mínimo de 8 comprobaciones de brújula, precisión
de la puerta, GPS fuera del campus, selección del rumbo y pausa/reanudación.
CI compila los APK de ambas apps y ejecuta también:

```sh
python -I -m unittest discover -s scripts -p test_grafo_campus.py -v
```

Verificación local de la revisión: análisis sin errores, 154 pruebas del tour
aprobadas (8 de integración remota omitidas), 20 de levantamiento y 7 del script.

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
