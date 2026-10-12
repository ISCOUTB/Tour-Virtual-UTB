# Idiomas y accesibilidad

El módulo tiene que servir a cualquier persona de la UTB:

- la comunidad internacional (Brasil, Portugal, Italia, España, Estados Unidos, Francia, Alemania, Turquía, Corea, China, Japón…);
- personas con discapacidad visual, auditiva, motriz, del habla o cognitiva.

El objetivo es **WCAG 2.2 nivel AA**. Este documento explica qué hace hoy la app, cómo se trabaja con los idiomas, qué formato deben tener los audios y subtítulos, y qué falta en el backend.

El trabajo está repartido así:

| Parte | Quién |
|---|---|
| Interfaz, idiomas de la app y accesibilidad del módulo | Frontend |
| Audios narrados por idioma y sus subtítulos | José González |
| Traducción del contenido (nombres, descripciones) y guardar idioma por medio | Backend, con Comunicaciones |

## 1. Qué hace la app hoy

| Necesidad | Qué hace el módulo | WCAG |
|---|---|---|
| **Lector de pantalla** (TalkBack, VoiceOver) | Todo botón tiene nombre y responde al doble toque. Paradas y marcadores anuncian número, nombre, categoría y si ya se visitaron. El visor 360 describe la escena y anuncia «Estás en…» al llegar. Las salidas de cada escena también son botones. La postal panorámica tiene acciones «Girar a la izquierda / derecha». | 1.1.1, 2.4.6, 4.1.2, 4.1.3 |
| **Contenido en otro idioma** | Lo que llega del servidor en español se marca con su idioma: el lector cambia de voz para leerlo en lugar de pronunciarlo con la voz del inglés o del japonés. La ficha avisa: «Información disponible en Español». | 3.1.2 |
| **Baja visión** | El texto crece hasta el 200 % sin cortarse. El ajuste del módulo se suma al del teléfono y tiene tope en 200 %. Hay alto contraste, que se activa con el ajuste del sistema o con el del módulo: el texto secundario queda en 8,4:1 o más (AAA) y los bordes, en 4,4:1. El foco del teclado es visible. | 1.4.4, 1.4.6, 1.4.11, 2.4.7 |
| **Sordera o hipoacusia** | Subtítulos en vivo debajo del audio y sobre el video, transcripción completa y botón CC. Nada depende del sonido: el hotspot vibra pero no suena. | 1.2.1, 1.2.2 |
| **Lengua de señas** | Un video con idioma `csn` aparece en su propia sección, «Lengua de señas», justo después del audio. | 1.2.6 (AAA) |
| **Movilidad reducida** | Objetivos táctiles de 48 dp o más. Se puede girar el 360 con botones, hacer zoom en el mapa con + y −, e ir a otra escena sin buscar el hotspot. El giroscopio se puede apagar. | 2.5.4, 2.5.7, 2.5.8 |
| **Habla** | Ninguna función pide voz. | — |
| **Vestibular o cognitiva** | «Reducir movimiento», del sistema o del módulo, quita las animaciones, los giros y el 3D. No hay límites de tiempo. Las pistas desaparecen solas, pero lo que dicen sigue disponible en los controles. | 2.2.1, 2.3.3 |

Los ajustes del módulo están en el botón del globo de la cabecera, el que muestra «ES», «EN», etc. Es un globo con el código de idioma para que lo reconozca quien no lee español. Cada ajuste se suma al del sistema, nunca lo anula.

## 2. Idiomas de la interfaz

| Código | Idioma | Observación |
|---|---|---|
| `es` | Español | Original. Plantilla de todos los textos |
| `en` | English | Idioma de respaldo |
| `pt` | Português (Brasil) | Lo usan todos los países lusófonos excepto Portugal |
| `pt_PT` | Português (Portugal) | Solo incluye lo que cambia: «telemóvel», «paragem»… El resto lo hereda de `pt` |
| `fr` | Français | |
| `it` | Italiano | |
| `de` | Deutsch | |
| `tr` | Türkçe | Mayúsculas propias: «İLK DURAK» |
| `ko` | 한국어 | Letra del sistema |
| `ja` | 日本語 | Letra del sistema |
| `zh` | 中文（简体） | Letra del sistema. El chino tradicional también usa este |

