#!/usr/bin/env python3
"""Catálogo de espacios interiores del campus, tomado de MAPSUTB.

MAPSUTB (https://github.com/ISCOUTB/AS_202620_mapsutb) es el proyecto de otro
equipo de la UTB que traza rutas a las zonas del campus. El profesor
orientador autorizó integrar su trabajo en el tour el 2026-11-23. De él se toma
el **catálogo** de `assets/data/zonas.json`: qué salones, laboratorios y
oficinas hay en cada edificio y en qué piso. No se toman sus coordenadas: las
nuestras son las entradas medidas en el campus el 20 y 21 de noviembre, y las
suyas son centros de edificio con A3 y A4 intercambiados (siguen el error de
OSM, ver docs/mapa-osm.md).

Escribe `packages/tour_virtual/assets/navegacion/espacios_campus.json`. Con él,
el buscador de la lista del tour encuentra un salón, un laboratorio o una
oficina, y «Cómo llegar» guía hasta la entrada del edificio que lo tiene y dice
en qué piso está. Cada edificio y, si hace falta, cada espacio o salón apunta
al lugar del catálogo (`pois_campus.json`) cuya entrada está en el grafo.

Uso:
    python -I scripts/espacios_mapsutb.py                 # descarga el commit fijado
    python -I scripts/espacios_mapsutb.py ruta/zonas.json # desde un archivo
"""

from __future__ import annotations

import argparse
import json
import sys
import urllib.request
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
CATALOGO = RAIZ / "scripts" / "datos" / "pois_campus.json"
SALIDA = RAIZ / "packages" / "tour_virtual" / "assets" / "navegacion" / "espacios_campus.json"

REPOSITORIO = "ISCOUTB/AS_202620_mapsutb"
# Último commit revisado. Al subirlo, revisar los cambios del catálogo y estas tablas.
COMMIT = "26543815f2e67a5033e1add02e615918484c162c"
URL = f"https://raw.githubusercontent.com/{REPOSITORIO}/{COMMIT}/assets/data/zonas.json"

# Zona de MAPSUTB → lugar del tour cuya entrada se usa para llegar.
ZONA_A_POI = {
    "a1": 6,          # Edificio A1
    "a2": 7,          # Edificio A2
    "a3": 8,          # Edificio A3 (por nombre: el letrero del edificio, no el polígono de OSM)
    "a4": 9,          # Edificio A4
    "a5": 10,         # Edificio A5
    "alcatraz": 11,   # Edificio Alcatraz
    "biblioteca": 1,  # Biblioteca
    "zonat": 4,       # Zona T
    "quid": 16,       # Centro de Cuidado Integral (QUID)
    # EDA2 no es un lugar del tour. MAPSUTB midió sus espacios dentro del
    # polígono que OSM da a Alcatraz, a unos 15 m de su entrada.
    "eda2": 11,
}
NOTAS = {"eda2": "junto al Edificio Alcatraz"}

# Espacios y salones que son un lugar del tour con entrada propia.
ESPACIO_A_POI = {
    "a1-esp-rectoria": 14,          # El Patio (Área Administrativa - Rectoría)
    "a5-esp-quanta": 26,         # Quanta Lab
    "zonat-esp-enfermeria": 3,      # Enfermería
    "zonat-esp-centro": 17,      # Centro Deportivo y Cultural
    "alcatraz-esp-placita": 25,     # La Placita
    "alcatraz-esp-salasestudio": 19,  # Salas de Estudio
}
SALON_A_POI = {
    "Solo Café": 24,  # El Mesón, en Alcatraz
}

# Sin ubicación en MAPSUTB (lat/lng 0): no hay a dónde guiar.
SIN_UBICACION = {"contenedores"}
# Las dos canchas ya son lugares del tour, con su nombre y su entrada.
YA_EN_EL_TOUR = {"espacioslibres"}


def cargar(origen: str | None) -> list[dict]:
    if origen:
        return json.loads(Path(origen).read_text(encoding="utf-8"))
    pedido = urllib.request.Request(URL, headers={"User-Agent": "utbtour-espacios/1.0"})
    with urllib.request.urlopen(pedido, timeout=60) as respuesta:
        return json.load(respuesta)


def _limpio(texto: str) -> str:
    return " ".join(texto.split())


