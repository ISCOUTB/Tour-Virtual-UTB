#!/usr/bin/env bash
# Las nueve poses restantes, de tres en tres.
cd "$(dirname "$0")"
TORSO="Upper body only, from the top of the cap down to the waist, zoomed in; the character fills most of the image and is cut off at the waist."
ENTERO="Full body, standing, the whole figure visible from cap to sneakers."

g() { bash generar.sh "$@"; }

g max_senalando "Pointing with his right hand and index finger down and toward the LEFT side of the image (the viewer's left), as if showing something next to him, body turned slightly toward that side, smiling, eyes looking where he points." "$TORSO" &
g max_celebrando "Celebrating with both arms raised high above his head, hands open, beak wide open in a joyful cheer, a small happy jump with knees slightly bent." "$ENTERO" &
g max_pensativo "Thinking: one hand on his chin, the other arm crossed under it, eyes looking up and to the side, curious and calm expression." "$TORSO" &
wait
g max_apenado "Slightly embarrassed and apologetic: scratching the back of his head under the cap with one hand, sheepish smile, eyebrows raised." "$TORSO" &
g max_telefono "Holding a smartphone in one hand and showing its screen toward the viewer, the other hand pointing at the phone, enthusiastic expression. The phone screen is plain light blue, with no text." "$TORSO" &
g max_mapa "Holding an unfolded paper campus map with both hands in front of him, looking over the map at the viewer with a happy expression. The map is plain, with simple green and grey shapes and NO readable text." "$ENTERO" &
wait
g max_escuchando "Listening attentively: one hand cupped behind the side of his head as if to hear better, eyes closed with a content smile." "$TORSO" &
g max_pulgar "Giving a thumbs up with one hand toward the viewer and a friendly wink with one eye, confident smile." "$TORSO" &
g max_invitando "Inviting the viewer to follow him: one arm extended to his side with the open palm up, showing the way, body slightly turned, warm smile, looking at the viewer." "$ENTERO" &
wait
echo LOTE_TERMINADO
ls -1 *.png
