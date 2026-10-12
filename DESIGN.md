---
name: UTB Tour Virtual
description: Módulo de recorrido virtual dentro de la app UTB oficial; adopta su lenguaje visual medido, sin estilo propio.
colors:
  fondo: "#010406"
  superficie: "#1B1C1E"
  superficie-sobre-azul: "#1A1E29"
  superficie-elevada: "#252C3E"
  hoja: "#121317"
  indicador: "#2D3D5E"
  fondo-info: "#1F3040"
  borde: "#FFFFFF14"
  borde-fuerte: "#FFFFFF33"
  contorno-segmentos: "#8E9199"
  azul: "#2047CD"
  azul-claro: "#6B9BF7"
  azul-info: "#7FA6F0"
  texto: "#FFFFFF"
  texto-secundario: "#A0A2A8"
  texto-tenue: "#8E9096"
  texto-terciario: "#6E7076"
  texto-sobre-azul: "#C9D5F7"
  verde: "#52C46A"
  amarillo: "#F2D54E"
  naranja: "#DF9349"
  morado: "#C046DF"
  rojo: "#E5534B"
  cabecera-arriba: "#1E49D3"
  cabecera-medio: "#15318F"
  cabecera-abajo: "#0E2161"
  cabecera-brillo: "#4A4FE3"
  destacada-inicio: "#112881"
  destacada-fin: "#376EBA"
  arranque-centro: "#16307A"
  arranque-borde: "#081B45"
  arranque-brillo: "#214E77"
typography:
  display:
    fontFamily: "Roboto"
    fontSize: "34px"
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: "-0.4px"
  headline:
    fontFamily: "Roboto"
    fontSize: "28px"
    fontWeight: 700
    lineHeight: 1.15
    letterSpacing: "-0.3px"
  headline-sm:
    fontFamily: "Roboto"
    fontSize: "24px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "-0.2px"
  title-lg:
    fontFamily: "Roboto"
    fontSize: "21px"
    fontWeight: 500
    lineHeight: 1.25
  title:
    fontFamily: "Roboto"
    fontSize: "18px"
    fontWeight: 500
    lineHeight: 1.3
  title-sm:
    fontFamily: "Roboto"
    fontSize: "15px"
    fontWeight: 500
    lineHeight: 1.3
  body-lg:
    fontFamily: "Roboto"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.45
  body:
    fontFamily: "Roboto"
    fontSize: "14.5px"
    fontWeight: 400
    lineHeight: 1.4
  body-sm:
    fontFamily: "Roboto"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: 1.35
  label:
    fontFamily: "Roboto"
    fontSize: "16px"
    fontWeight: 500
    letterSpacing: "0.1px"
  label-sm:
    fontFamily: "Roboto"
    fontSize: "13px"
    fontWeight: 500
  sobretitulo:
    fontFamily: "Roboto"
    fontSize: "12.5px"
    fontWeight: 500
    lineHeight: 1.2
    letterSpacing: "1.6px"
rounded:
  info: "18px"
  tarjeta-compacta: "22px"
  cabecera-compacta: "24px"
  tarjeta: "26px"
  hoja: "28px"
  cabecera: "32px"
  postal: "16px"
  pildora: "999px"
spacing:
  xs: "6px"
  sm: "8px"
  md: "12px"
  margen: "18px"
  tarjeta: "20px"
  toque: "48px"
