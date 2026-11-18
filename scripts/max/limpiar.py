"""Recorta una pose de Max generada sobre magenta y la deja lista para la app.

Uso: python -I limpiar.py <entrada.png> <salida.webp> <alto_px> [control.png]

1. Alfa por distancia al color del fondo (mediana del borde), con transición
   suave: el borde del pelaje queda difuminado, no dentado.
2. Solo la figura: se descarta todo lo que no esté conectado a la más grande.
3. Sin reflejo magenta: en los píxeles del borde, el exceso de rojo+azul sobre
   el verde (la firma del magenta) se resta.
4. Recorte a la figura con margen y escala al alto pedido, en WebP.
"""
import sys

import cv2
import numpy as np
from PIL import Image

entrada, salida, alto = sys.argv[1], sys.argv[2], int(sys.argv[3])
control = sys.argv[4] if len(sys.argv) > 4 else None

rgb = np.array(Image.open(entrada).convert('RGB')).astype(np.float32)
h, w, _ = rgb.shape
borde = np.concatenate([rgb[:4].reshape(-1, 3), rgb[-4:].reshape(-1, 3),
                        rgb[:, :4].reshape(-1, 3), rgb[:, -4:].reshape(-1, 3)])
fondo = np.median(borde, 0)

d = np.linalg.norm(rgb - fondo, axis=2)
alfa = np.clip((d - 60) / (150 - 60), 0, 1)

# Solo la figura más grande (y lo que esté pegado a ella).
solido = (alfa > 0.5).astype(np.uint8)
n, lab, stats, _ = cv2.connectedComponentsWithStats(solido, 8)
if n > 1:
    mayor = 1 + int(np.argmax(stats[1:, cv2.CC_STAT_AREA]))
    zona = cv2.dilate((lab == mayor).astype(np.uint8), np.ones((9, 9), np.uint8))
    alfa = alfa * zona

# Reflejo magenta: rojo y azul por encima del verde a la vez.
r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
reflejo = np.clip(np.minimum(r, b) - g, 0, None)
# Solo cerca del borde (alfa parcial o pegado a él); el interior queda igual.
cerca = cv2.dilate((alfa < 0.98).astype(np.uint8), np.ones((7, 7), np.uint8)) > 0
peso = np.where(cerca, 1.0, 0.0)
rgb[..., 0] -= reflejo * peso
rgb[..., 2] -= reflejo * peso
rgb = np.clip(rgb, 0, 255)

rgba = np.dstack([rgb, alfa * 255]).astype(np.uint8)
img = Image.fromarray(rgba, 'RGBA')
caja = img.getbbox()
m = 12
caja = (max(caja[0] - m, 0), max(caja[1] - m, 0), min(caja[2] + m, w), min(caja[3] + m, h))
img = img.crop(caja)
import json
if not salida.endswith('.png'):
    json.dump({'caja': caja, 'alto': alto}, open(salida + '.caja.json', 'w'))
if alto > 0:
    escala = alto / img.height
    img = img.resize((round(img.width * escala), alto), Image.LANCZOS)
if salida.endswith('.png'):
    img.save(salida, 'PNG', optimize=True)
else:
    img.save(salida, 'WEBP', quality=88, method=6)

if control:
    lienzo = Image.new('RGBA', (img.width * 2 + 24, img.height), (40, 40, 40, 255))
    for i, color in enumerate([(1, 4, 6, 255), (30, 73, 211, 255)]):
        f = Image.new('RGBA', img.size, color)
        f.alpha_composite(img)
        lienzo.paste(f, (i * (img.width + 24), 0))
    lienzo.convert('RGB').save(control)
print(salida, img.size)
