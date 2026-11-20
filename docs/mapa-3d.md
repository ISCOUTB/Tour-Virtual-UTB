# Maqueta 3D del campus

El mapa del tour permite alternar entre el plano OSM y la maqueta de
[ElMapita UTB](https://github.com/ISCOUTB/AS_202620_ElMapita). El botón 3D está
en el mapa, debajo del contador de paradas. Conserva la selección del
carrusel, las fichas y el encuadre al volver al plano.

La transición cruza el plano con una vista cenital del modelo y luego inclina
la cámara. Al volver, la cámara se endereza antes del fundido. «Quitar
animaciones» evita el movimiento espacial. Zoom, giro y encuadre también
tienen botones de 48 dp; no requieren pellizcar ni arrastrar.

## Preparar el modelo

Desde la raíz del repositorio, antes de compilar:

```sh
python -I scripts/preparar_modelo3d.py
```

El script descarga el GLB público, comprueba su SHA-256 y excluye del dibujo
el nodo `Plano_Referencia`, usado como imagen de apoyo al modelar. Conserva
las coordenadas y la geometría del resto de la maqueta. El origen, autores,
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

```sh
python -B -I -m unittest discover -s scripts -p 'test_*.py' -v
cd apps/mobile
flutter test test/mapa_3d_test.dart
flutter test
```

Las regresiones cubren la transformación geográfica inversa, el fallo de
carga, la cancelación mientras carga y la conservación del carrusel, además
de excluir la referencia del GLB sin modificar su bloque binario.
