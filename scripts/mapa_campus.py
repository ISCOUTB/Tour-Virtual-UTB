#!/usr/bin/env python3
"""Arma el plano del campus desde OpenStreetMap y ubica cada lugar de la UTB.

El mapa del modulo dejo de ser la ilustracion isometrica de la universidad: es
un plano dibujado por la app con los datos de OSM del Campus Ternera (way
68735397). Este script produce los tres archivos de los que depende:

- `apps/mobile/android/app/src/assets/campus_osm.geojson`: el plano. Edificios,
  vias, senderos, canchas y zonas verdes del campus y su entorno, sin puntos
  sueltos: los lugares con nombre van como POI, no como etiquetas del plano.
- `scripts/datos/pois_campus.json`: el catalogo de lugares con su lat/lng y de
  donde sale cada posicion.
- `scripts/datos/pois_campus.sql`: el mismo catalogo para la base compartida.
  Ver docs/mapa-osm.md antes de ejecutarlo.

Correcciones a OSM. Casi todo el detalle del campus lo subio un solo usuario
el 2026-09-30. OSM tiene los nombres de los edificios A3 y A4 intercambiados
(confirmado en campus el 2026-10-24); el plano lleva el nombre correcto. Si
alguien lo corrige en OSM, la correccion de aqui no cambia nada.

Posiciones. Las que OSM tiene se toman de OSM: centroide del poligono o el
nodo. Las que solo estan en la leyenda del mapa institucional
(`assets/Mapa_UTB.pdf`) se pasan a lat/lng con un ajuste afin: una ilustracion
isometrica de un terreno plano es una transformacion afin del plano, y ocho
marcadores de la leyenda tienen su edificio en OSM. El ajuste falla por 1 a
9 m en esos ocho puntos y, dejando cada uno fuera, por 9 m de mediana y 15 m
como maximo. Basta para dibujar un marcador, no para la realidad
aumentada, que necesita el punto exacto donde la persona se para: eso se
mide en campus (docs/plan-realidad-aumentada.md).

Las estaciones del guion que no estan ni en OSM ni en la leyenda las marco el
equipo sobre el mapa de OSM. Un lugar sin posicion se lista pero no se dibuja;
no se inventa un punto.

Licencia: los datos de OSM son ODbL. El plano es una base de datos derivada y
se distribuye con la app, asi que va bajo ODbL y la app muestra «©
colaboradores de OpenStreetMap». El PDF institucional no puede usarse como
fuente para editar OSM sin permiso de la universidad.

Uso:

    python scripts/mapa_campus.py                    # descarga de Overpass
    python scripts/mapa_campus.py --crudo osm.json   # reusa una descarga
"""

from __future__ import annotations

import argparse
import json
import math
import sys
import urllib.parse
import urllib.request
from datetime import date
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
PLANO = RAIZ / "apps" / "mobile" / "android" / "app" / "src" / "assets" / "campus_osm.geojson"
DATOS = RAIZ / "scripts" / "datos"
OVERPASS = "https://overpass-api.de/api/interpreter"

# Poligono del campus en OSM y caja del plano: la del poligono mas unos 40 m,
# para que las calles del borde no queden cortadas, salvo por el sur. Alli el
# poligono sigue 300 m por terreno sin edificar, y con el mapa a cobertura
# completa esa franja vacia se comia media pantalla y dejaba los lugares
# pequenos arriba. Se corta a unos 200 m del lugar mas al sur.
CAMPUS = "way/68735397"
SUR, OESTE, NORTE, ESTE = 10.36720, -75.46783, 10.37181, -75.46110

CORRECCIONES = {
    # OSM los tiene intercambiados respecto a la leyenda institucional, y la
    # leyenda es la correcta (verificado en campus el 2026-10-24).
    "way/1563809309": {"name": "Edificio A4"},
    "way/238258177": {"name": "Edificio A3"},
}