components:
  button-primary:
    backgroundColor: "{colors.azul}"
    textColor: "{colors.texto}"
    typography: "{typography.label}"
    rounded: "{rounded.pildora}"
    padding: "0 24px"
    height: "52px"
  button-primary-disabled:
    backgroundColor: "{colors.superficie-elevada}"
    textColor: "{colors.texto-terciario}"
    rounded: "{rounded.pildora}"
    height: "52px"
  button-text:
    textColor: "{colors.azul-claro}"
    typography: "{typography.label}"
    rounded: "{rounded.pildora}"
    height: "48px"
  button-outlined:
    textColor: "{colors.texto}"
    typography: "{typography.label}"
    rounded: "{rounded.pildora}"
    height: "48px"
  button-glass:
    backgroundColor: "#FFFFFF29"
    textColor: "{colors.texto}"
    typography: "{typography.label}"
    rounded: "{rounded.pildora}"
    padding: "10px 20px"
    height: "48px"
  button-circular:
    backgroundColor: "#00000099"
    textColor: "{colors.texto}"
    rounded: "{rounded.pildora}"
    size: "48px"
  segmented-selected:
    backgroundColor: "{colors.azul}"
    textColor: "{colors.texto}"
    rounded: "{rounded.pildora}"
    height: "46px"
  segmented-unselected:
    backgroundColor: "{colors.fondo}"
    textColor: "{colors.texto}"
    rounded: "{rounded.pildora}"
    height: "46px"
  card:
    backgroundColor: "{colors.superficie}"
    textColor: "{colors.texto}"
    rounded: "{rounded.tarjeta}"
    padding: "20px"
  card-compact:
    backgroundColor: "{colors.superficie}"
    rounded: "{rounded.tarjeta-compacta}"
    padding: "16px 10px 16px 18px"
  card-featured:
    backgroundColor: "{colors.destacada-inicio}"
    textColor: "{colors.texto}"
    rounded: "{rounded.hoja}"
    padding: "24px 22px 22px 22px"
  info-box:
    backgroundColor: "{colors.fondo-info}"
    textColor: "{colors.texto}"
    rounded: "{rounded.info}"
    padding: "14px 12px 14px 16px"
  chip:
    backgroundColor: "#7FA6F024"
    textColor: "{colors.azul-info}"
    typography: "{typography.sobretitulo}"
    rounded: "{rounded.pildora}"
    padding: "5px 10px"
  sheet:
    backgroundColor: "{colors.hoja}"
    textColor: "{colors.texto}"
    rounded: "{rounded.hoja}"
  snackbar:
    backgroundColor: "{colors.superficie-elevada}"
    textColor: "{colors.texto}"
    typography: "{typography.body}"
    rounded: "{rounded.postal}"
---

# Design System: UTB Tour Virtual

## Overview

**Creative North Star: "El módulo anfitrión"**

El tour no tiene identidad visual propia. Es un módulo de la app UTB oficial y se lee como tal desde el primer cuadro: tema oscuro casi negro, cabecera azul con arcos que colapsa, tarjetas grafito, Roboto, sobretítulos en versalitas, el selector segmentado de Agenda y los anillos de avance. Cada tono se **midió** sobre las capturas de `docs/capturas_utbapp/` (a 1,4 px por dp), no se inventó. Si la anfitriona cambia, se vuelve a medir allí; este archivo describe una adopción, no un diseño original. Compromiso de marca registrado en PRODUCT.md el 2026-10-11.

Lo único que el módulo añade es lo que la anfitriona no tiene y el tour necesita: la postal 3D de la panorámica que se inclina con el dedo, el mapa isométrico que entra inclinado, la revelación circular hacia el visor 360 y los marcadores que se contraescalan contra la cámara. Todo eso se construye con código y con el mismo vocabulario de color, radio y movimiento que el resto; no introduce material nuevo.

Densidad media, de app institucional: márgenes de 18, tarjetas de radio amplio, un azul de acción por pantalla. El módulo no pinta barra inferior propia (la pone la anfitriona) y no replica el asistente robot de la anfitriona, que es global de ella.

**Key Characteristics:**
- Oscuro por defecto: negro con punto de azul de fondo, grafito para tarjetas.
- Un solo azul de acción lleno; un azul claro para lo legible sobre negro.
- Cabeceras azules con gradiente, resplandor violeta y arcos finos concéntricos, esquinas inferiores redondeadas.
- Radios amplios (22-32) y píldoras en todo lo pulsable.
- Movimiento de salida exponencial; todo efecto decorativo se apaga con «Quitar animaciones».

