# Maqueta 3D del campus

El mapa del tour permite alternar entre el plano OSM y la maqueta de
[ElMapita UTB](https://github.com/ISCOUTB/AS_202620_ElMapita). El botón 3D está
en el mapa, debajo del contador de paradas. Conserva la selección del
carrusel, las fichas y el encuadre al volver al plano.

## Transición

La maqueta aparece primero cenital, con el mismo centro y la misma escala que
el plano, y se funde sobre él; luego la cámara se inclina a 55° y se acerca un
poco en 900 ms, con aceleración y frenado. Al volver se endereza y mira al
norte en 650 ms, y solo entonces el plano reaparece con el encuadre que dejó
el 3D. «Quitar animaciones» hace los cambios de golpe.

Flutter y el visor hablan en **metros visibles en vertical**, no en distancia
de cámara. model-viewer adapta el campo de visión a la proporción de la vista
(en retrato, `25deg` queda en unos 39° verticales); con un radio calculado en
Dart el 3D aparecía 1,6 veces más lejos que el plano y el fundido saltaba.

## Cámara y controles

- Arrastrar gira, pellizcar acerca, dos dedos desplazan. El centro de la vista
  no sale del campus y la inclinación se queda en 62°: más tumbada, la vista
  se llenaba de horizonte.
- A la derecha, los mismos tres botones que en 2D: ver todo, acercar y alejar.
- En 3D, bajo el botón 2D/3D, una fila con girar a la izquierda, la brújula y
  girar a la derecha. La aguja roja marca el norte; tocarla lo vuelve a poner
  arriba. Todos miden 48 dp y no requieren gestos (WCAG 2.5.7).
- Cada vuelo (centrar una parada, zoom, giro) dura entre 380 y 900 ms y se
  interrumpe con cualquier gesto.

## Pines y nombres

- Las paradas usan la misma figura que el plano 2D (caja de 56×60, círculo de
  34 y punta en y = 48): en el fundido no cambian de forma. Azul, o verde con
  ✓ si ya se visitó. La elegida en el carrusel crece, pulsa y muestra su nombre.
- Cada pin se clava en el techo o el suelo que tiene debajo: al cargar, con la
  cámara aún cenital, se mide con `positionAndNormalFromPoint`.
- Si dos paradas caen en el mismo sitio, una sube (o se aparta) y un tallo la
  une a su punto real. Una parada que no choca nunca se mueve.
- Los demás lugares son puntos mudos de lejos; de cerca son un círculo grafito
  con el icono de su categoría, dibujado en Flutter con el mismo `IconData`
  que el plano, y más cerca aún muestran su nombre si no pisa a otro.
- Las paradas van siempre encima de los lugares: model-viewer ordena los pines
  por profundidad y una hoja de estilo dentro de su shadow root lo corrige.

## Imagen

El modelo se ilumina con un entorno dibujado en el propio visor (cielo claro,
suelo más oscuro, sol y un lado opuesto más frío): con la luz por defecto
techos y fachadas salían del mismo tono. Detrás, un cielo tenue que solo
aparece al inclinar; en cenital el fondo es la tierra del plano.

Cada vista acredita lo que muestra: «© colaboradores de OpenStreetMap» en el
plano y «Modelo 3D: ElMapita UTB» en la maqueta.

## Preparar el modelo

Desde la raíz del repositorio, antes de compilar:

```sh
python -I scripts/preparar_modelo3d.py
```

El script descarga el GLB público, comprueba su SHA-256 y excluye del dibujo
el nodo `Plano_Referencia`, usado como imagen de apoyo al modelar, y los 28
rótulos de texto `Etq_*`: estaban solo en español, no se leían en un
teléfono, quedaban al revés al girar y no coincidían con los nombres del
catálogo. Los nombres los pone el módulo, traducidos y accesibles. Conserva
las coordenadas y la geometría del resto de la maqueta. Cualquier cambio al
modelo va en este script: CI lo reconstruye desde la descarga. El origen, autores,
URL y huella están en
[`origen.json`](../packages/tour_virtual/assets/mapa3d/origen.json).

El binario institucional no se versiona. El APK incorpora tanto el GLB como
el motor del visor y funciona sin conexión. CI prepara el recurso antes de
compilar ambas apps. Si falta el modelo o falla el visor, el plano sigue
disponible y se puede reintentar.

## Integración

Se reutiliza el modelo, sin introducir el backend ni el estado de ElMapita.
Las fichas, el catálogo de lugares, sus permisos y el progreso siguen siendo
los del módulo. Los pines se crean solo con los POI que este ya recibió.

La transformación OSM → modelo corresponde al ajuste provisional de
ElMapita (error medio aproximado de 9 m). `Georreferencia3d` permite también
la conversión inversa para conservar el centro del mapa. No interviene en
el cálculo de rutas ni de llegadas de AR: esos siguen usando el grafo y los
accesos medidos. La alineación se debe afinar con puntos reales del campus.

La vista 3D usa `model_viewer_plus` en Android e iOS. Windows y web conservan
el plano. La comprobación física de esta integración se realiza en Android;
el comportamiento de iOS requiere su propia revisión en dispositivo.

## Apps anfitrionas

El visor sirve recursos del APK mediante un servidor en `127.0.0.1`.
En Android la anfitriona debe permitir HTTP **solo hacia loopback**, manteniendo
HTTPS para la API y los medios externos. El ejemplo está en
[`network_security_config.xml`](../apps/mobile/android/app/src/main/res/xml/network_security_config.xml)
y se referencia desde el manifest de la app de demostración.

En iOS se configura `NSAppTransportSecurity.NSAllowsLocalNetworking`.
No se habilita HTTP general para la API.

## Comprobaciones

Para ajustar el visor sin teléfono:

```sh
python -I scripts/banco_mapa3d.py   # http://127.0.0.1:8765/
```

Arma la misma página que recibe el WebView, con los `visor.js` y `visor.css`
del módulo y los atributos de `mapa_3d.dart`. En la consola, `await escena()`
entra e inclina como la app y `registro` guarda los mensajes hacia Dart. Los
iconos de categoría son marcadores; la prueba en el dispositivo sigue siendo
la que vale.

```sh
python -B -I -m unittest discover -s scripts -p 'test_*.py' -v
cd apps/mobile
flutter test test/mapa_3d_test.dart
flutter test
```

Las regresiones cubren la transformación geográfica inversa, el fallo de
carga, la cancelación mientras carga y la conservación del carrusel, además
de excluir la referencia del GLB sin modificar su bloque binario.

La comprobación en un Android conectado usa una prueba dentro de Flutter,
sin inyectar toques en otras apps ni necesitar el permiso `INJECT_EVENTS`:

```sh
cd apps/mobile
flutter drive --driver=test_driver/mapa_3d.dart --target=integration_test/mapa_3d_test.dart -d <serial>
```

Verifica el GLB local, los pines, zoom, el giro exacto de 45°, la brújula,
el crédito de cada vista, la apertura de una ficha y el regreso al plano. Captura también texto al 200 %. Las imágenes quedan en
`.impeccable/review/`. Las preferencias de esa prueba viven en memoria; se
conservan los datos guardados por la persona. Después de ejecutarla se debe
reinstalar el APK normal: el comando instala una app de comprobación.