# Marcadores numerados de la leyenda de assets/Mapa_UTB.pdf, normalizados a la
# pagina (u hacia la derecha, v hacia abajo). Salen de la capa de texto del PDF
# con pymupdf; el numero esta centrado en el pin.
LEYENDA = {
    1: (0.2946, 0.5119),  # Auditorio
    2: (0.2378, 0.4754),  # Edificio A2
    3: (0.3525, 0.3552),  # Ed. Alcatraz
    4: (0.4550, 0.4949),  # Maloka
    5: (0.5188, 0.3841),  # Edificio A1
    6: (0.5934, 0.3412),  # Rectoria
    7: (0.4688, 0.2737),  # Biblioteca
    8: (0.7545, 0.5118),  # Centro de Cuidado Integral (QUID)
    9: (0.6951, 0.4607),  # Centro Deportivo y Cultural
    10: (0.7135, 0.5055),  # Enfermeria
    11: (0.6811, 0.2046),  # Edificio A3
    12: (0.5987, 0.1367),  # Edificio A4
    13: (0.7471, 0.1516),  # Edificio A5
    14: (0.4250, 0.7572),  # Cancha de futbol
    15: (0.5991, 0.6586),  # Cancha de softbol
    16: (0.5666, 0.2852),  # El Patio
}

# Marcador de la leyenda -> su edificio en OSM, ya con la correccion de A3/A4.
# La biblioteca es el poligono grande sin nombre; el que OSM llama «biblioteca»
# es su segundo acceso.
PARES_AJUSTE = {
    2: "way/1563809302",
    5: "way/97546323",
    7: "way/97546334",
    11: "way/238258177",
    12: "way/1563809309",
    13: "way/992473927",
    14: "way/97546338",
    15: "way/97546336",
}

TODAS = "externo,estudiante,docente"

