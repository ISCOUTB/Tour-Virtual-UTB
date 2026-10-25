# Tareas de backend tras el mapa OSM y las narraciones (2026-10-24)

La rama `frontend/rediseno-modulo-utb` trae cuatro cambios:

- el mapa del campus sobre OpenStreetMap;
- 26 lugares con lat/lng;
- narraciones en 11 idiomas con subtítulos;
- textos alternativos para las panorámicas.

La app ya funciona con todo eso en modo demo. Para que funcione contra la API y la base compartida faltan las tareas de abajo. No hay conflictos con `mejoras-backend-medios` ni con `feature/panel-admin`: esta rama solo cambia `services/api/Data/ContenidoInicial.cs`.

Los archivos de audio y subtítulos no están en el repositorio. Van en `entrega-backend-2026-10-24.zip`, compartido por Drive (ver «Qué trae el zip»).

## 1. API: guardar lat/lng de los POI

`PoiDto` ya devuelve `lat` y `lng`, pero la API de administración no deja escribirlos.

- [ ] Agregar `double? Lat` y `double? Lng` a `CrearPoiRequest` y `ActualizarPoiRequest` en `DTOs/AdminRequests.cs`.
- [ ] Pasarlos en `ContenidoService.CrearPoiAsync` y `ActualizarPoiAsync`.
- [ ] Regenerar `packages/contracts/openapi.yaml` y `apps/admin/src/api/schema.d.ts`.

## 2. Base compartida: cargar el catálogo de lugares

- [ ] Revisar y ejecutar [`scripts/datos/pois_campus.sql`](../scripts/datos/pois_campus.sql). Se puede ejecutar más de una vez sin efectos repetidos. Hace dos cosas:
  - A las cinco paradas les pone lat/lng y los textos del guion institucional, y renombra «Enfermeria» a «Enfermería». Las reconoce por nombre, no por id.
  - Crea los 21 lugares restantes si no existen: edificios A1 a A5, Auditorio, Rectoría, Solo Café, QuantaLab y otros.
- [ ] Comprobar: `GET /api/lugares/1/pois` debe devolver 26 POI, todos con `lat` y `lng`.

El origen de cada posición y su precisión están en [docs/mapa-osm.md](mapa-osm.md). El SQL lo genera `scripts/mapa_campus.py`; no se edita a mano.

## 3. API: una escena sin panorámica no hace parada

Desde la migración `EscenaImagenOpcional` puede existir una escena sin imagen. `/recorrido` ya la filtra, pero el POI la sigue anunciando en `escena_principal_id`. La app trata como **parada** a todo POI con `escena_principal_id`, así que lo numeraría y ofrecería un 360 que no abre.

- [ ] En `PoiDto`, devolver `escena_principal_id = null` cuando la escena principal no tiene `ImagenUrl`.

## 4. API: narraciones por idioma y subtítulos

Hoy cada POI tiene un solo audio, en español y sin subtítulos. Las nuevas son 88: 8 lugares en 11 idiomas, cada una con su WebVTT.

- [ ] **Columna `Idioma`** (`string?`, código BCP 47) en `Models/Medio.cs`, con su migración EF, y `idioma` en `MedioDto`, `CrearMedioRequest`, `ActualizarMedioRequest` y `SubirMedioRequest`. Nulo significa español. La app ya la lee: elige la narración del idioma de la interfaz y deja cambiarla en «Escuchar en».
- [ ] **Varios audios por POI**, uno por idioma. Hay que comprobar que nada impide más de un `Medio` de tipo audio por POI.
- [ ] **Subir el `.vtt`.** `TiposArchivo` no acepta `.vtt` y `SubirMedioRequest` no tiene campo de subtítulos. Propuesta:
  - un `IFormFile? Subtitulos` en `SubirMedioRequest`, guardado en la carpeta `subtitulos` (agregarla a `CarpetasPermitidas`) con `Content-Type: text/vtt`;
  - su ruta va a `SubtitulosUrl`.
- [ ] **Cargar las 88 narraciones del zip:**
  - Un `Medio` por fila de `manifiesto.csv`: tipo `audio`, `idioma`, `duracion_seg`, `texto_alt = "Audio narrado de <lugar>"` y su VTT.
  - Los POI se reconocen por el nombre de la columna `poi`, el mismo de `pois_campus.sql`.
  - Los 5 audios en español que hay hoy se **reemplazan**: borrarlos o desactivarlos.
  - Tres lugares que no son paradas también tienen narración: Solo Café, La Placita y QuantaLab.
