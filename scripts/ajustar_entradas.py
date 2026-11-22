"""Genera la herramienta para ajustar a mano las entradas del campus.

El GPS de un teléfono junto a los edificios falla de 5 a 25 m aunque diga
±3 m: las medidas repetidas de una misma puerta salen separadas. Esta página
muestra, sobre la foto satelital, las medidas de todos los levantamientos de
cada entrada y un punto propuesto (la mediana de las medidas con ±8 m o
mejor). Quien estuvo en el campus arrastra el punto a la puerta real, lo
confirma y descarga `ajustes-entradas.json`. Ese archivo se pasa a
`grafo_campus.py` junto con los levantamientos y manda sobre las medidas.

Uso:

    python -I scripts/ajustar_entradas.py campo/*.json
    # abre campo/ajustar-entradas.html, ajusta, descarga ajustes-entradas.json

Si entre los JSON hay un ajustes-entradas.json anterior, la herramienta
arranca desde esos puntos (para que otra persona los revise) en vez de la
mediana de las medidas.
    python -I scripts/grafo_campus.py campo/*.json

La página usa Leaflet y las imágenes satelitales de Esri desde internet.
"""

from __future__ import annotations

import argparse
import glob
import hashlib
import json
import math
import statistics
from datetime import date
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
PLANO = RAIZ / "packages" / "tour_virtual" / "assets" / "campus_osm.geojson"
CATALOGO = RAIZ / "scripts" / "datos" / "pois_campus.json"
GRAFO = RAIZ / "packages" / "tour_virtual" / "assets" / "navegacion" / "grafo_campus.json"
PLANTILLA = RAIZ / "scripts" / "plantillas" / "ajustar_entradas.html"

# Medidas peores no entran a la propuesta (sí se dibujan).
PRECISION_PROPUESTA_M = 8.0
# Si las medidas de una entrada se separan más que esto, se revisa primero.
DISPERSION_REVISAR_M = 6.0
# Los puntos de un recorrido peores que esto no se dibujan.
PRECISION_RECORRIDO_M = 15.0


def metros(a: tuple[float, float], b: tuple[float, float]) -> float:
    lat = math.radians((a[0] + b[0]) / 2)
    return math.hypot((a[0] - b[0]) * 111_320, (a[1] - b[1]) * 111_320 * math.cos(lat))


def leer(rutas: list[str]) -> tuple[list[tuple[str, dict]], dict[tuple[int, str], dict]]:
    """Los levantamientos, cada uno con el nombre de quien midió. Acepta también
    el volcado de las preferencias de Android (la clave
    `flutter.levantamiento.datos` con el JSON adentro)."""
    archivos = []
    for patron in rutas:
        coincidencias = glob.glob(patron) if glob.has_magic(patron) else [patron]
        archivos += [Path(r) for r in coincidencias]
    salida, ajustes = [], {}
    for ruta in sorted(set(archivos)):
        datos = json.loads(ruta.read_text(encoding="utf-8-sig"))
        for clave in ("flutter.levantamiento.datos", "levantamiento.datos"):
            if clave in datos:
                datos = datos[clave]
                if isinstance(datos, str):
                    datos = json.loads(datos)
        if datos.get("formato") == "ajustes-entradas-1":
            # Un ajuste anterior: la herramienta arranca desde él, para revisarlo.
            for a in datos.get("entradas") or []:
                ajustes[(int(a["poi_id"]), a.get("nombre") or "")] = a
            continue
        if "accesos" not in datos:
            continue
        quien = (datos.get("medidor") or ruta.stem).strip().lower()
        salida.append((quien, datos))
    return salida, ajustes