# Catalogo de lugares. Los cinco primeros son las paradas del recorrido, con
# panoramica, y conservan su id. Los textos son los del guion institucional de
# estaciones (docs/STORYTELLING UTB.xlsx), literales; donde el guion solo trae
# notas de produccion la descripcion queda vacia, porque esas notas no son un
# texto para publicar. `posicion` dice de donde sale la lat/lng:
#   ("osm", id)           centroide del elemento de OSM
#   ("leyenda", n)        marcador n de la leyenda, por el ajuste afin
#   ("entre", id1, id2)   punto medio entre dos elementos de OSM
#   ("equipo", lat, lng)  marcado por el equipo sobre una captura del mapa de
#                         OSM, georreferenciada con 12 edificios y canchas
#                         (error mediano 0.7 m, maximo 2.3 m)
#   None                  sin posicion conocida
#
# Granja Solar (estacion 9, lejos del nucleo del campus) y Pasillo del exito
# (estacion 7, ubicacion sin confirmar) quedan fuera hasta que se sepa donde
# estan.
CATALOGO = [
    {
        "id": 1,
        "nombre": "Biblioteca",
        "nombres_previos": ["Biblioteca"],
        "categoria": "Recursos",
        "estacion": 5,
        "descripcion": "Más que una biblioteca: concentración, disciplina, "
        "tecnología y construcción de sueños.",
        "posicion": ("osm", "way/97546334"),
    },
    {
        "id": 2,
        "nombre": "Puente A3 - A5",
        "nombres_previos": ["Puente A3 - A5"],
        "categoria": "Academico",
        "estacion": 13,
        "descripcion": "Un punto que conecta espacios, personas y recorridos "
        "dentro del campus. Cada trayecto en la UTB hace parte de una "
        "experiencia que conecta tu presente con lo que quieres construir.",
        "posicion": ("entre", "way/238258177", "way/992473927"),
    },
    {
        "id": 3,
        "nombre": "Enfermería",
        "nombres_previos": ["Enfermeria", "Enfermería"],
        "categoria": "Bienestar",
        "estacion": 10,
        "descripcion": "Bienestar y cuidado integral. Un espacio para atender "
        "tu salud, recibir orientación y recordar que cuidar de ti también "
        "hace parte de la experiencia universitaria.",
        # En el edificio de la Zona T: su puerta da a la plazoleta. La leyenda
        # (marcador 10, por el ajuste afin) la ponia 20 m al oeste, sobre una
        # canchita.
        "posicion": ("equipo", 10.3692651, -75.4655196),
    },
    {
        "id": 4,
        "nombre": "Zona T",
        "nombres_previos": ["Zona T"],
        "categoria": "Servicios",
        "estacion": 12,
        "descripcion": "Punto de encuentro, pausa y conexión. Un lugar para "
        "compartir con otros estudiantes, conversar y disfrutar los espacios "
        "que hacen del campus una comunidad.",
        "posicion": ("osm", "way/1563809308"),
    },
    {
        "id": 5,
        "nombre": "Cancha de softbol",
        "nombres_previos": ["Cancha de softbol"],
        "categoria": "Deporte",
        "estacion": 11,
        "descripcion": "El campus también se vive en movimiento. Espacio para "
        "el deporte, la disciplina, el trabajo en equipo y las experiencias "
        "que se construyen más allá del aula.",
        # OSM la llama «Cancha de Beisbol» desde 2011; la leyenda, softbol.
        "posicion": ("osm", "way/97546336"),
    },
    # --- Lugares del campus, todavia sin panoramica ni medios ---------------
    {"nombre": "Edificio A1", "categoria": "Academico", "posicion": ("osm", "way/97546323")},
    {"nombre": "Edificio A2", "categoria": "Academico", "posicion": ("osm", "way/1563809302")},
    {"nombre": "Edificio A3", "categoria": "Academico", "posicion": ("osm", "way/238258177")},
    {"nombre": "Edificio A4", "categoria": "Academico", "posicion": ("osm", "way/1563809309")},
    {"nombre": "Edificio A5", "categoria": "Academico", "posicion": ("osm", "way/992473927")},
    {"nombre": "Edificio Alcatraz", "categoria": "Academico", "posicion": ("leyenda", 3)},
    {"nombre": "Auditorio", "categoria": "Cultura", "posicion": ("leyenda", 1)},
    {
        "nombre": "Plaza Maloca",
        "categoria": "Cultura",
        "estacion": 2,
        # La leyenda escribe «Maloka»; el guion, «Plaza Maloca».
        "posicion": ("leyenda", 4),
    },
    {"nombre": "Rectoría", "categoria": "Administrativo", "posicion": ("leyenda", 6)},
    {
        "nombre": "Laboratorio El Patio",
        "categoria": "Academico",
        "estacion": 6,
        "posicion": ("leyenda", 16),
    },
    {
        "nombre": "Centro de Cuidado Integral (QUID)",
        "categoria": "Bienestar",
        "posicion": ("leyenda", 8),
    },
    {
        "nombre": "Centro Deportivo y Cultural",
        "categoria": "Deporte",
        "posicion": ("leyenda", 9),
    },
    {"nombre": "Cancha de fútbol", "categoria": "Deporte", "posicion": ("osm", "way/97546338")},
    {"nombre": "Salas de estudio", "categoria": "Recursos", "posicion": ("osm", "way/1563809304")},
    {"nombre": "Cafetería", "categoria": "Servicios", "posicion": ("osm", "way/1563809303")},
    {"nombre": "Tienda", "categoria": "Servicios", "posicion": ("osm", "way/1563809310")},
    {"nombre": "Cajero automático", "categoria": "Servicios", "posicion": ("osm", "node/14234939099")},
    # --- Estaciones del guion marcadas por el equipo ------------------------
    {
        "nombre": "Pasillo de la conexión",
        "categoria": "Administrativo",
        "estacion": 1,
        # En la glorieta junto al Edificio A2, la llegada desde el SITM.
        "posicion": ("equipo", 10.3707567, -75.4659942),
    },
    {
        "nombre": "Solo Café",
        "categoria": "Servicios",
        "estacion": 3,
        "descripcion": "Espacio de conexión, ideas y conversaciones que "
        "también transforman la experiencia universitaria. Aquí nacen "
        "amistades, proyectos y networking.",
        # Sobre el edificio que OSM tiene como cafeteria (way/1563809317).
        "posicion": ("equipo", 10.3702285, -75.4655508),
    },
    {
        "nombre": "La Placita",
        "categoria": "Cultura",
        "estacion": 4,
        "descripcion": "Inspirada en las plazas del Caribe. Un espacio creado "
        "para compartir, desconectarse y sentirse en casa dentro de la UTB.",
        "posicion": ("equipo", 10.3704913, -75.4654840),
    },
    {
        "nombre": "QuantaLab",
        "categoria": "Academico",
        "estacion": 8,
        "descripcion": "Laboratorio de analítica, IA y datos. El futuro "
        "pertenece a quienes saben interpretar información y tomar decisiones.",
        # En el Edificio A5.
        "posicion": ("equipo", 10.3690907, -75.4646518),
    },
]


# --- Descarga ----------------------------------------------------------------