**Cómo se elige:** se toma el primero de los idiomas del teléfono que esté traducido. Si ninguno lo está, el módulo usa **inglés**, no español: alguien con el teléfono en ruso o en árabe entiende antes el inglés. El usuario puede fijar otro idioma desde el globo y la elección se recuerda.

**Dónde están los textos:** en `apps/mobile/lib/l10n/textos_<código>.arb`. Ningún texto de la interfaz se escribe directamente en el código; se usa `Textos.of(context).clave`.

Para **añadir o cambiar un texto**:

1. Escríbelo en `textos_es.arb`. Si es ambiguo, añade una `description` para quien traduce.
2. Tradúcelo en cada `textos_<código>.arb`.
3. Ejecuta `flutter pub get` (o `flutter gen-l10n`) y versiona los `.dart` que se generan.
4. `test/textos_test.dart` falla si a un idioma le falta una clave o un marcador como `{nombre}`.

Para **añadir un idioma**: crea su `.arb` completo, agrega una línea en `idiomasUi` y su nombre en `nombreDeIdioma` (los dos en `lib/nucleo/idiomas.dart`) y verifica que la prueba de textos pase. Los idiomas que se escriben de derecha a izquierda, como el árabe, todavía no están preparados: antes hay que cambiar los márgenes y alineaciones fijos a sus versiones direccionales.

> **Las traducciones de esta primera versión no las ha revisado un hablante nativo.** Antes de publicar, alguien que hable cada idioma debería leer su archivo; los estudiantes de intercambio son la fuente natural. Basta con editar el `.arb` correspondiente.

## 3. Audios y subtítulos

Esta sección es la especificación para producir las narraciones.

**Narraciones**

- Una narración por lugar y por idioma. La versión en español es obligatoria; las demás se agregan cuando estén listas.
- Formato MP3 mono a 64 kbps y 44,1 kHz, el mismo al que `scripts/subir_medios.py` convierte hoy.
- Volumen normalizado a −16 LUFS integrados con pico máximo de −1 dBTP, para que no haya saltos de volumen de un lugar a otro.
- Voz clara y a ritmo pausado. Si hay música, debe quedar por debajo de la voz: quien tiene hipoacusia pierde la voz cuando la música compite.
- La app elige la narración en el idioma de quien escucha; si no existe, usa la original con sus subtítulos. Cuando hay varias, se puede cambiar desde «Escuchar en».

**Subtítulos (uno por cada narración y en el mismo idioma)**

- WebVTT en UTF-8. Un `.srt` también sirve, y un `.txt` también, aunque este último solo da la transcripción, sin subtítulos en vivo.
- Cada frase en un bloque: máximo dos líneas de unos 42 caracteres y entre 1 y 7 segundos en pantalla.
- Sincronizados con la voz, con un desfase de ±0,2 s como máximo.
- Los sonidos que importan van entre corchetes: `[música]`, `[risas]`. Si habla más de una persona, se usa `<v Nombre>`.

```text
WEBVTT

1
00:00.000 --> 00:04.200
Más que una biblioteca: concentración,

2
00:04.200 --> 00:09.500
disciplina, tecnología y construcción de sueños.
```

**Nombres de archivo.** El idioma va con su código BCP 47:

```text
audios/biblioteca.mp3            original en español
audios/biblioteca.en.mp3         inglés
audios/biblioteca.pt-BR.mp3      portugués de Brasil
subtitulos/biblioteca.vtt        subtítulos del original
subtitulos/biblioteca.en.vtt     subtítulos de la narración en inglés
```

**Revisarlos en la app sin backend.** Pon los archivos en la carpeta que sirve el modo demo (ver la guía de desarrollo) y arranca con:

```powershell
flutter run -d windows --dart-define=DATOS=demo --dart-define=MEDIOS_DEMO=http://127.0.0.1:8765
```