## Colors

Una paleta prestada y medida: negros azulados en capas tonales, un azul real institucional como única acción, y cinco puntos de color de la Agenda que codifican categorías.

### Primary
- **Azul de acción UTB** (azul): botón lleno principal, segmento elegido del selector, fondo del botón de reproducir. Aparece una vez por pantalla como acción dominante.
- **Azul legible** (azul-claro): azul que sí alcanza contraste sobre negro. Enlaces y botones de texto, números de parada, anillos de avance, pista activa del deslizador, indicador de progreso.
- **Azul informativo** (azul-info): icono y encabezado del recuadro informativo y de las píldoras de etiqueta.

### Secondary
- **Gradiente de cabecera** (cabecera-arriba → cabecera-medio → cabecera-abajo, paradas 0 / 0,62 / 1) con un **resplandor violeta** (cabecera-brillo al 90 %) anclado abajo a la derecha y una luz blanca al 7 % arriba a la izquierda. Solo en cabeceras y en la cara «recorrido completado» de la postal.
- **Destacada** (destacada-inicio → destacada-fin, en diagonal): la tarjeta de la próxima parada, equivalente del «Tu carnet digital» de la anfitriona.
- **Arranque** (arranque-centro, arranque-borde, arranque-brillo): solo la pantalla de carga.

### Tertiary
Puntos de categoría, copiados de los puntos de materia de la Agenda: **azul-claro** recursos/biblioteca, **amarillo** académico, **verde** bienestar/salud (y también «visitado»), **naranja** servicios/comida, **morado** deporte. **Rojo** solo para error.

### Neutral
- **Negro anfitrión** (fondo): página, lienzo, barra de sistema.
- **Hoja** (hoja): hojas inferiores; un paso sobre el fondo, uno bajo la tarjeta.
- **Grafito** (superficie): tarjetas y esqueletos de carga.
- **Grafito sobre azul** (superficie-sobre-azul): tarjeta que monta sobre la cabecera azul.
- **Elevada** (superficie-elevada): avisos, tooltips, botón lleno deshabilitado.
- **Indicador** (indicador): contenedor primario; la píldora de pestaña activa de la anfitriona.
- **Fondo informativo** (fondo-info): recuadro «esto aún no existe».
- **Bordes** (borde al 8 %, borde-fuerte al 20 %) y **contorno de segmentos** (contorno-segmentos, 0,8 px).
- **Texto**: blanco para titulares; texto-secundario para metadatos; **texto-tenue** para texto corrido de tercer nivel (5,3:1 sobre grafito, AA); **texto-terciario** solo para iconos decorativos y deshabilitados (3,4:1, no alcanza para texto); texto-sobre-azul para texto atenuado encima de cabecera o destacada.

### Alto contraste
`PaletaUtb` (extensión del tema) sustituye los neutros que cambian: texto-secundario #D9DBDF (12,3:1 sobre grafito), texto-tenue #CACCD1 (10,6:1), texto-terciario #B4B6BC (8,4:1, ya válido para texto), bordes al 45 % (4,4:1) y al 70 %, y velos oscuros más opacos sobre fotos y panorámicas. El contorno del selector pasa a blanco de 1,5 px. Se activa con «aumentar contraste» del sistema o con el ajuste del módulo; el azul, los colores de categoría y la cabecera no cambian. Los neutros que dependen del contraste se leen con `PaletaUtb.de(context)`, nunca de `ColoresUtb` directamente.

### Named Rules
**La Regla de la Medida.** Ningún tono entra al sistema sin haberse medido en una captura de la anfitriona. Un color nuevo se mide en `docs/capturas_utbapp/` o no existe. La paleta de alto contraste es la excepción: sale del cálculo de contraste, no de la anfitriona, que no tiene ese modo.