def descargar() -> dict:
    caja = f"{SUR},{OESTE},{NORTE},{ESTE}"
    consulta = f"""[out:json][timeout:90];
(
  nwr["building"]({caja});
  nwr["highway"]({caja});
  nwr["leisure"]({caja});
  nwr["landuse"]({caja});
  nwr["natural"]({caja});
  nwr["amenity"]({caja});
  nwr["waterway"]({caja});
  {CAMPUS.replace("/", "(")});
);
out tags geom;"""
    datos = urllib.parse.urlencode({"data": consulta}).encode()
    pedido = urllib.request.Request(
        OVERPASS, data=datos, headers={"User-Agent": "utbtour-mapa-campus/1.0"}
    )
    with urllib.request.urlopen(pedido, timeout=120) as respuesta:
        return json.load(respuesta)


# --- Geometria ---------------------------------------------------------------

LAT0 = (SUR + NORTE) / 2
M_POR_GRADO_LAT = 110_574.0
M_POR_GRADO_LNG = 111_320.0 * math.cos(math.radians(LAT0))


def a_metros(lat: float, lng: float) -> tuple[float, float]:
    """Plano local equirectangular. A 650 m de campus el error es de cm."""
    return ((lng - OESTE) * M_POR_GRADO_LNG, (lat - SUR) * M_POR_GRADO_LAT)


def a_latlng(x: float, y: float) -> tuple[float, float]:
    return (SUR + y / M_POR_GRADO_LAT, OESTE + x / M_POR_GRADO_LNG)


def centroide(elemento: dict) -> tuple[float, float]:
    if elemento["type"] == "node":
        return elemento["lat"], elemento["lon"]
    puntos = [a_metros(p["lat"], p["lon"]) for p in elemento["geometry"]]
    if puntos[0] != puntos[-1]:
        x = sum(p[0] for p in puntos) / len(puntos)
        y = sum(p[1] for p in puntos) / len(puntos)
        return a_latlng(x, y)
    area = cx = cy = 0.0
    for (x0, y0), (x1, y1) in zip(puntos, puntos[1:]):
        c = x0 * y1 - x1 * y0
        area += c
        cx += (x0 + x1) * c
        cy += (y0 + y1) * c
    area /= 2
    return a_latlng(cx / (6 * area), cy / (6 * area))


def resolver(matriz: list[list[float]]) -> list[float]:
    """Gauss-Jordan sobre una matriz aumentada pequena."""
    n = len(matriz)
    for i in range(n):
        pivote = max(range(i, n), key=lambda f: abs(matriz[f][i]))
        matriz[i], matriz[pivote] = matriz[pivote], matriz[i]
        for f in range(n):
            if f != i:
                k = matriz[f][i] / matriz[i][i]
                matriz[f] = [a - k * b for a, b in zip(matriz[f], matriz[i])]
    return [matriz[i][n] / matriz[i][i] for i in range(n)]


def ajustar_leyenda(elementos: dict) -> tuple:
    """Ajuste afin (x, y) en metros -> (u, v) de la leyenda, por minimos
    cuadrados. Devuelve la inversa, de (u, v) a lat/lng, y los residuos."""
    filas = []
    for marcador, osm in PARES_AJUSTE.items():
        x, y = a_metros(*centroide(elementos[osm]))
        filas.append(((x, y, 1.0), LEYENDA[marcador], marcador))

    coeficientes = []
    for eje in (0, 1):
        normal = [[0.0] * 4 for _ in range(3)]
        for a, b, _ in filas:
            for i in range(3):
                for j in range(3):
                    normal[i][j] += a[i] * a[j]
                normal[i][3] += a[i] * b[eje]
        coeficientes.append(resolver(normal))
    (a, b, c), (d, e, f) = coeficientes
    det = a * e - b * d

    def inversa(u: float, v: float) -> tuple[float, float]:
        x = (e * (u - c) - b * (v - f)) / det
        y = (a * (v - f) - d * (u - c)) / det
        return a_latlng(x, y)

    residuos = {}
    for (x, y, _), uv, marcador in filas:
        xi, yi = a_metros(*inversa(*uv))
        residuos[marcador] = math.hypot(xi - x, yi - y)
    return inversa, residuos


# --- Plano -------------------------------------------------------------------


