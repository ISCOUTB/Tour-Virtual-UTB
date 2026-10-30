# Mapa del campus sobre OpenStreetMap

Desde el 2026-10-24 el mapa del módulo es un plano de OpenStreetMap del Campus Ternera. Sustituye a la ilustración isométrica de la universidad, que era incómoda de usar y no servía para ubicar a nadie. Cada lugar se dibuja por su lat/lng, la misma coordenada que usará la realidad aumentada (ver [plan-realidad-aumentada.md](plan-realidad-aumentada.md)).

## De dónde sale

- **Polígono del campus:** `way/68735397`, «Universidad Tecnológica de Bolívar - Campus Ternera».
- **Detalle:** casi todo (edificios A1 a A5, Zona T, biblioteca, cafés y 38 senderos) lo subió un solo usuario de OSM, `charlygz21`, el 2026-09-30. Nadie más lo ha revisado. Las canchas son de 2011.
- **Qué falta en OSM:** Enfermería, Centro Deportivo, Auditorio, Rectoría, el puente A3–A5, las entradas de los edificios y cualquier dato de accesibilidad (rampas, pendientes, escalones).

`scripts/mapa_campus.py` descarga esos datos de Overpass y genera tres archivos:

| Archivo | Qué es |
|---|---|
| `packages/tour_virtual/assets/campus_osm.geojson` | El plano: edificios, vías, senderos, escaleras, canchas, parqueaderos. Unos 46 KB, empaquetado con la app. |
| `scripts/datos/pois_campus.json` | Los 26 lugares, con lat/lng y de dónde sale cada posición. |
| `scripts/datos/pois_campus.sql` | El mismo catálogo para la base compartida (ver «Qué le toca a backend»). |

Para regenerarlos: `python scripts/mapa_campus.py`. Con `--guardar-crudo` guarda la descarga y con `--crudo` la reutiliza sin volver a pedirla.

La app no muestra etiquetas sobre el plano. Todo lugar con nombre es un POI con su marcador.

## Correcciones

**A3 y A4 están intercambiados en OSM.** La leyenda institucional tiene razón, y se comprobó en el campus el 2026-10-24. El script corrige el nombre en el plano. Si alguien lo arregla en OSM, la corrección del script deja de cambiar nada.

**La biblioteca tiene dos polígonos en OSM y los dos son correctos:** son sus dos accesos. El marcador usa el grande (`way/97546334`). Para la realidad aumentada importan los dos accesos.

## Precisión de cada posición

| Fuente | Lugares | Precisión |
|---|---|---|
| Elemento de OSM (centroide) | Biblioteca, Zona T, canchas, edificios A1 a A5, salas de estudio, cafetería, tienda, cajero | La del trazado de OSM sobre foto aérea; unos pocos metros |
| Leyenda de `Mapa_UTB.pdf`, por ajuste afín | Auditorio, Edificio Alcatraz, Plaza Maloca, Rectoría, Laboratorio El Patio, QUID, Centro Deportivo | Unos 9 m de error típico y hasta 15 m |
| Punto medio entre A3 y A5 | Puente A3 - A5 | Aproximado |
| Marcado por el equipo sobre el mapa de OSM | Enfermería (en el edificio de la Zona T), Pasillo de la conexión (glorieta junto al A2), Solo Café (la cafetería que OSM tiene como `coffee_shop`), La Placita, QuantaLab (en el Edificio A5) | La captura se georreferenció con 12 edificios y canchas: 0,7 m de error mediano y 2,3 m como máximo, más lo que se haya desviado la marca |

**Cómo funciona el ajuste afín.** Una ilustración isométrica de un terreno plano es una transformación afín del plano. Ocho marcadores de la leyenda tienen su edificio en OSM, y con ellos se ajusta la transformación por mínimos cuadrados. Con eso basta para poner un marcador en el plano. **No basta para la realidad aumentada:** su radio de llegada es de 10 m, y además se necesita el punto donde la persona se para, no el centro del edificio.

Enfermería queda en el mismo edificio que la Zona T, a unos 10 m de su marcador. En el mapa de lejos los dos pines casi se tocan; al acercar se separan.

**Fuera del catálogo por ahora:** Granja Solar, que queda lejos del núcleo del campus, y Pasillo del éxito, cuya ubicación no está confirmada. Entran cuando se sepa dónde están.

## Paradas y lugares

- Una **parada** es un POI con escena 360 (`escena_principal_id`). Lleva número, entra en el carrusel y en la lista, y cuenta para el avance.
- Los demás POI son **lugares del campus**. Se ven como puntos y solo se pueden tocar al acercar el mapa; también están en «Más lugares del campus», al final de Recorrido. Abren su ficha sin número y no cuentan como visita.
- En cuanto un lugar recibe su panorámica desde el panel, pasa a ser parada sin cambiar nada en la app.

Hay tres categorías nuevas: `Cultura`, `Administrativo` y `Sostenibilidad`, con icono y traducción en los 11 idiomas.

## Licencia

Los datos de OSM son **ODbL 1.0**.

- La app muestra «© colaboradores de OpenStreetMap» sobre el mapa. Es obligatorio.
- `campus_osm.geojson` es una base de datos derivada y se distribuye dentro de la app, así que también queda bajo ODbL. Lo cumple estar en el repositorio público.
- Cualquier corrección que se suba a OSM tiene que venir de observarla en el campus. `Mapa_UTB.pdf` es material institucional y no se puede usar como fuente para editar OSM sin permiso de la universidad.
- No se usan los servidores de mosaicos de OSM: la app dibuja el plano con sus propios datos. Así no depende de su política de uso y funciona sin conexión.

## Qué le toca a backend

1. **Lat/Lng en la API de administración.** `CrearPoiRequest` y `ActualizarPoiRequest` no tienen `Lat` ni `Lng`, así que hoy no hay forma de guardar una posición por la API. Hay que agregarlos, pasarlos en `ContenidoService` y regenerar `packages/contracts/openapi.yaml` y `apps/admin/src/api/schema.d.ts`.
2. **Cargar el catálogo en la base compartida.** Primero hay que revisar `scripts/datos/pois_campus.sql` y luego ejecutarlo. Se puede ejecutar más de una vez sin efectos repetidos. Hace dos cosas:
   - A las cinco paradas les pone lat/lng y los textos del guion (y renombra «Enfermeria» a «Enfermería»).
   - Crea los 21 lugares restantes si no existen, reconociéndolos por nombre.

   `ContenidoInicial.cs` ya trae lo mismo para una base nueva. Ojo: se cambió desde la rama de frontend y no se compiló aquí, porque no hay SDK de .NET.
3. **`escena_principal_id` nulo si la escena no tiene panorámica.** Desde `EscenaImagenOpcional` puede existir una escena sin imagen. `/recorrido` ya la filtra, pero el POI la sigue anunciando: la app lo contaría como parada y ofrecería un 360 que no abre.
4. **El mapa ilustrado ya no se usa.** La app dejó de pedir `GET /api/lugares/{id}/mapa`. El endpoint puede quedarse, pero el panel no necesita una función para subir mapas.
5. **Panel de administración.** El formulario de POI necesita lat/lng, idealmente eligiéndolos sobre el mismo `campus_osm.geojson` (Leaflet o MapLibre lo leen tal cual), y una vista de los lugares sin posición.