El modo demo busca solo `audios/<lugar>.<idioma>.mp3` y `subtitulos/<lugar>[.<idioma>].vtt`. En la ficha aparecen el selector de idioma, el botón CC y los subtítulos mientras suena. Los nombres de lugar son `biblioteca`, `enfermeria`, `zona-t` y `cancha-softbol`.

**Lengua de Señas Colombiana.** Un video por lugar con idioma `csn`. La persona intérprete va en plano medio, sobre fondo liso y con buena luz, y el video lleva también subtítulos.

**Videos con información visual.** Si un video muestra algo que el audio no cuenta (letreros, recorridos), necesita audiodescripción (WCAG 1.2.5) o una narración que lo diga.

## 4. Lo que necesitamos del backend

Es una propuesta: el backend es de otro equipo y la app ya funciona sin estos cambios.

1. **Columna `idioma` en `Medio`**: `text null`, código BCP 47, en la entidad y en `MedioDto` como `idioma`. Se permiten varios audios por POI, uno por idioma. Si viene vacío, la app lo toma como español.
2. **`subtitulos_url` firmada** como las demás URL de S3.
3. **Traducciones del contenido.** La app envía `Accept-Language` (por ejemplo `pt-BR, es;q=0.5`) en cada consulta. El servidor responde en ese idioma si tiene traducción, o en español si no, e indica el idioma que usó con `Content-Language`. Habría que traducir el nombre y la descripción del POI, el nombre y la descripción de la ruta, el nombre de la escena y la etiqueta del hotspot. Una tabla `poi_traducciones (poi_id, idioma, nombre, descripcion)` y sus equivalentes bastan.
4. **`texto_alt` en `Escena`**: qué se ve en la panorámica, para quien no la ve. Mientras no exista, el visor usa la descripción del POI.
5. **Tipos nuevos de medio**: la app ignora los que no conoce en vez de fallar, así que se pueden añadir sin coordinar una versión.
6. **Panel de administración**: debe exigir `texto_alt` y `subtitulos_url` antes de publicar, como ya dice `docs/arquitectura.md`.

## 5. Cómo se prueba

Pruebas automáticas, en `apps/mobile/test/`:

- `textos_test.dart`: cada idioma completo, los marcadores intactos, la elección de idioma, las mayúsculas en turco y el tope del 200 %.
- `widget_test.dart`, grupo `accesibilidad`:
  - nada se corta con el texto al 200 % en español, alemán y japonés;
  - el lector de pantalla puede activar cada botón;
  - se cumplen las guías de Flutter de objetivo táctil y etiqueta;
  - el alto contraste funciona, tanto el del sistema como el del módulo.
- `widget_test.dart`, grupo `idioma`: sigue al teléfono, distingue Portugal del resto, cae al inglés y recuerda la elección.

En un teléfono real (**todavía no se ha hecho**; hasta ahora solo hay pruebas automáticas y capturas de escritorio):

- [ ] TalkBack y VoiceOver: recorrer la lista, abrir una ficha, reproducir el audio, entrar al 360, ir a otra escena con los botones de salida y volver.
- [ ] Texto del sistema al máximo, con y sin «Muy grande» en el módulo.
- [ ] «Aumentar contraste» (iOS) y alto contraste del módulo.
- [ ] «Quitar animaciones» de Android y «Reducir movimiento» de iOS.
- [ ] Accesibilidad con interruptores de Android o un teclado Bluetooth: el foco tiene que verse en cada control.
- [ ] Teléfono en japonés y en turco: las letras de los textos y las mayúsculas.
- [ ] Giroscopio apagado: la escena no se mueve al mover el teléfono.

## 6. Pendiente

- Verificación en teléfonos reales (sección 5).
- Revisión nativa de las traducciones.
- Traducción del contenido en el backend (sección 4). Mientras no exista, nombres y descripciones se ven en español con el aviso correspondiente.
- Narraciones por idioma, subtítulos y videos en Lengua de Señas Colombiana.
- Idiomas de derecha a izquierda.
- Chino tradicional, que hoy usa el simplificado.