def clase_de(etiquetas: dict) -> str | None:
    hw = etiquetas.get("highway")
    if etiquetas.get("amenity") == "university":
        return "campus"
    if "building" in etiquetas:
        return "edificio"
    if hw and etiquetas.get("area") == "yes":
        return "plazoleta"
    if hw == "steps":
        return "escalera"
    if hw in ("footway", "path", "pedestrian", "cycleway", "corridor", "track"):
        return "sendero"
    if hw in ("trunk", "primary", "secondary", "tertiary", "trunk_link",
              "primary_link", "secondary_link", "tertiary_link"):
        return "via_principal"
    if hw in ("residential", "unclassified", "service", "living_street", "road"):
        return "via"
    if etiquetas.get("leisure") in ("pitch", "track", "sports_centre"):
        return "cancha"
    if etiquetas.get("amenity") in ("parking", "motorcycle_parking", "bicycle_parking"):
        return "parqueadero"
    if etiquetas.get("natural") in ("water",) or "waterway" in etiquetas:
        return "agua"
    if etiquetas.get("natural") in ("wood", "tree_row") or etiquetas.get("landuse") == "forest":
        return "arboles"
    if (
        etiquetas.get("landuse") in ("grass", "meadow", "recreation_ground", "village_green")
        or etiquetas.get("leisure") in ("park", "garden")
        or etiquetas.get("natural") in ("grassland", "scrub", "heath")
    ):
        return "verde"
    if etiquetas.get("landuse") in ("residential", "commercial", "industrial", "retail"):
        return "zona"
    return None


def geometrias(elemento: dict) -> list[list[tuple[float, float]]]:
    """Anillos o lineas del elemento, en [lng, lat]. De las multipoligonales
    solo se toman los anillos exteriores: los huecos no se ven a esta escala."""
    if elemento["type"] == "way":
        return [[(p["lon"], p["lat"]) for p in elemento["geometry"]]]
    if elemento["type"] == "relation":
        return [
            [(p["lon"], p["lat"]) for p in m["geometry"]]
            for m in elemento.get("members", [])
            if m.get("role") == "outer" and m.get("geometry")
        ]
    return []


def plano(crudo: dict) -> dict:
    rasgos = []
    vistos = set()
    for e in crudo["elements"]:
        clave = f"{e['type']}/{e['id']}"
        if clave in vistos or e["type"] == "node":
            continue
        vistos.add(clave)
        etiquetas = {**e.get("tags", {}), **CORRECCIONES.get(clave, {})}
        clase = clase_de(etiquetas)
        if clase is None:
            continue
        for linea in geometrias(e):
            cerrada = len(linea) > 3 and linea[0] == linea[-1]
            lineal = clase in ("sendero", "escalera", "via", "via_principal")
            es_area = cerrada and (not lineal or etiquetas.get("area") == "yes")
            coords = [[round(lng, 7), round(lat, 7)] for lng, lat in linea]
            propiedades = {"osm": clave, "clase": clase}
            if "name" in etiquetas:
                propiedades["nombre"] = etiquetas["name"]
            rasgos.append(
                {
                    "type": "Feature",
                    "properties": propiedades,
                    "geometry": {
                        "type": "Polygon" if es_area else "LineString",
                        "coordinates": [coords] if es_area else coords,
                    },
                }
            )
    return {
        "type": "FeatureCollection",
        "bbox": [OESTE, SUR, ESTE, NORTE],
        "properties": {
            "fuente": "© colaboradores de OpenStreetMap, ODbL 1.0",
            "generado": date.today().isoformat(),
            "osm_base": crudo.get("osm3s", {}).get("timestamp_osm_base"),
            "correcciones": CORRECCIONES,
        },
        "features": rasgos,
    }


# --- Catalogo ----------------------------------------------------------------