- [ ] **Comprobar:** `GET /api/pois/{id}` del Puente debe devolver 11 audios, cada uno con `idioma` y `subtitulos_url` firmada. La firma ya existe en `ObtenerPoiPorIdAsync`.

## 5. API: texto alternativo de las panorámicas

Es lo que el lector de pantalla dice en el visor 360, para quien no ve la imagen (WCAG 1.1.1). Mientras falte, la app lee la descripción del POI.

- [ ] Agregar la columna `TextoAlt` (`string?`) en `Models/Escena.cs` con su migración, `texto_alt` en `EscenaDto` y en los requests de escena.
- [ ] Cargar los 5 textos de [`scripts/datos/escenas_texto_alt.json`](../scripts/datos/escenas_texto_alt.json). La clave es el nombre del archivo de la panorámica: `biblioteca`, `puente-a3-a5`, `enfermeria`, `zona-t` y `cancha-softbol`.

## 6. API: revisar `ContenidoInicial.cs`

- [ ] Compilarlo y revisarlo. Se cambió desde la rama de frontend sin SDK de .NET, así que no se compiló.
  - Trae los 26 POI con lat/lng y asigna la escena principal desde las escenas.
  - Solo importa para una base nueva: `Program.cs` tiene la siembra comentada.

## 7. Panel de administración

- [ ] **Formulario de POI con lat/lng**, idealmente eligiendo el punto sobre el mismo plano que usa la app: `apps/mobile/android/app/src/assets/campus_osm.geojson`. Leaflet o MapLibre lo leen tal cual.
  - Es ODbL: hay que mostrar «© colaboradores de OpenStreetMap».
  - Una vista de los lugares sin posición.
- [ ] **Medios:**
  - selector de idioma y carga del subtítulo;
  - no dejar publicar un audio o video sin `subtitulos_url`, ni una imagen sin `texto_alt` (WCAG 2.2 AA; ver `docs/arquitectura.md` y `docs/ACCESIBILIDAD.md`).
- [ ] **No hace falta subir un mapa ilustrado.** La app ya no llama a `GET` ni `POST /api/lugares/{id}/mapa`. El endpoint puede quedarse.

## 8. Después, sin urgencia

- [ ] **Marcar la voz sintética.** Las 88 narraciones son de una voz diseñada con IA (VoxCPM2), no de una persona. Un campo en `Medio`, como `VozSintetica bool`, permitiría que la app lo diga en el reproductor. Es buena práctica y lo piden los propios modelos.
- [ ] **Traducir el contenido** según `Accept-Language`, respondiendo con `Content-Language` (ver `docs/ACCESIBILIDAD.md`, sección 4.3).
  - Para los 8 lugares con narración ya hay nombre y descripción en 11 idiomas en `scripts/narraciones/guiones.json`.
  - Son borradores sin revisión nativa.
- [ ] **Datos de la realidad aumentada.** Hay que decidir dónde viven el grafo peatonal (JSON), la tabla `accesos` (la Biblioteca tiene dos entradas), `escenas.rumbo_norte` y los campos `ar_*` del POI, y si eso espera a la migración a Firestore del SRS. La propuesta está en [docs/plan-realidad-aumentada.md](plan-realidad-aumentada.md), en «Modelo de datos propuesto».

## Qué no hay que tocar

Las categorías nuevas (`Cultura`, `Administrativo`, `Sostenibilidad`) son texto libre en `Poi.Categoria`: no requieren cambios.

## Qué trae el zip

El archivo es `entrega-backend-2026-10-24.zip`.

| Ruta | Qué es |
|---|---|
| `narraciones/audios/` | 88 MP3, mono a 64 kbps, a −16 LUFS con el pico bajo −1 dBTP. Se llaman `<lugar>.mp3` (español) y `<lugar>.<idioma>.mp3`. |
| `narraciones/subtitulos/` | 88 WebVTT en UTF-8, con el mismo nombre que su audio. |
| `narraciones/manifiesto.csv` | Una fila por narración: archivos, POI, idioma, duración y verificación. |
| `narraciones/informe.json` | La verificación: lo que oyó el reconocedor en cada clip frente al guion. |
| `LEEME.md` | Cómo se generaron y cómo se cargan. |

Los idiomas son los de la app: `es`, `en`, `pt` (Brasil), `pt-PT`, `fr`, `it`, `de`, `tr`, `ko`, `ja` y `zh`.

Cómo se producen las narraciones: [docs/ACCESIBILIDAD.md](ACCESIBILIDAD.md), sección 3, y `scripts/narraciones/generar_narraciones.py`.
