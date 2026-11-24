# MAPSUTB como referencia de «Cómo llegar»

[MAPSUTB](https://github.com/ISCOUTB/AS_202620_mapsutb) es el proyecto de otro
equipo de la UTB: un mapa del campus que traza rutas a pie hasta sus zonas. El
profesor orientador autorizó usarlo en el tour el 23 de noviembre de 2026.

No se copió como un componente aparte. Se usó para dos cosas:

1. **Validar** nuestra guía «Cómo llegar» (grafo, entradas, rutas, GPS) contra
   un trabajo independiente sobre el mismo campus.
2. **Traer lo que ellos tienen y nosotros no**, dentro de las pantallas que ya
   existen: el catálogo de salones y oficinas, el filtro de lecturas del GPS y
   la ruta vista sin GPS.

Revisado en su commit `2654381` (21 de noviembre de 2026).

## Qué se comparó y qué salió

| | MAPSUTB | Tour (antes) | Tour (ahora) |
|---|---|---|---|
| Trazado de caminos | OSM, changeset 189774414 | El mismo OSM | El mismo, con 7 cruces y 3 puntas reparados |
| Grafo | 78 nodos, 90 tramos, 3,33 km | 198 nodos, 211 tramos, 2,92 km | 204 nodos, 227 tramos, 2,95 km |
| Piezas sueltas | 1 vía de 47 m sin conexión | Ninguna | Ninguna |
| Entradas | 10, provisionales (nodo más cercano al edificio) | 27, medidas y revisadas en el campus | Igual |
| Escaleras y rampas | 14 m (solo `highway=steps` de OSM) | 217 m, marcados en el campus | Igual |
| A3 y A4 | Intercambiados (siguen el error de OSM) | Corregidos | Igual |
| Ruteo | Dijkstra desde el nodo más cercano | A* desde el punto más cercano del tramo | Igual |
| Salones y oficinas | 81 espacios y 114 salones por piso | Ninguno | Los suyos, en el buscador |
| Filtro del GPS | Descarta lecturas viejas e imprecisas; avisa sin señal | No | Sí |
| Partida sin GPS | Tocando el mapa | No | Desde la entrada o desde un lugar |
| Flecha sobre la cámara | Descartada (su ADR 0003) | Sí, temblorosa | Estable, con marcador del destino |

### Los caminos son los mismos

OSM no ha cambiado en el campus desde el 30 de septiembre: el trazado lo hizo
Charly, de MAPSUTB, y es el que ya leíamos. Comparando metro a metro:

- Todo nuestro grafo está a menos de 1 m del suyo.
- Lo suyo que no está en el nuestro (453 m) son calles públicas fuera del
  polígono del campus y un tramo de vía suelto. A propósito: una ruta no debe
  salir del campus.
- De 2.701 pares de puntos, las rutas solo difieren en 14, y todas por un mismo
  tramo de vía en el portón.

### Lo que los dos teníamos mal

El trazado de OSM tiene **7 senderos que cruzan una vía sin un nodo
compartido** y **puntas de andén que terminan a 5-8 m del camino al que
llegan**. Donde no hay nodo, la ruta no puede girar: rodeaba hasta 560 m. Ningún
camino del campus está marcado como puente, túnel ni en otro nivel, así que
cada cruce es un paso a nivel.

`scripts/grafo_campus.py` ahora los repara en cada generación
(`reparar_topologia`, con pruebas):

- Parte los dos tramos en cada cruce y los une en un nodo (`tipo: cruce`).
- Une una punta a otro camino a 8 m o menos solo si eso ahorra un rodeo de 20 m
  o más (y de tres veces el hueco) y la unión no atraviesa un edificio. Esas
  uniones llevan `inferido: true`. Quedaron tres, en el portón y en el sur. Las
  dos puntas junto a la Biblioteca y al A2 no se unieron: la unión cruzaría un
  edificio.

Efecto, con una rejilla de 1.600 puntos del campus hacia las 27 entradas: de
25.893 rutas, **8.978 se acortan** (mediana 113 m, máximo 465 m) y **ninguna se
alarga**. Cada unión se revisó sobre la foto satelital de Esri.

### Lo que hacíamos bien

- **Entradas:** las nuestras son puertas medidas; las suyas, el nodo de camino
  más cercano al polígono del edificio, que queda a entre 4 y 48 m de la puerta
  real (A1 48 m, Zona T 41 m, A3 33 m).
- **Escaleras:** sus dos tramos de escaleras están en el nuestro, marcados igual.
  Nosotros tenemos además los 11 que se marcaron en el campus.
- **Partida de la ruta:** ellos arrancan en el nodo más cercano y dibujan una
  línea recta desde el GPS hasta él, que puede cruzar un edificio; nosotros
  entramos al grafo por el punto más cercano del tramo.
- **Posiciones de los lugares:** las suyas son centros de edificio; A3 y A4
  están intercambiados.

### Los lugares, contra tres fuentes

Cada lugar se comparó con tres fuentes independientes: su polígono de OSM, el
rótulo de la maqueta 3D de ElMapita (los `Etq_*` que el tour oculta, ubicados
con `Georreferencia3d`) y la zona de MAPSUTB.

- **Coinciden:** A1, A3, A4, A5, Alcatraz, la Biblioteca, QUID y Rectoría están
  en su edificio o a pocos metros.
- **Canchas:** llevan la entrada en el borde, donde se entra.
- **Edificio A2: estaba mal.**
  - La entrada (y el pin) estaba en el patio junto al Auditorio, 18 m al sur del
    edificio. Las tres fuentes ponen el A2 en el edificio del norte.
  - La había dejado allí un ajuste manual con solo dos medidas de GPS, y quedó
    más al sur que las dos.
  - El equipo confirmó el 23 de noviembre que la puerta está en la fachada sur,
    donde llega el andén del patio: (10.3706609, −75.4656804).
  - Se corrigió en `ajustes-entradas.json`, y de ahí `grafo_campus.py` y
    `aplicar_pines.py` la llevaron al grafo y a todas las copias del pin.
- **Zona T:** OSM y MAPSUTB la ponen sobre la cancha techada (en la maqueta,
  «Cancha de Baloncesto»). El equipo confirmó que la entrada que tenemos, en el
  cruce al norte del edificio de Bienestar, es la correcta.

Al aplicar el pin del A2 apareció otro error: `aplicar_pines.py` reescribía
`actualizar_posiciones.sql` entero. Con un solo lugar movido, se borraban los
otros 25 updates que backend aún no había corrido. Ahora conserva los
anteriores (`combinar_actualizaciones`, con prueba).

## Qué se trajo y dónde quedó

Nada de esto es una pantalla nueva.

### Catálogo de salones, laboratorios y oficinas

`scripts/espacios_mapsutb.py` convierte su `assets/data/zonas.json` (commit
fijado) en `packages/tour_virtual/assets/navegacion/espacios_campus.json`:
10 edificios, 81 espacios, 114 salones, con sus pisos. Se toman los nombres y
los pisos, **no sus coordenadas**: cada edificio apunta al lugar del tour cuya
entrada medida está en el grafo.

- EDA2 no es un lugar del tour: MAPSUTB midió sus espacios dentro del polígono
  de Alcatraz, así que lleva a la entrada de Alcatraz y lo dice («EDA2, junto al
  Edificio Alcatraz»).
- Algunos espacios son lugares del tour con entrada propia (Enfermería, Centro
  Deportivo, La Placita, Salas de estudio, QuantaLab, Rectoría, Solo Café) y
  llevan a ella.
- Contenedores (Semilleros, Inventario, Administración 1 y 2) no tiene ubicación
  en MAPSUTB: queda fuera hasta medirlo.
- Las dos canchas ya son lugares del tour.

**Dónde se usa:**

- **El buscador «¿A dónde vas?»** va en la lista del tour, bajo la tarjeta de la
  siguiente parada. Los resultados salen debajo, en la misma lista. Un lugar
  abre su ficha. Un salón abre «Cómo llegar» hasta su edificio, con la tarjeta
  del salón y su piso (`/navegar/7?espacio=a2-401`). Al llegar, la guía dice
  «Salón 401 está aquí, en: Cuarto Piso».
- El índice (`IndiceBusqueda`) es el suyo, portado, con una mejora: en «a2 401»
  ordena por las palabras que están en el nombre. Así el salón 401 sale antes
  que el grupo «Salones 401-408».

### Filtro de lecturas del GPS (su ADR 0017)

- Se descarta una lectura de hace más de 10 s. Al abrir el GPS, Android puede
  entregar primero la última posición conocida, que puede ser de la casa: con
  ella la guía calculaba la ruta desde allá y se quedaba en «fuera del campus».
- Con una lectura imprecisa (más de 50 m) no se calcula la ruta. Tampoco se
  decide que la persona está fuera del campus, salvo que lo esté aun con el
  peor error (`fueraDelCampusCon`).
- Si en 30 s no llega una lectura útil (15 s una vez guiando), la guía dice que
  no hay señal en vez de «Buscando señal» para siempre. Cuando la señal vuelve,
  la guía sigue sola.
- Fuera del campus ya no es un callejón sin salida: el GPS sigue escuchando y la
  guía empieza sola al llegar.

### Ruta sin GPS (su partida a mano)

«Ver la ruta sin GPS» aparece antes de pedir el permiso, sin permiso, con el GPS
apagado, fuera del campus y sin señal. Muestra la ruta entera sobre el plano,
desde la entrada principal o desde el lugar que se elija en un menú, con:

- el resumen («4 min · 280 m», con o sin escaleras);
- la lista de pasos.

Usa las mismas reglas de giro que la guía.

## La flecha de la cámara

En la prueba en el campus la flecha temblaba. Tenía tres causas:

1. **Brújula sin giroscopio.** El rumbo salía solo del acelerómetro y el
   magnetómetro, con un filtro de 0,3 s: cada paso movía la flecha. Ahora un
   filtro complementario (`FiltroRumbo`) hace dos cosas:
   - gira con el giroscopio, que es inmediato y sin ruido;
   - se acerca a la brújula con una constante de 1,5 s.

   Con ±12° de ruido en la brújula, la flecha se mueve menos de 4°.
2. **Cambio de fuente al caminar.** Al pasar de 0,6 m/s mandaba el rumbo del
   GPS, que se actualiza cada 2 s con ±20° de ruido y no sabe hacia dónde apunta
   la cámara. Además, al pararse la flecha saltaba a la brújula. Ahora manda la
   brújula, como pide RF-29. El GPS solo entra si la brújula está interferida y
   se camina con buena señal.
3. **Puntería al vértice siguiente.** Con el vértice a 10-20 m, cada salto del
   GPS movía la flecha 15-30°. Ahora apunta a un punto 15 m adelante sobre la
   ruta (`SeguimientoRuta.rumboGuia`). Si la persona está a 4 m o menos del
   camino, sale de su proyección sobre él, así el ruido lateral no la mueve.

Además, la vista de cámara ancla un marcador amarillo sobre la puerta del
destino cuando entra en la imagen: nombre y metros, a la altura del horizonte.

## Datos y licencias

- El grafo sigue bajo ODbL (derivado de OSM), con su crédito en el plano.
- El catálogo de espacios es de MAPSUTB. Se usa con la autorización del
  profesor orientador y se acredita bajo los resultados del buscador («Salones y
  oficinas: MAPSUTB») y en el archivo (`fuente`, `permiso`).

## Pendiente

- **Para el backend:**
  - tablas de espacios y salones;
  - servir el catálogo y el grafo con versión (RF-34);
  - un evento de analítica «llegó con la guía», sin coordenadas (RN-10).
- **Para el campo:**
  - medir Contenedores y la entrada propia de EDA2;
  - confirmar las 3 uniones inferidas.

  Las tres se pueden quitar con el modo campo, con «Por aquí no se pasa».
