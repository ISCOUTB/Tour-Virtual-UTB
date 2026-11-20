#!/usr/bin/env python3
"""Grafo peatonal del Campus Ternera para la navegación (RF-27, AD-02).

Lee el plano que ya usa la app (`packages/tour_virtual/assets/campus_osm.geojson`,
derivado de OpenStreetMap) y el catálogo de lugares (`scripts/datos/pois_campus.json`),
y escribe `packages/tour_virtual/assets/navegacion/grafo_campus.json`:

- **nodos**: cada vértice de los senderos, vías y escaleras de OSM. Dos líneas
  que comparten un vértice quedan unidas ahí, como en OSM.
- **aristas**: cada tramo entre dos vértices, con sus metros (Haversine), el
  tipo de camino y si tiene escalones. `techado` queda en falso: OSM no lo
  dice y hay que marcarlo en el campus.
- **accesos**: por dónde se entra a cada lugar. Hoy salen de la posición del
  catálogo (centro del edificio o estimación) y van con `verificado: false`;
  la herramienta de levantamiento de la app de demostración mide los reales.
  Cada acceso se engancha al punto más cercano del camino partiendo ese tramo,
  para que la ruta termine en la puerta y no en el nodo más próximo.

Es una base de datos derivada de OSM: va bajo ODbL, como el plano.

Uso:  python -I scripts/grafo_campus.py [levantamiento.json ...]

Cada levantamiento (exportado por la herramienta de la app) reemplaza los
accesos estimados del lugar que mide por los medidos.
"""

from __future__ import annotations

import json
import math
import sys
from datetime import date
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
PLANO = RAIZ / "packages" / "tour_virtual" / "assets" / "campus_osm.geojson"
CATALOGO = RAIZ / "scripts" / "datos" / "pois_campus.json"
SALIDA = RAIZ / "packages" / "tour_virtual" / "assets" / "navegacion" / "grafo_campus.json"

# Declinación magnética en el campus (grados, positiva al este). El norte de
# la brújula está corrido ~7,7° al oeste del geográfico en Cartagena; el GPS
# usa el geográfico. Se recalibra con la herramienta de levantamiento.
DECLINACION = -7.7

# Segunda entrada de la Biblioteca: el otro polígono de OSM (ver docs/mapa-osm.md).
ACCESOS_EXTRA = {1: [("Biblioteca, segunda entrada", "way/1563809305")]}

CLASES = {"sendero": "sendero", "via": "via", "escalera": "escalera"}
R_TIERRA = 6371008.8


def metros(a: tuple[float, float], b: tuple[float, float]) -> float:
    (lat1, lng1), (lat2, lng2) = a, b
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp, dl = p2 - p1, math.radians(lng2 - lng1)
    h = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * R_TIERRA * math.asin(math.sqrt(h))


def clave(lat: float, lng: float) -> tuple[int, int]:
    return round(lat * 1e7), round(lng * 1e7)


