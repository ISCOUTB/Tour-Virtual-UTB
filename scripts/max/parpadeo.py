"""Capa de ojos cerrados de una pose, calzada exactamente sobre la base.

Uso: python -I parpadeo.py <nombre>
Lee max_<n>.png (original), max_<n>_ojos.png (edición de Codex) y
limpias/max_<n>.webp.caja.json (recorte de la base). Escribe
limpias/max_<n>_ojos.webp: transparente salvo los ojos, del mismo tamaño que
la base, y limpias/control_<n>_ojos.png para revisarla.

La edición puede moverse unos píxeles o retocar detalles que no se pidieron.
Por eso se alinea con el original (ECC afín) y solo se toma la zona que
cambió en la cabeza, con borde suave: el resto del cuerpo sale siempre de la
base y no puede «saltar» al parpadear.
"""
import json
import sys

import cv2
import numpy as np
from PIL import Image

n = sys.argv[1]
a = np.array(Image.open(f'max_{n}.png').convert('RGB'))
b = np.array(Image.open(f'max_{n}_ojos.png').convert('RGB'))
h, w, _ = a.shape
if b.shape != a.shape:
    b = cv2.resize(b, (w, h), interpolation=cv2.INTER_LANCZOS4)

ga = cv2.cvtColor(a, cv2.COLOR_RGB2GRAY).astype(np.float32) / 255
gb = cv2.cvtColor(b, cv2.COLOR_RGB2GRAY).astype(np.float32) / 255
matriz = np.eye(2, 3, dtype=np.float32)
try:
    _, matriz = cv2.findTransformECC(
        ga, gb, matriz, cv2.MOTION_AFFINE,
        (cv2.TERM_CRITERIA_EPS | cv2.TERM_CRITERIA_COUNT, 200, 1e-6), None, 5)
except cv2.error as e:
    print('ECC no convergió, sin alinear:', e)
bal = cv2.warpAffine(b, matriz, (w, h), flags=cv2.INTER_LINEAR + cv2.WARP_INVERSE_MAP,
                     borderMode=cv2.BORDER_REPLICATE)
print('desplazamiento', matriz[:, 2].round(2), 'escala', matriz[0, 0].round(4), matriz[1, 1].round(4))

dif = np.abs(a.astype(np.int16) - bal.astype(np.int16)).sum(2).astype(np.float32)
dif = cv2.GaussianBlur(dif, (0, 0), 3)
cambio = (dif > 60).astype(np.uint8)

# Solo los dos cambios más grandes de la mitad superior: los ojos.
cambio[int(h * 0.55):] = 0
k, lab, stats, cent = cv2.connectedComponentsWithStats(cambio, 8)
orden = sorted(range(1, k), key=lambda i: -stats[i, cv2.CC_STAT_AREA])[:2]
mascara = np.isin(lab, orden).astype(np.uint8)
print('zonas', [(tuple(stats[i, :4]), int(stats[i, 4])) for i in orden])
mascara = cv2.dilate(mascara, np.ones((15, 15), np.uint8))
suave = cv2.GaussianBlur(mascara.astype(np.float32), (0, 0), 5)

capa = np.dstack([bal, (np.clip(suave, 0, 1) * 255).astype(np.uint8)])
img = Image.fromarray(capa, 'RGBA')
datos = json.load(open(f'limpias/max_{n}.webp.caja.json'))
img = img.crop(tuple(datos['caja']))
base = Image.open(f'limpias/max_{n}.webp').convert('RGBA')
img = img.resize(base.size, Image.LANCZOS)
img.save(f'limpias/max_{n}_ojos.webp', 'WEBP', quality=90, method=6)

# Control: la cabeza con los ojos abiertos y cerrados, lado a lado.
compuesta = base.copy()
compuesta.alpha_composite(img)
alto_cabeza = int(base.height * 0.42)
par = Image.new('RGBA', (base.width * 2 + 16, alto_cabeza), (1, 4, 6, 255))
for i, im in enumerate([base, compuesta]):
    f = Image.new('RGBA', base.size, (1, 4, 6, 255))
    f.alpha_composite(im)
    par.paste(f.crop((0, 0, base.width, alto_cabeza)), (i * (base.width + 16), 0))
par.convert('RGB').save(f'limpias/control_{n}_ojos.png')
print('listo', img.size)