def datos_herramienta(levantamientos: list[tuple[str, dict]], marcadas: set[str],
                      ajustes: dict[tuple[int, str], dict] | None = None) -> dict:
    ajustes = ajustes or {}
    grafo = json.loads(GRAFO.read_text(encoding="utf-8"))
    nodos = {n["id"]: (round(n["lat"], 7), round(n["lng"], 7)) for n in grafo["nodos"]}

    medidas: dict[tuple[int, str], list[dict]] = {}
    vistas = set()
    for quien, datos in levantamientos:
        for a in datos.get("accesos") or []:
            identidad = (a["poi_id"], a["nombre"], a["lat"], a["lng"], a["fecha"])
            if identidad in vistas:
                continue
            vistas.add(identidad)
            medidas.setdefault((int(a["poi_id"]), a["nombre"]), []).append(
                {"lat": a["lat"], "lng": a["lng"], "prec": a["precision"],
                 "quien": quien, "fecha": a["fecha"]})

    entradas = []
    for a in grafo["accesos"]:
        lista = medidas.get((a["poi_id"], a["nombre"]), [])
        buenas = [m for m in lista if m["prec"] <= PRECISION_PROPUESTA_M]
        motivo = []
        if a["nombre"] in marcadas:
            motivo.append("marcada para ajustar a mano")
        if buenas:
            propuesta = (statistics.median(m["lat"] for m in buenas),
                         statistics.median(m["lng"] for m in buenas))
            dispersion = max(metros(propuesta, (m["lat"], m["lng"])) for m in buenas)
            if dispersion > DISPERSION_REVISAR_M:
                motivo.append(f"medidas separadas hasta {dispersion:.0f} m")
        else:
            propuesta, dispersion = (a["lat"], a["lng"]), None
            motivo.append("sin medidas")
        anterior = ajustes.get((a["poi_id"], a["nombre"]))
        pin = None
        if anterior:
            # Se revisa lo que ya ajustó alguien: arranca ahí y no en la mediana.
            propuesta = (anterior["lat"], anterior["lng"])
            pin = anterior.get("pin")
            motivo.insert(0, "ajustada antes" + (f": {anterior['nota']}" if anterior.get("nota") else ""))
        entradas.append({
            "poi_id": a["poi_id"], "nombre": a["nombre"], "principal": a["principal"],
            "estimado": [a["lat"], a["lng"]], "propuesta": list(propuesta), "pin": pin,
            "dispersion": None if dispersion is None else round(dispersion, 1),
            "motivo": motivo, "medidas": lista,
        })

    plano = json.loads(PLANO.read_text(encoding="utf-8"))
    edificios = []
    for f in plano["features"]:
        if f["geometry"]["type"] != "Polygon":
            continue
        nombre = f["properties"].get("nombre") or f["properties"].get("name") or ""
        if nombre.startswith("Universidad"):
            continue
        edificios.append([nombre, [[round(c[1], 7), round(c[0], 7)]
                                   for c in f["geometry"]["coordinates"][0]]])

    recorridos, grabados = [], set()
    for _, datos in levantamientos:
        for r in datos.get("recorridos") or []:
            # Las copias «limpia» y «original» de un mismo teléfono repiten recorridos.
            if (r.get("etiqueta"), r.get("fecha")) in grabados:
                continue
            grabados.add((r.get("etiqueta"), r.get("fecha")))
            puntos = [[round(p["lat"], 7), round(p["lng"], 7)] for p in r.get("puntos", [])
                      if p.get("precision", 0) <= PRECISION_RECORRIDO_M]
            if len(puntos) >= 2:
                recorridos.append([r.get("etiqueta") or "", puntos])

    catalogo = json.loads(CATALOGO.read_text(encoding="utf-8"))
    return {
        "entradas": entradas,
        "pois": [{"id": p["id"], "nombre": p["nombre"], "lat": p["lat"], "lng": p["lng"]}
                 for p in catalogo if p.get("lat") is not None],
        "tramos": [[nodos[e["a"]], nodos[e["b"]], e["tipo"], bool(e.get("escalones"))]
                   for e in grafo["aristas"]],
        "edificios": edificios,
        "recorridos": recorridos,
        "generado": date.today().isoformat(),
        # Cambia si cambian los puntos de partida: el navegador no mezcla lo
        # guardado de una herramienta con otra.
        "firma": hashlib.sha1(json.dumps([e["propuesta"] for e in entradas]).encode()).hexdigest()[:10],
    }


def main() -> None:
    argumentos = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    argumentos.add_argument("levantamientos", nargs="+", help="JSON de la app de levantamiento")
    argumentos.add_argument("--salida", type=Path, help="HTML a escribir (por omisión, junto al primer JSON)")
    argumentos.add_argument("--marcar", action="append", default=[],
                            help="nombre de una entrada que alguien pidió ajustar a mano (se puede repetir)")
    a = argumentos.parse_args()
    levantamientos, ajustes = leer(a.levantamientos)
    if not levantamientos:
        raise SystemExit("No hay levantamientos con entradas medidas.")
    datos = datos_herramienta(levantamientos, set(a.marcar), ajustes)
    primero = Path(glob.glob(a.levantamientos[0])[0] if glob.has_magic(a.levantamientos[0]) else a.levantamientos[0])
    salida = a.salida or primero.parent / "ajustar-entradas.html"
    html = PLANTILLA.read_text(encoding="utf-8").replace(
        "__DATOS__", json.dumps(datos, ensure_ascii=False, separators=(",", ":")))
    salida.write_text(html, encoding="utf-8")
    revisar = sum(1 for e in datos["entradas"] if e["motivo"])
    print(f"{salida}: {len(datos['entradas'])} entradas, {revisar} para revisar con cuidado")


if __name__ == "__main__":
    main()
