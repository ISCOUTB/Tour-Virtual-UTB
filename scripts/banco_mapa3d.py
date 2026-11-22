#!/usr/bin/env python3
"""Banco del visor 3D en el navegador, sin teléfono.

Arma la misma página que model_viewer_plus sirve al WebView: su plantilla,
su `model-viewer.min.js`, el GLB preparado y los `visor.js` / `visor.css`
del módulo, con los atributos que pone `mapa_3d.dart`. Los lugares salen de
`scripts/datos/pois_campus.json` y `TourMapa3d` se sustituye por un registro.

    python -I scripts/banco_mapa3d.py            # http://127.0.0.1:8765/
    python -I scripts/banco_mapa3d.py --puerto 9000

Desde la consola de la página:

    await escena({alto: 360})                         // entrar e inclinar
    await escena({pasos: [['zoom', 2], ['girar', 45]]})
    registro                                          // mensajes hacia Dart

Requiere haber corrido `flutter pub get` en apps/mobile y
`scripts/preparar_modelo3d.py`. No reemplaza la prueba en el dispositivo:
los iconos de categoría son marcadores y el WebView real puede diferir.
"""
import argparse
import functools
import http.server
import json
import math
import re
import shutil
import tempfile
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
PAQUETE = RAIZ / "packages" / "tour_virtual"
DART = PAQUETE / "lib" / "ui" / "inicio" / "mapa_3d.dart"
GEO = PAQUETE / "lib" / "datos" / "georreferencia_3d.dart"


def carpeta_model_viewer_plus() -> Path:
    config = json.loads((RAIZ / "apps/mobile/.dart_tool/package_config.json").read_text(encoding="utf-8"))
    uri = next(p["rootUri"] for p in config["packages"] if p["name"] == "model_viewer_plus")
    return Path(uri.removeprefix("file:///"))


def constante(texto: str, nombre: str) -> float:
    return float(re.search(rf"static const {nombre} = ([-0-9.]+);", texto).group(1))


def atributos(dart: str, norte: float) -> str:
    bloque = re.search(r"return ModelViewer\((.*?)\n    \);", dart, re.S).group(1)

    def valor(nombre):
        m = re.search(rf"\b{nombre}: (.+?),\n", bloque)
        if not m:
            return None
        return m.group(1).strip().replace("${Georreferencia3d.norteCamara}", str(norte)).strip("'")

    pares = {
        "camera-orbit": "cameraOrbit", "min-camera-orbit": "minCameraOrbit",
        "max-camera-orbit": "maxCameraOrbit", "camera-target": "cameraTarget",
        "field-of-view": "fieldOfView", "min-field-of-view": "minFieldOfView",
        "max-field-of-view": "maxFieldOfView", "shadow-intensity": "shadowIntensity",
        "exposure": "exposure",
    }
    texto = " ".join(f'{html}="{v}"' for html, dart_ in pares.items() if (v := valor(dart_)) is not None)
    for bandera, html in (("cameraControls: true", "camera-controls"), ("disableTap: true", "disable-tap")):
        if bandera in bloque:
            texto += f" {html}"
    # Sin esto la invitación a girar de model-viewer mueve la cámara sola.
    if "InteractionPrompt.none" in bloque:
        texto += ' interaction-prompt="none"'
    return texto


def configuracion(geo: str) -> dict:
    ar, ai = constante(geo, "ar"), constante(geo, "ai")
    tx, tz = constante(geo, "tx"), constante(geo, "tz")
    olat, olng = constante(geo, "origenLat"), constante(geo, "origenLng")
    mlat, mlng = constante(geo, "metrosLat"), 111320 * math.cos(olat * math.pi / 180)
    norte = math.atan2(ai, -ar) * 180 / math.pi

    def modelo(lat, lng):
        u, v = -(lng - olng) * mlng, (lat - olat) * mlat
        return ar * u - ai * v + tx, ai * u + ar * v + tz

    pois = json.loads((RAIZ / "scripts/datos/pois_campus.json").read_text(encoding="utf-8"))
    paradas = [p for p in pois if p.get("es_parada")]
    icono = ("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E"
             "%3Ccircle cx='12' cy='12' r='7' fill='%23a0a2a8'/%3E%3C/svg%3E")
    lista = []
    for p in pois:
        if p.get("lat") is None:
            continue
        x, z = modelo(p["lat"], p["lng"])
        lista.append({
            "id": p["id"], "nombre": p["nombre"], "etiqueta": p["nombre"], "x": x, "z": z,
            "numero": paradas.index(p) + 1 if p in paradas else None,
            "visitado": False, **({} if p in paradas else {"icono": icono}),
        })
    return {
        "quieto": False, "contraste": False, "norte": norte, "descripcion": "Maqueta 3D del campus",
        "escalaTexto": 1, "color": "#2047cd", "colorClaro": "#5a76d9",
        "visitado": "#52c46a", "visitadoClaro": "#7bd38e",
        "seleccion": paradas[0]["id"] if paradas else None, "pois": lista,
    }