def catalogo(crudo: dict) -> tuple[list[dict], dict]:
    elementos = {f"{e['type']}/{e['id']}": e for e in crudo["elements"]}
    inversa, residuos = ajustar_leyenda(elementos)

    lugares = []
    siguiente = 6
    for entrada in CATALOGO:
        lugar = dict(entrada)
        if "id" not in lugar:
            lugar["id"] = siguiente
            siguiente += 1
        posicion = lugar.pop("posicion")
        lat = lng = None
        match posicion:
            case ("osm", osm):
                lat, lng = centroide(elementos[osm])
                fuente = f"OSM {osm}"
            case ("leyenda", n):
                lat, lng = inversa(*LEYENDA[n])
                fuente = f"leyenda {n}, ajuste afin (~9 m)"
            case ("entre", uno, otro):
                a, b = centroide(elementos[uno]), centroide(elementos[otro])
                lat, lng = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
                fuente = f"punto medio entre OSM {uno} y {otro}"
            case ("equipo", lat, lng):
                fuente = "marcado por el equipo sobre el mapa de OSM (2026-10-24)"
            case None:
                fuente = "sin posicion conocida"
        lugar.update(
            lat=None if lat is None else round(lat, 7),
            lng=None if lng is None else round(lng, 7),
            fuente_posicion=fuente,
            audiencias=TODAS,
            es_parada=lugar["id"] <= 5,
        )
        lugar.setdefault("descripcion", None)
        lugares.append(lugar)
    return lugares, residuos


def texto_sql(valor) -> str:
    if valor is None:
        return "null"
    if isinstance(valor, bool):
        return "true" if valor else "false"
    if isinstance(valor, (int, float)):
        return repr(valor)
    return "'" + str(valor).replace("'", "''") + "'"


def sql(lugares: list[dict]) -> str:
    lineas = [
        "-- Generado por scripts/mapa_campus.py. No editar a mano.",
        "--",
        "-- Pone lat/lng y los textos del guion a las cinco paradas, y crea los",
        "-- demas lugares del campus si no existen (se reconocen por nombre).",
        "-- No toca escenas, hotspots ni medios. Se puede ejecutar mas de una vez.",
        "begin;",
        "",
    ]
    for lugar in lugares:
        campos = {
            '"Nombre"': lugar["nombre"],
            '"Categoria"': lugar["categoria"],
            '"Descripcion"': lugar["descripcion"],
            '"Lat"': lugar["lat"],
            '"Lng"': lugar["lng"],
        }
        if lugar["es_parada"]:
            asignaciones = ", ".join(f"{k} = {texto_sql(v)}" for k, v in campos.items())
            previos = ", ".join(texto_sql(n) for n in lugar["nombres_previos"])
            lineas.append(
                f'update "Pois" set {asignaciones}\n'
                f' where "LugarId" = 1 and "Nombre" in ({previos});'
            )
        else:
            columnas = ", ".join(['"LugarId"', *campos, '"Audiencias"', '"Activo"'])
            valores = ", ".join(
                ["1", *(texto_sql(v) for v in campos.values()),
                 texto_sql(lugar["audiencias"]), "true"]
            )
            lineas.append(
                f'insert into "Pois" ({columnas})\n'
                f"select {valores}\n"
                f' where not exists (select 1 from "Pois" where "LugarId" = 1'
                f' and "Nombre" = {texto_sql(lugar["nombre"])});'
            )
        lineas.append("")
    lineas.append("commit;")
    return "\n".join(lineas) + "\n"


def main() -> int:
    argumentos = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    argumentos.add_argument("--crudo", type=Path, help="respuesta de Overpass ya descargada")
    argumentos.add_argument("--guardar-crudo", type=Path, help="guarda la descarga para reusarla")
    opciones = argumentos.parse_args()

    if opciones.crudo:
        crudo = json.loads(opciones.crudo.read_text(encoding="utf-8"))
    else:
        crudo = descargar()
        if opciones.guardar_crudo:
            opciones.guardar_crudo.write_text(json.dumps(crudo), encoding="utf-8")

    geojson = plano(crudo)
    PLANO.write_text(
        json.dumps(geojson, ensure_ascii=False, separators=(",", ":")), encoding="utf-8"
    )
    lugares, residuos = catalogo(crudo)
    DATOS.mkdir(parents=True, exist_ok=True)
    (DATOS / "pois_campus.json").write_text(
        json.dumps(lugares, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    (DATOS / "pois_campus.sql").write_text(sql(lugares), encoding="utf-8")

    print(f"plano: {len(geojson['features'])} rasgos, {PLANO.stat().st_size / 1024:.0f} KB")
    print("residuo del ajuste por marcador (m):",
          ", ".join(f"{k}: {v:.1f}" for k, v in sorted(residuos.items())))
    sin = [l["nombre"] for l in lugares if l["lat"] is None]
    print(f"lugares: {len(lugares)}, sin posicion: {', '.join(sin)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
