"""Mueve los pines de los lugares a las posiciones ajustadas en el campus.

El pin de cada lugar (lat/lng del POI) está copiado en varios sitios, y todos
tienen que quedar iguales:

- scripts/datos/pois_campus.json y pois_campus.sql (los genera mapa_campus.py);
- scripts/mapa_campus.py: la `posicion` del catálogo, para que una nueva
  descarga de OSM no deshaga el ajuste;
- services/api/Data/ContenidoInicial.cs (datos iniciales de la API);
- packages/tour_virtual/lib/datos/repositorio_demo.dart (modo demo de la app);
- apps/admin_flutter/lib/data/repositories/poi_repository.dart (datos de
  ejemplo del panel).

La base de datos que ya está en uso no se toca: el SQL de carga solo inserta
lo que falta. Para ella se escribe scripts/datos/actualizar_posiciones.sql,
que alguien con acceso a Supabase corre una vez.

El pin va en la entrada principal ajustada, salvo que en la herramienta se
haya marcado que va aparte (por ejemplo, en el centro de una cancha).

Uso:

    python -I scripts/aplicar_pines.py scripts/datos/campo/ajustes-entradas.json
"""

from __future__ import annotations

import argparse
import json
import re
from datetime import date
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
DATOS = RAIZ / "scripts" / "datos"
CATALOGO_JSON = DATOS / "pois_campus.json"
CATALOGO_SQL = DATOS / "pois_campus.sql"
MAPA_CAMPUS = RAIZ / "scripts" / "mapa_campus.py"
CONTENIDO_API = RAIZ / "services" / "api" / "Data" / "ContenidoInicial.cs"
DEMO_APP = RAIZ / "packages" / "tour_virtual" / "lib" / "datos" / "repositorio_demo.dart"
DEMO_PANEL = RAIZ / "apps" / "admin_flutter" / "lib" / "data" / "repositories" / "poi_repository.dart"
SQL_ACTUALIZAR = DATOS / "actualizar_posiciones.sql"

# Por debajo de esto un pin no se mueve: es ruido del ajuste.
MOVIMIENTO_MINIMO_M = 1.0


def metros(a: tuple[float, float], b: tuple[float, float]) -> float:
    import math
    lat = math.radians((a[0] + b[0]) / 2)
    return math.hypot((a[0] - b[0]) * 111_320, (a[1] - b[1]) * 111_320 * math.cos(lat))


def reemplazar(texto: str, viejo: str, nuevo: str, archivo: Path, esperadas: int | None = None) -> str:
    veces = texto.count(viejo)
    if veces == 0 or (esperadas is not None and veces != esperadas):
        raise SystemExit(f"{archivo.name}: se esperaba encontrar {esperadas or 'al menos 1'} vez "
                         f"«{viejo}» y está {veces}. Revisa el archivo a mano.")
    return texto.replace(viejo, nuevo)


def pines(ajustes: list[dict]) -> dict[int, tuple[float, float, str]]:
    """Nuevo pin por lugar: el de la entrada principal, o el marcado aparte."""
    salida = {}
    for a in ajustes:
        if not a.get("principal"):
            continue
        pin = a.get("pin") or {"lat": a["lat"], "lng": a["lng"]}
        salida[int(a["poi_id"])] = (round(pin["lat"], 7), round(pin["lng"], 7), a.get("nota") or "")
    return salida