ESCENA = """async (escena = {}) => {
  const esperar = ms => new Promise(r => setTimeout(r, ms));
  for (let i = 0; i < 100 && !registro.some(r => r.tipo === 'listo'); i++) await esperar(100);
  const c = window.CONFIG.pois.filter(p => p.numero);
  const x = c.reduce((s, p) => s + p.x, 0) / c.length, z = c.reduce((s, p) => s + p.z, 0) / c.length;
  tour3d.vista(false, x, z, escena.alto ?? 440, false, true, 0);
  await esperar(200);
  if (escena.inclinar !== false) tour3d.vista(true, x, z, (escena.alto ?? 440) * 0.82, false, false, 900);
  await esperar(1100);
  for (const [orden, ...args] of escena.pasos ?? []) { tour3d[orden](...args); await esperar(900); }
  return registro.at(-1);
}"""


def main() -> None:
    argumentos = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    argumentos.add_argument("--puerto", type=int, default=8765)
    puerto = argumentos.parse_args().puerto

    mvp = carpeta_model_viewer_plus()
    dart, geo = DART.read_text(encoding="utf-8"), GEO.read_text(encoding="utf-8")
    config = configuracion(geo)
    salida = Path(tempfile.gettempdir()) / "banco_mapa3d"
    salida.mkdir(exist_ok=True)

    cuerpo = (
        f'<model-viewer src="model.glb" alt="Maqueta" {atributos(dart, config["norte"])} '
        'style="background-color: rgba(242, 239, 233, 255); min-hotspot-opacity: 1; max-hotspot-opacity: 1; ">\n'
        "</model-viewer>\n<script>\nwindow.registro = [];\n"
        "window.TourMapa3d = { postMessage(m) { const d = JSON.parse(m); registro.push(d);"
        " if (d.tipo === 'listo') tour3d.configurar(window.CONFIG); } };\n"
        f"window.CONFIG = {json.dumps(config, ensure_ascii=False)};\n</script>\n"
        f"<script>\n{(PAQUETE / 'assets/mapa3d/visor.js').read_text(encoding='utf-8')}\n</script>\n"
        f"<script>window.escena = {ESCENA};</script>"
    )
    plantilla = (mvp / "assets/template.html").read_text(encoding="utf-8")
    # El servidor de la app manda charset=UTF-8 en la cabecera; aquí va en la página.
    pagina = '<meta charset="utf-8">\n' + plantilla.replace(
        "/* other-css */", (PAQUETE / "assets/mapa3d/visor.css").read_text(encoding="utf-8")
    ).replace("<!-- body -->", cuerpo)
    (salida / "index.html").write_text(pagina, encoding="utf-8")
    shutil.copy(mvp / "assets/model-viewer.min.js", salida / "model-viewer.min.js")
    glb = PAQUETE / "assets/mapa3d/campus_elmapita.glb"
    if not glb.exists():
        raise SystemExit("Falta el modelo: python -I scripts/preparar_modelo3d.py")
    shutil.copy(glb, salida / "model.glb")

    servidor = http.server.ThreadingHTTPServer(
        ("127.0.0.1", puerto),
        functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(salida)),
    )
    print(f"Banco del visor 3D en http://127.0.0.1:{puerto}/ (Ctrl+C para salir)")
    servidor.serve_forever()


if __name__ == "__main__":
    main()
