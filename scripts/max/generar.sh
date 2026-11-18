#!/usr/bin/env bash
# Genera una pose de Max con Codex (herramienta de generación de imágenes).
# Uso: generar.sh <nombre> "<pose>" "<encuadre>"
set -u
cd "$(dirname "$0")"
nombre="$1"; pose="$2"; encuadre="$3"

read -r -d '' PROMPT <<EOF
Use your image generation tool to create exactly ONE new image, then save it as a PNG file named ${nombre}.png in the current working directory. Do not edit any other file.

The two attached images are the reference of the character: Max, the mascot of Universidad Tecnológica de Bolívar (UTB). ref_max_frente.png is the main reference; ref_max_4vistas.png shows front, side and back views.

Draw the SAME character, faithful to the references:
- white fluffy eagle with layered white feathers, big brown eyes, yellow beak with a friendly smile;
- royal blue baseball cap worn backwards;
- royal blue T-shirt with the outlined letters "UTB" on the chest, in light blue;
- navy blue track pants with one cyan side stripe; NO text, NO letters and NO emblem on the pants;
- white sneakers with green stripes;
- same soft 3D render style, same proportions, same colors and lighting as the reference.

Pose: ${pose}
Framing: ${encuadre}

Background: a perfectly flat, solid magenta (#FF00FF) background, with no gradient, no floor, no ground shadow, no other objects, no text and no watermark. Leave a small margin around the character; nothing may be cut off except where the framing says so.

Size: portrait, at least 1024 pixels tall.
EOF

codex exec --skip-git-repo-check -s workspace-write \
  -i ref_max_frente.png -i ref_max_4vistas.png \
  -o "${nombre}.log.md" "$PROMPT" > "${nombre}.codex.txt" 2>&1
echo "salida $? -> $(ls -1 ${nombre}.png 2>/dev/null || echo 'SIN IMAGEN')"
