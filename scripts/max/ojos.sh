#!/usr/bin/env bash
# Versión con los ojos cerrados de una pose, para el parpadeo.
# Uso: ojos.sh <nombre>   (lee max_<nombre>.png, escribe max_<nombre>_ojos.png)
set -u
cd "$(dirname "$0")"
n="$1"
read -r -d '' PROMPT <<EOF
Use your image generation tool to EDIT the attached image max_${n}.png and save the result as a PNG named max_${n}_ojos.png in the current working directory. Do not edit any other file.

Change ONLY the eyes: both eyes gently closed, as in the middle of a natural blink. The closed eyelids are soft white feathered skin, like the rest of the face, with a thin dark curved lash line where the eye was; keep the eyebrows exactly where they are.

Everything else must stay IDENTICAL to the input: the same pose, beak, mouth, cap, clothes, hands, colors, lighting, framing, image size and the same flat magenta background. Do not move, resize, crop, re-frame or redraw anything except the eyes.
EOF
codex exec --skip-git-repo-check -s workspace-write -i "max_${n}.png" \
  -o "max_${n}_ojos.log.md" "$PROMPT" > "max_${n}_ojos.codex.txt" 2>&1
echo "$n: $(ls -1 max_${n}_ojos.png 2>/dev/null || echo 'SIN IMAGEN')"