def main(levantamientos: list[str]) -> None:
    plano = json.loads(PLANO.read_text(encoding="utf-8"))
    catalogo = json.loads(CATALOGO.read_text(encoding="utf-8"))

    nodos: dict[tuple[int, int], dict] = {}
    aristas: list[dict] = []

    def nodo(lat: float, lng: float, tipo: str = "camino") -> str:
        k = clave(lat, lng)
        if k not in nodos:
            nodos[k] = {"id": f"n{len(nodos)}", "lat": round(lat, 7), "lng": round(lng, 7), "tipo": tipo}
        return nodos[k]["id"]

    # Solo dentro del campus (con 15 m de margen para las entradas): el plano
    # trae también las calles públicas de alrededor y una ruta no debe salir.
    campus = next(f for f in plano["features"] if f["properties"].get("clase") == "campus")
    borde = [(lat, lng) for lng, lat in campus["geometry"]["coordinates"][0]]

    def dentro(p: tuple[float, float]) -> bool:
        lat, lng = p
        adentro = False
        for (la1, lo1), (la2, lo2) in zip(borde, borde[1:] + borde[:1]):
            if (la1 > lat) != (la2 > lat):
                x = lo1 + (lat - la1) * (lo2 - lo1) / (la2 - la1)
                if lng < x:
                    adentro = not adentro
        if adentro:
            return True
        return min(metros(p, q) for q in borde) < 15

    for f in plano["features"]:
        clase = f["properties"].get("clase")
        if clase not in CLASES or f["geometry"]["type"] != "LineString":
            continue
        puntos = [(lat, lng) for lng, lat in f["geometry"]["coordinates"]]
        for a, b in zip(puntos, puntos[1:]):
            if not (dentro(a) and dentro(b)):
                continue
            aristas.append({
                "a": nodo(*a), "b": nodo(*b),
                "metros": round(metros(a, b), 2),
                "tipo": CLASES[clase],
                "escalones": clase == "escalera",
                "techado": False,
                "osm": f["properties"].get("osm"),
            })

    por_id = {n["id"]: n for n in nodos.values()}

    def proyectar(p: tuple[float, float]) -> tuple[int, tuple[float, float], float]:
        """Arista más cercana a p y el punto de ella más próximo (plano local)."""
        lat0 = math.radians(p[0])
        def xy(q):
            return (math.radians(q[1]) * math.cos(lat0) * R_TIERRA, math.radians(q[0]) * R_TIERRA)
        px, py = xy(p)
        mejor = (-1, p, float("inf"))
        for i, e in enumerate(aristas):
            a, b = por_id[e["a"]], por_id[e["b"]]
            ax, ay = xy((a["lat"], a["lng"]))
            bx, by = xy((b["lat"], b["lng"]))
            dx, dy = bx - ax, by - ay
            largo2 = dx * dx + dy * dy
            t = 0.0 if largo2 == 0 else max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / largo2))
            qx, qy = ax + t * dx, ay + t * dy
            d = math.hypot(px - qx, py - qy)
            if d < mejor[2]:
                lat = a["lat"] + t * (b["lat"] - a["lat"])
                lng = a["lng"] + t * (b["lng"] - a["lng"])
                mejor = (i, (lat, lng), d)
        return mejor

    def enganchar(nombre: str, poi: dict, lat: float, lng: float, principal: bool,
                  verificado: bool, fuente: str) -> dict:
        i, punto, distancia = proyectar((lat, lng))
        e = aristas.pop(i)
        medio = nodo(*punto)
        for extremo in (e["a"], e["b"]):
            if extremo == medio:
                continue
            q = por_id[extremo]
            aristas.append({**e, "a": medio, "b": extremo,
                            "metros": round(metros(punto, (q["lat"], q["lng"])), 2)})
        por_id[medio] = nodos[clave(*punto)]
        puerta = nodo(lat, lng, "acceso")
        por_id[puerta] = nodos[clave(lat, lng)]
        if puerta != medio:
            aristas.append({"a": medio, "b": puerta, "metros": round(distancia, 2),
                            "tipo": "acceso", "escalones": False, "techado": False, "osm": None})
        return {"poi_id": poi["id"], "poi": poi["nombre"], "nombre": nombre,
                "lat": round(lat, 7), "lng": round(lng, 7), "nodo": puerta,
                "principal": principal, "verificado": verificado, "fuente": fuente,
                "metros_al_camino": round(distancia, 1)}

    medidos: dict[int, list[dict]] = {}
    for ruta in levantamientos:
        datos = json.loads(Path(ruta).read_text(encoding="utf-8"))
        for a in datos.get("accesos", []):
            medidos.setdefault(int(a["poi_id"]), []).append(a)

    poligonos = {f["properties"].get("osm"): f for f in plano["features"]
                 if f["geometry"]["type"] == "Polygon"}

    accesos = []
    for poi in catalogo:
        if poi.get("lat") is None:
            continue
        if poi["id"] in medidos:
            for j, m in enumerate(medidos[poi["id"]]):
                accesos.append(enganchar(m.get("nombre") or poi["nombre"], poi, m["lat"], m["lng"],
                                         j == 0, True, f"levantamiento ±{m.get('precision', '?')} m"))
            continue
        accesos.append(enganchar(poi["nombre"], poi, poi["lat"], poi["lng"], True, False,
                                 f"catálogo: {poi['fuente_posicion']}"))
        for nombre, osm in ACCESOS_EXTRA.get(poi["id"], []):
            anillo = poligonos[osm]["geometry"]["coordinates"][0]
            lat = sum(c[1] for c in anillo) / len(anillo)
            lng = sum(c[0] for c in anillo) / len(anillo)
            accesos.append(enganchar(nombre, poi, lat, lng, False, False, f"centro de OSM {osm}"))

    # Componentes conexos: una ruta solo existe dentro de uno.
    vecinos: dict[str, set[str]] = {n: set() for n in por_id}
    for e in aristas:
        vecinos[e["a"]].add(e["b"])
        vecinos[e["b"]].add(e["a"])
    componente, n_comp = {}, 0
    for inicio in vecinos:
        if inicio in componente:
            continue
        pila = [inicio]
        while pila:
            v = pila.pop()
            if v in componente:
                continue
            componente[v] = n_comp
            pila.extend(vecinos[v] - componente.keys())
        n_comp += 1
    tam = {}
    for c in componente.values():
        tam[c] = tam.get(c, 0) + 1
    principal_comp = max(tam, key=tam.get)
    sueltos = [a for a in accesos if componente[a["nodo"]] != principal_comp]

    # Solo el componente donde están los accesos: el resto son tramos sueltos
    # a los que ninguna ruta llega.
    vivos = {n for n, c in componente.items() if c == principal_comp}
    nodos = {k: n for k, n in nodos.items() if n["id"] in vivos}
    aristas = [e for e in aristas if e["a"] in vivos]

    salida = {
        "version": date.today().isoformat(),
        "licencia": "ODbL 1.0 — © colaboradores de OpenStreetMap",
        "generado_por": "scripts/grafo_campus.py",
        "declinacion": DECLINACION,
        "nodos": list(nodos.values()),
        "aristas": [{k: v for k, v in e.items() if k != "osm"} for e in aristas],
        "accesos": accesos,
    }
    SALIDA.parent.mkdir(parents=True, exist_ok=True)
    SALIDA.write_text(json.dumps(salida, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")

    total = sum(e["metros"] for e in aristas)
    print(f"{len(nodos)} nodos, {len(aristas)} aristas, {total:.0f} m de camino "
          f"(se descartan {n_comp - 1} componentes sueltos)")
    print(f"{len(accesos)} accesos, {sum(a['verificado'] for a in accesos)} verificados")
    for a in sorted(accesos, key=lambda a: -a["metros_al_camino"])[:6]:
        print(f"  {a['nombre']}: {a['metros_al_camino']} m hasta el camino")
    if sueltos:
        print("Accesos fuera del componente principal (sin ruta posible):")
        for a in sueltos:
            print("  ", a["nombre"])
    print(SALIDA, f"{SALIDA.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main(sys.argv[1:])