def main() -> None:
    argumentos = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    argumentos.add_argument("ajustes", type=Path, help="ajustes-entradas.json de la herramienta")
    a = argumentos.parse_args()
    ajustes = json.loads(a.ajustes.read_text(encoding="utf-8-sig"))["entradas"]
    nuevos = pines(ajustes)

    catalogo = json.loads(CATALOGO_JSON.read_text(encoding="utf-8"))
    sql = CATALOGO_SQL.read_text(encoding="utf-8")
    mapa = MAPA_CAMPUS.read_text(encoding="utf-8")
    api = CONTENIDO_API.read_text(encoding="utf-8")
    demo = DEMO_APP.read_text(encoding="utf-8")
    panel = DEMO_PANEL.read_text(encoding="utf-8")
    hoy = date.today().isoformat()

    actualizaciones = []
    for poi in catalogo:
        if poi["id"] not in nuevos or poi.get("lat") is None:
            continue
        lat, lng, nota = nuevos[poi["id"]]
        viejo = (poi["lat"], poi["lng"])
        movido = metros(viejo, (lat, lng))
        if movido < MOVIMIENTO_MINIMO_M:
            continue
        vlat, vlng = repr(viejo[0]), repr(viejo[1])
        nlat, nlng = repr(lat), repr(lng)

        poi["lat"], poi["lng"] = lat, lng
        poi["fuente_posicion"] = f"ajustado por el equipo sobre la foto satelital con el levantamiento ({hoy})"

        sql = reemplazar(sql, f"{vlat}, {vlng}", f"{nlat}, {nlng}", CATALOGO_SQL) \
            if f"{vlat}, {vlng}" in sql else sql
        sql = sql.replace(f'"Lat" = {vlat}, "Lng" = {vlng}', f'"Lat" = {nlat}, "Lng" = {nlng}')
        api = reemplazar(api, f"{vlat}, {vlng}", f"{nlat}, {nlng}", CONTENIDO_API, 1)
        demo = reemplazar(demo, f"lat: {vlat},", f"lat: {nlat},", DEMO_APP, 1)
        demo = reemplazar(demo, f"lng: {vlng},", f"lng: {nlng},", DEMO_APP, 1)

        # Panel: solo lat/lng. Su mapX/mapY es la posición en el mapa ilustrado
        # anterior, otra referencia: no se recalcula aquí.
        panel = reemplazar(panel, f"lat: {vlat},", f"lat: {nlat},", DEMO_PANEL, 1)
        panel = reemplazar(panel, f"lng: {vlng},", f"lng: {nlng},", DEMO_PANEL, 1)

        # Catálogo de mapa_campus.py: la entrada de este lugar pasa a «equipo».
        patron = re.compile(r'("nombre": "' + re.escape(poi["nombre"]) + r'",[^{}]*?"posicion": )(\([^)]*\)|None)')
        if not patron.search(mapa):
            raise SystemExit(f"{MAPA_CAMPUS.name}: no encuentro la posición de «{poi['nombre']}».")
        mapa = patron.sub(lambda m: f'{m.group(1)}("equipo", {nlat}, {nlng})', mapa, count=1)

        nombre_sql = poi["nombre"].replace("'", "''")
        actualizaciones.append(
            f'update "Pois" set "Lat" = {nlat}, "Lng" = {nlng} '
            f"where \"LugarId\" = 1 and \"Nombre\" = '{nombre_sql}';"
            f"  -- {movido:.0f} m{': ' + nota if nota else ''}")
        print(f"{poi['nombre']:34} {movido:6.1f} m")

    if not actualizaciones:
        print("Ningún pin se movió más de 1 m.")
        return

    CATALOGO_JSON.write_text(json.dumps(catalogo, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    CATALOGO_SQL.write_text(sql, encoding="utf-8")
    MAPA_CAMPUS.write_text(mapa, encoding="utf-8")
    CONTENIDO_API.write_text(api, encoding="utf-8")
    DEMO_APP.write_text(demo, encoding="utf-8")
    DEMO_PANEL.write_text(panel, encoding="utf-8")
    SQL_ACTUALIZAR.write_text(
        f"-- Pines ajustados con el levantamiento del campus ({hoy}).\n"
        "-- Generado por scripts/aplicar_pines.py. Correr una vez en el editor SQL de Supabase:\n"
        "-- la carga inicial (pois_campus.sql) no cambia lugares que ya existen.\n"
        "begin;\n" + "\n".join(actualizaciones) + "\ncommit;\n",
        encoding="utf-8")
    print(f"\n{len(actualizaciones)} pines movidos. Para la base en uso: {SQL_ACTUALIZAR.relative_to(RAIZ)}")


if __name__ == "__main__":
    main()