**La Regla del Tercer Gris.** texto-tenue (#8E9096) es el gris más oscuro permitido para texto. texto-terciario (#6E7076) es para iconos y estados deshabilitados, nunca para palabras que haya que leer.

**La Regla del Punto de Materia.** El color de categoría vive en un punto, un icono o una franja lateral de 4 px; nunca tiñe una tarjeta entera ni un titular.

## Typography

**Display Font:** Roboto (empaquetada, 400 / 500 / 700)
**Body Font:** Roboto
**Label Font:** Roboto, en versalitas espaciadas para sobretítulos

**Character:** La letra de la anfitriona, empaquetada para que iOS y el escritorio de desarrollo se vean igual que Android. Titulares en 700 con interletra ligeramente negativa; todo lo demás en 400/500.

### Hierarchy
- **Display**: título «Tour virtual» de la cabecera desplegada; se reduce a 22 en la barra compacta al colapsar.
- **Headline**: nombre del lugar en la tarjeta destacada.
- **Headline-sm**: encabezados de sección («Paradas») y nombre en la ficha.
- **Title-lg**: número de parada con cifras tabulares, en azul-claro y 700, formateado a dos dígitos («01») como las horas de la Agenda.
- **Title / Title-sm**: nombre de lugar en filas y tarjetas compactas.
- **Body-lg / Body / Body-sm**: descripciones; body-sm en texto-tenue para el extracto de dos líneas de cada parada.
- **Label**: botones (16, 500).
- **Sobretítulo**: versalitas de 12,5 con 1,6 de interletra, en texto-secundario o blanco translúcido sobre azul.

### Named Rules
**La Regla del Sobretítulo con Dato.** El sobretítulo es material nativo de la anfitriona («LUNES, 5 DE OCTUBRE», «PRÓXIMA CLASE») y aquí sigue su uso: nombra un estado o lleva un dato («SIGUIENTE PARADA», «CAMINANDO HACIA», «RECURSOS · PARADA 1 DE 4», nombre de la ruta · número de lugares). Nunca se pone como adorno sobre un titular que no lo necesita.

**La Regla de la Cifra Tabular.** Números de parada, contadores y tiempos de audio usan cifras tabulares para no bailar al cambiar.

## Layout

Columna única de teléfono con margen lateral de 18. Todo el módulo vive en un solo `CustomScrollView`: cabecera azul colapsable (276 desplegada, 64 compacta, más la barra de estado), selector «Recorrido | Mapa» de alto fijo 80 con márgenes, y debajo el contenido del modo.

Ritmo: 6 / 8 / 12 entre elementos de una tarjeta, 12 entre filas de parada, 20 de relleno en tarjetas, 18-22 en compactas y destacada. Objetivo táctil mínimo 48; el botón lleno mide 52. Densidad visual fija en todas las plataformas (estándar, con objetivo táctil acolchado) para que las capturas de escritorio no mientan.

En modo Mapa la cabecera se pliega sola y el desplazamiento se bloquea: los gestos de arrastre son del mapa. El mapa ocupa exactamente lo que queda bajo la cabecera compacta, en una tarjeta de radio amplio; la cámara se encuadra por la caja de los POI y prioriza cobertura sobre ajuste (sin bandas vacías). La lista de paradas es una línea de tiempo: riel de 22 a la izquierda, tarjeta a la derecha.

## Elevation & Depth

Profundidad sobre todo **tonal**: fondo → hoja → grafito → elevada, con bordes blancos al 8 % para separar tarjetas del negro. Las sombras aparecen solo donde algo flota sobre imagen o sobre azul, y son siempre difusas y negras o azules, nunca duras ni desplazadas en seco.

### Shadow Vocabulary
- **Resplandor de destacada** (`0 14px 36px` azul al 30 %): solo bajo la tarjeta de la próxima parada, como el carnet de la anfitriona.
- **Sombra de postal** (`-6px 12px 18px` negro al 40 %): la postal 3D inclinada.
- **Sombra flotante** (`0 3-4px 8-12px` negro al 25-50 %): insignias, píldoras y marcadores sobre el mapa o el visor.
- **Sombra de ficha** (desenfoque 24, negro al 40 %): la imagen principal de la ficha.

La profundidad real del módulo es **3D por código**: perspectiva 0,0011 en las transformaciones (postal inclinable, mapa entrando inclinado, postal girando desde el canto).

### Named Rules
**La Regla Plana por Defecto.** Tarjetas y hojas no llevan sombra; se separan por tono y borde. La sombra es para lo que flota sobre imagen o sobre azul.

## Shapes

Esquinas amplias y suaves por todas partes: 32 en la cabecera desplegada (interpola a 24 al colapsar, solo esquinas inferiores), 28 en hojas y tarjeta destacada, 26 en tarjetas, 22 en tarjetas compactas (paradas, tarjeta del mapa, audio), 18 en el recuadro informativo, 16 en postal y avisos. Todo lo pulsable que no es tarjeta es **píldora** (botones llenos, de texto, contorneados, selector, etiquetas) o **círculo** (botón flotante, marcadores, anillos). Los arcos concéntricos finos (1,2 px, blanco 3-8,5 %, centro fuera de pantalla arriba a la derecha, separación ≈30 dp) son la geometría de firma de toda superficie azul.

## Components

### Buttons
Táctiles y sobrios, siempre en píldora.
- **Lleno (principal):** azul de acción, texto blanco label, alto 52, relleno lateral 24. Deshabilitado: elevada con texto-terciario. Uno por pantalla.
- **Vidrio:** sobre superficies azules únicamente; blanco al 16 % con borde blanco al 26 %, alto mínimo 48, icono 20 opcional. Es la acción principal dentro de la tarjeta destacada («Empezar recorrido», «Continuar recorrido»).
- **Circular:** para flotar sobre imagen y sobre el visor 360; negro al 60 % (al 50 % se perdía sobre cielo y paredes claras) con borde blanco al 20 %, 48 de diámetro, icono al 46 %. Siempre con tooltip y etiqueta semántica.
- **Texto / contorneado:** azul-claro sin fondo; o blanco con borde-fuerte. Mínimo 48.
- **Pulsación:** salpicadura InkSparkle; las tarjetas pulsables se hunden a 0,982 en 180 ms (salvo con «Quitar animaciones»).

### Segmented control («Recorrido | Mapa»)
Copia del «Horario | Eventos» de Agenda: píldora con contorno gris fino (0,8 px), segmento elegido en azul lleno con palomita delante, el otro sobre negro, texto 16,5, alto 46. Es la navegación del módulo en lugar de pestañas.

### Chips
- **Etiqueta:** tinte del color al 14 % en píldora, icono 15 y texto en versalitas del mismo color («SUGERENCIA», «DATOS DE DEMOSTRACIÓN»). Informativa, no pulsable.

### Cards / Containers
- **Tarjeta grafito:** superficie, radio 26 (22 compacta), borde al 8 %, relleno 20, sin sombra, se hunde al pulsar.
- **Fila de parada:** tarjeta compacta con franja de categoría de 4 px a la izquierda, número de dos cifras en azul-claro, palomita verde si está visitada, chevron en texto-terciario; el estado viaja también en la etiqueta semántica.
- **Destacada:** gradiente diagonal destacada, radio 28, borde blanco al 16 %, resplandor azul, arcos propios; toda la tarjeta es objetivo táctil.
- **Recuadro informativo:** fondo-info, radio 18, icono azul-info. Es la forma de decir que algo falta o aún no existe: se lee como información, no como error.
- **Esqueleto:** bloque grafito con barrido de luz blanca al 6 % en 1,5 s; quieto con «Quitar animaciones».

### Navigation
Sin barra inferior propia. La cabecera azul es la navegación superior: flecha de volver solo si hay a dónde volver; al colapsar, el título se cruza de 34 a 22 en una franja corta del desplazamiento y el anillo de avance sube a la esquina como píldora. Hojas inferiores en color hoja, radio 28 arriba, asa 40×4 blanco al 33 %, barrera negra al 70 %. Las alturas de cabecera y selector crecen con la escala de texto; el título se encoge para caber si una traducción es larga.

### Botón de idioma y accesibilidad
Píldora de vidrio arriba a la derecha de la cabecera, con globo y código del idioma («ES», «JA»): se reconoce sin leer español. Abre la hoja de ajustes: idiomas escritos en su propia lengua, tamaño de texto con tres «A» y vista previa en vivo, e interruptores de contraste, movimiento, subtítulos y giroscopio, cada uno con su línea de explicación.

### Visor 360
Pie oscuro con la escena, sus puntos y, a la derecha, dos botones circulares para girar 45°. Debajo, «Desde aquí puedes ir a» con una píldora por salida (icono de caminar y destino): la misma navegación que los hotspots, sin tener que encontrarlos. Arriba a la derecha, el interruptor del giroscopio, que se rellena de azul cuando está activo.

### Anillo de avance
Trazo de 8 con puntas redondas en azul-claro sobre pista del mismo tono al 18 %; el arranque del trazo es más claro (barrido de gradiente). Se llena desde cero en 850 ms al aparecer. 76 en la cabecera desplegada, 34 compacto.

### Postal de escena
Recorte de la panorámica con borde blanco de 3 px, radio 16, inclinado en reposo y que responde al dedo (máximo 0,24 rad); insignia circular blanca de 34 con icono 360 en azul. Entra girando desde el canto.

### Marcadores del mapa
Gotas circulares con número o palomita, en el color de su estado; se **contraescalan** contra la cámara (factor 1/escala, acotado) para mantener tamaño constante en pantalla al acercar o alejar. El elegido crece a 1,14 en 180 ms.

### Motion
Un solo vocabulario: corto 180 ms, medio 320, largo 520, escena 850; curvas de salida cúbica y cuártica, vaivén cúbico para cámara y desplazamiento; nada rebota salvo los marcadores al caer. Entradas escalonadas de lista a 55 ms por elemento. La transición al visor 360 es una revelación circular. **Cada** efecto decorativo consulta `sinMovimiento()` y se reduce a fundido o corte.

## Do's and Don'ts

### Do:
- **Do** medir cualquier tono nuevo en `docs/capturas_utbapp/` antes de usarlo y añadirlo a `ColoresUtb`.
- **Do** usar texto-tenue (#8E9096) como el gris más bajo para texto corrido; texto-terciario solo para iconos y deshabilitados.
- **Do** dejar un único botón lleno azul por pantalla; sobre superficies azules la acción va en botón de vidrio.
- **Do** mantener todo objetivo táctil en 48 o más, y los botones flotantes con tooltip y etiqueta semántica.
- **Do** hacer que cada animación decorativa consulte `sinMovimiento()` y tenga una versión quieta.
- **Do** contraescalar contra la cámara todo lo que se dibuje sobre el mapa.
- **Do** expresar «esto aún no existe» con el recuadro informativo azul, no con un error rojo.
- **Do** escribir todo texto de interfaz en `lib/l10n/` y comprobar la pantalla con la letra al 200 %.
- **Do** dar `onTap` al `Semantics` que excluye la semántica de un botón: si no, el lector de pantalla no puede pulsarlo.

### Don't:
- **Don't** pintar una barra inferior propia: la pone la app anfitriona.
- **Don't** replicar el asistente robot de la anfitriona; es global de ella.
- **Don't** inventar una paleta, una tipografía o un radio que la anfitriona no tenga.
- **Don't** usar sombras duras o desplazadas en seco; las sombras del sistema son difusas.
- **Don't** usar sobretítulos sin dato ni estado detrás, ni teñir tarjetas enteras con color de categoría.
- **Don't** introducir movimiento continuo que no se pueda apagar (incluido el giro automático del visor 360).
- **Don't** fijar alturas que contengan texto sin derivarlas de la escala de texto.
- **Don't** dejar una acción que solo se haga arrastrando, pellizcando o moviendo el teléfono.
