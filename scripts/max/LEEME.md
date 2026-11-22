# Ilustraciones de Max

De aquí salen las poses de Max, la mascota de la UTB, que usa el módulo en
`packages/tour_virtual/assets/max/` (ver `lib/ui/comunes/ilustracion_max.dart`).

Son renders 2D generados con **Codex** (herramienta de generación de imágenes,
sesión de ChatGPT) a partir de la hoja de referencia del personaje, y limpiados
con estos scripts. Las referencias y los resultados en alta resolución no se
versionan ni se guardan en el repositorio local (se borraron el 2026-11-22):
para regenerar una pose hay que partir de la hoja oficial del personaje.

## Pasos

Todo se corre dentro de una carpeta de trabajo con los scripts y dos
referencias: `ref_max_frente.png` (la vista frontal ya limpia) y
`ref_max_4vistas.png` (la hoja de cuatro vistas del personaje).

1. **Generar las poses:** `bash poses.sh`, o una sola con
   `bash generar.sh <nombre> "<pose>" "<encuadre>"`. Se piden sobre magenta
   plano y con el pantalón sin letras: lo primero facilita el recorte y lo
   segundo evita el letrero deformado típico de la IA.
2. **Recortar y limpiar:** `python -I limpiar.py max_<n>.png limpias/max_<n>.webp <alto>`
   (1000 para cuerpo entero, 760 para torso). Quita el fondo por distancia de
   color, se queda con la figura y resta el reflejo magenta de los bordes.
   Guarda la caja de recorte en `<salida>.caja.json`. Con `.png` y alto `0`
   exporta a resolución nativa (para video y piezas gráficas).
3. **Parpadeo:** `bash ojos.sh <n>` pide a Codex la misma imagen con los ojos
   cerrados; `python -I parpadeo.py <n>` la alinea con el original (ECC afín),
   toma solo la zona de los ojos y la recorta con la misma caja que la base. El
   resultado (`max_<n>_ojos.webp`) es transparente salvo los ojos y se
   superpone exacto: el cuerpo nunca «salta» al parpadear.
4. Revisar a ojo los `control_*.png` y copiar los `.webp` a
   `packages/tour_virtual/assets/max/`. Una pose nueva se agrega también a
   `PoseMax`, con su proporción ancho/alto.

## Qué revisar en cada imagen

- Las letras «UTB» de la camiseta y que el pantalón no tenga texto ni emblema.
- Manos: dedos completos y sin piezas sueltas.
- Borde del recorte sobre negro y sobre el azul de la cabecera.
- En el parpadeo, que solo cambien los ojos (el script imprime el
  desplazamiento de la alineación y las zonas que tomó).