def convertir(zonas: list[dict], pois: dict[int, dict]) -> dict:
    edificios, sin_ubicacion = [], []
    espacios_vistos: set[str] = set()
    for zona in zonas:
        if zona["id"] in YA_EN_EL_TOUR:
            continue
        if zona["id"] in SIN_UBICACION:
            sin_ubicacion.append({"zona": zona["nombre"],
                                  "espacios": [e["nombre"] for e in zona.get("espacios", [])]})
            continue
        poi = ZONA_A_POI.get(zona["id"])
        if poi is None:
            raise ValueError(f"Zona de MAPSUTB sin lugar del tour: {zona['id']} ({zona['nombre']}). "
                             "Agregarla a ZONA_A_POI o a SIN_UBICACION.")
        espacios = []
        for e in zona.get("espacios", []):
            if e["id"] in espacios_vistos:
                raise ValueError(f"Espacio repetido en MAPSUTB: {e['id']}")
            espacios_vistos.add(e["id"])
            salones = []
            for s in e.get("salones", []):
                salon = {"id": s["id"], "nombre": _limpio(s["nombre"])}
                if s["nombre"] in SALON_A_POI:
                    salon["poi_id"] = SALON_A_POI[s["nombre"]]
                salones.append(salon)
            espacio = {"id": e["id"], "nombre": _limpio(e["nombre"]), "tipo": e.get("tipo") or "",
                       "pisos": list(e.get("pisos", [])), "salones": salones}
            if e["id"] in ESPACIO_A_POI:
                espacio["poi_id"] = ESPACIO_A_POI[e["id"]]
            espacios.append(espacio)
        edificio = {"id": zona["id"], "nombre": _limpio(zona["nombre"]), "poi_id": poi,
                    "pisos": [{"id": p["id"], "nombre": _limpio(p["nombre"])} for p in zona.get("pisos", [])],
                    "espacios": espacios}
        if zona["id"] in NOTAS:
            edificio["nota"] = NOTAS[zona["id"]]
        edificios.append(edificio)

    usados = {e["poi_id"] for e in edificios}
    usados |= {x["poi_id"] for e in edificios for x in e["espacios"] if "poi_id" in x}
    usados |= {s["poi_id"] for e in edificios for x in e["espacios"] for s in x["salones"] if "poi_id" in s}
    faltan = sorted(usados - pois.keys())
    if faltan:
        raise ValueError(f"Lugares del tour que no existen en el catálogo: {faltan}")

    return {
        "formato": "espacios-campus-1",
        "fuente": f"MAPSUTB, github.com/{REPOSITORIO}, assets/data/zonas.json en {COMMIT[:7]}",
        "permiso": "Integrado con autorización del profesor orientador (2026-11-23).",
        "generado_por": "scripts/espacios_mapsutb.py",
        "edificios": edificios,
        "sin_ubicacion": sin_ubicacion,
    }


def main(origen: str | None) -> None:
    pois = {p["id"]: p for p in json.loads(CATALOGO.read_text(encoding="utf-8"))}
    salida = convertir(cargar(origen), pois)
    no_usados = [k for k in ESPACIO_A_POI
                 if not any(x["id"] == k for e in salida["edificios"] for x in e["espacios"])]
    if no_usados:
        raise ValueError(f"Espacios de ESPACIO_A_POI que ya no están en MAPSUTB: {no_usados}")
    SALIDA.parent.mkdir(parents=True, exist_ok=True)
    SALIDA.write_text(json.dumps(salida, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    espacios = sum(len(e["espacios"]) for e in salida["edificios"])
    salones = sum(len(x["salones"]) for e in salida["edificios"] for x in e["espacios"])
    print(f"{len(salida['edificios'])} edificios, {espacios} espacios, {salones} salones")
    for z in salida["sin_ubicacion"]:
        print(f"  sin ubicación: {z['zona']} ({', '.join(z['espacios'])})")
    print(SALIDA)


if __name__ == "__main__":
    argumentos = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    argumentos.add_argument("zonas", nargs="?", help="zonas.json de MAPSUTB (si no, se descarga)")
    a = argumentos.parse_args()
    try:
        main(a.zonas)
    except (ValueError, OSError) as error:
        print(error, file=sys.stderr)
        sys.exit(1)
