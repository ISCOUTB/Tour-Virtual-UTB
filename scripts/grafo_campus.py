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

Uso:
    python -I scripts/grafo_campus.py [levantamiento.json ...]
    python -I scripts/grafo_campus.py --informe [--geojson recorridos.geojson] levantamiento.json ...

Los levantamientos son los JSON que exporta la app de levantamiento
(`apps/levantamiento`). Se pueden pasar varios (un archivo por teléfono o por
día): se juntan. Con ellos:

- **Entradas:** una entrada medida reemplaza a la estimada con el mismo
  nombre; una con nombre nuevo se agrega. Queda `verificado: true` solo si
  pasa el criterio del plan (dos medidas en días distintos, a 5 m o menos
  entre sí, cada una con precisión de 5 m o mejor). Si no lo pasa pero hay
  medidas, se usan con `verificado: false`: siguen siendo mejores que el
  centro del edificio.
- **Tramos:** cada tramo marcado en el campus cambia el tipo, los escalones y
  el techado del tramo de OSM más cercano (a 8 m o menos).

Con `--informe` no se escribe el grafo: se imprime en Markdown el estado del
levantamiento (entradas aceptadas y pendientes, norte de las panorámicas,
error de la brújula frente a RNF-27, pruebas de la guía) y, con `--geojson`,
se escriben los recorridos grabados para revisarlos en geojson.io o JOSM.
"""

from __future__ import annotations

import argparse
import glob
import json
import math
import statistics
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


# Criterio de aceptación de una entrada (docs/plan-realidad-aumentada.md, fase 0).
PRECISION_ACEPTABLE_M = 5.0
TOLERANCIA_ENTRE_DIAS_M = 5.0
# Una medida con peor precisión no se usa ni siquiera como provisional.
PRECISION_PROVISIONAL_M = 15.0
# Un tramo marcado se aplica al tramo de OSM más cercano solo dentro de esto.
RADIO_MARCA_TRAMO_M = 8.0
# RNF-27: error de orientación de 10° como máximo.
ERROR_RUMBO_MAX = 10.0
# AD-03: radio de llegada.
RADIO_LLEGADA_M = 10.0

TIPOS_TRAMO = {"sendero", "via", "escalera", "rampa", "pasillo", "acceso"}


def cargar_levantamientos(rutas: list[str]) -> dict[str, list]:
    """Junta varios JSON de la app. Acepta también el formato 1 (solo
    accesos, nortes y recorridos)."""
    juntos: dict[str, list] = {k: [] for k in
                               ("accesos", "nortes", "tramos", "brujula", "pruebas", "recorridos")}
    archivos = set()
    for patron in rutas:
        # PowerShell pasa los comodines literalmente a los programas nativos.
        coincidencias = glob.glob(patron) if glob.has_magic(patron) else [patron]
        if not coincidencias:
            raise FileNotFoundError(f"No hay levantamientos que coincidan con {patron}")
        archivos.update(Path(ruta).resolve() for ruta in coincidencias)
    vistos = {k: set() for k in juntos}
    for ruta in sorted(archivos):
        datos = json.loads(Path(ruta).read_text(encoding="utf-8"))
        for k in juntos:
            # Cada exportación contiene también los días anteriores. No contar
            # dos veces una medida presente en varias copias del mismo teléfono.
            for registro in datos.get(k) or []:
                identidad = json.dumps(registro, sort_keys=True, ensure_ascii=False)
                if identidad not in vistos[k]:
                    juntos[k].append(registro)
                    vistos[k].add(identidad)
    for k in juntos:
        juntos[k].sort(key=lambda d: d.get("fecha", ""))
    return juntos


def _promedio(medidas: list[dict]) -> tuple[float, float, float]:
    """Promedio ponderado por 1/precisión²: las lecturas buenas pesan más."""
    pesos = [1 / max(m["precision"], 0.5) ** 2 for m in medidas]
    total = sum(pesos)
    lat = sum(m["lat"] * w for m, w in zip(medidas, pesos)) / total
    lng = sum(m["lng"] * w for m, w in zip(medidas, pesos)) / total
    return lat, lng, statistics.fmean(m["precision"] for m in medidas)


def evaluar_acceso(medidas: list[dict]) -> dict:
    """Decide si las medidas de una entrada pasan el criterio de la fase 0.

    Devuelve `estado` ('aceptado', 'sin_confirmar' o 'sin_medidas_utiles'),
    el punto a usar, la precisión media, la distancia entre las dos mejores
    medidas de días distintos y un `motivo` legible. La app aplica la misma
    regla para mostrar el estado en el campus (datos_levantamiento.dart).
    """
    buenas = [m for m in medidas if m["precision"] <= PRECISION_ACEPTABLE_M]
    mejor_par = None
    for i, a in enumerate(buenas):
        for b in buenas[i + 1:]:
            if a["fecha"][:10] == b["fecha"][:10]:
                continue
            d = metros((a["lat"], a["lng"]), (b["lat"], b["lng"]))
            if mejor_par is None or d < mejor_par[0]:
                mejor_par = (d, a, b)
    dias = len({m["fecha"][:10] for m in buenas})
    if mejor_par and mejor_par[0] <= TOLERANCIA_ENTRE_DIAS_M:
        d, a, b = mejor_par
        centro = ((a["lat"] + b["lat"]) / 2, (a["lng"] + b["lng"]) / 2)
        grupo = [m for m in buenas if metros(centro, (m["lat"], m["lng"])) <= TOLERANCIA_ENTRE_DIAS_M]
        lat, lng, prec = _promedio(grupo)
        return {"estado": "aceptado", "lat": lat, "lng": lng, "precision": prec,
                "entre_dias_m": d, "motivo": f"{len(grupo)} medidas en {dias} días, a {d:.1f} m"}
    if mejor_par:
        motivo = f"las medidas de días distintos quedan a {mejor_par[0]:.1f} m (máx. 5): medir otra vez"
    elif buenas:
        motivo = "falta una medida en otro día"
    elif medidas:
        peor = min(m["precision"] for m in medidas)
        motivo = f"ninguna medida con precisión de 5 m o mejor (la mejor: ±{peor:.1f} m)"
    else:
        motivo = "sin medir"
    usables = buenas or [m for m in medidas if m["precision"] <= PRECISION_PROVISIONAL_M]
    if not usables:
        return {"estado": "sin_medidas_utiles", "motivo": motivo}
    lat, lng, prec = _promedio(usables)
    return {"estado": "sin_confirmar", "lat": lat, "lng": lng, "precision": prec,
            "entre_dias_m": mejor_par[0] if mejor_par else None, "motivo": motivo}


def _media_circular(grados: list[float]) -> float:
    x = sum(math.cos(math.radians(g)) for g in grados)
    y = sum(math.sin(math.radians(g)) for g in grados)
    return math.degrees(math.atan2(y, x)) % 360


def _diferencia(desde: float, hacia: float) -> float:
    d = (hacia - desde) % 360
    return d - 360 if d > 180 else d


def informe(datos: dict[str, list], catalogo: list[dict], accesos_grafo: list[dict],
            declinacion: float) -> str:
    """El estado del levantamiento, en Markdown, para pegarlo en el chat del
    equipo o en docs/."""
    lineas = ["# Informe del levantamiento", ""]

    # Entradas
    por_nombre: dict[tuple[int, str], list[dict]] = {}
    for m in datos["accesos"]:
        por_nombre.setdefault((int(m["poi_id"]), m.get("nombre") or ""), []).append(m)
    esperadas = [(a["poi_id"], a["nombre"]) for a in accesos_grafo]
    nuevas = [k for k in por_nombre if k not in esperadas]
    aceptadas = 0
    filas = []
    for clave_acceso in esperadas + nuevas:
        r = evaluar_acceso(por_nombre.get(clave_acceso, []))
        aceptadas += r["estado"] == "aceptado"
        marca = {"aceptado": "✅", "sin_confirmar": "🟡", "sin_medidas_utiles": "❌"}[r["estado"]]
        if not por_nombre.get(clave_acceso):
            marca = "⬜"
        nueva = " (nueva)" if clave_acceso in nuevas else ""
        filas.append(f"| {marca} | {clave_acceso[1]}{nueva} | {len(por_nombre.get(clave_acceso, []))} | {r['motivo']} |")
    lineas += [f"## Entradas: {aceptadas} de {len(esperadas) + len(nuevas)} aceptadas", "",
               "Criterio: dos medidas en días distintos, a 5 m o menos entre sí, con precisión de 5 m o mejor.", "",
               "| | Entrada | Medidas | Estado |", "|---|---|---|---|", *filas, ""]

    # Norte de las panorámicas
    paradas = {p["id"]: p["nombre"] for p in catalogo if p.get("es_parada")}
    lineas += ["## Norte de las panorámicas", ""]
    lineas += ["| Parada | Objeto | Rumbo magnético | Rumbo geográfico | Yaw del objeto | Yaw del norte |",
               "|---|---|---|---|---|---|"]
    medidas_norte = {}
    for n in datos["nortes"]:
        medidas_norte.setdefault(int(n["poi_id"]), []).append(n)
    for pid, nombre in sorted(paradas.items()):
        for n in medidas_norte.get(pid, []) or [None]:
            if n is None:
                lineas.append(f"| ⬜ {nombre} | — | — | — | — | — |")
                continue
            # Se conserva el magnético crudo para poder corregir después la
            # declinación sin volver a medir las panorámicas.
            geo = (n["rumbo_magnetico"] + declinacion) % 360
            yaw = n.get("yaw_objeto")
            norte = "falta el yaw" if yaw is None else f"{(yaw - geo) % 360:.1f}°"
            lineas.append(f"| {nombre} | {n.get('objeto', '')} | {n['rumbo_magnetico']:.1f}° | {geo:.1f}° | "
                          f"{'—' if yaw is None else f'{yaw:.1f}°'} | {norte} |")
    lineas += ["", "Yaw del norte = yaw del objeto en la panorámica − rumbo geográfico del objeto "
               "(los dos en sentido horario). Es el `rumbo_norte` de la escena.", ""]

    # Brújula
    lineas += ["## Brújula (RNF-27: 10° como máximo)", ""]
    errores = [b["error"] for b in datos["brujula"]]
    if len(errores) < 2:
        lineas += [f"{len(errores)} comprobaciones: hacen falta al menos 8, en sitios distintos.", ""]
    else:
        sesgo = statistics.fmean(errores)
        residuos = sorted(abs(e - sesgo) for e in errores)
        p95 = residuos[min(len(residuos) - 1, math.ceil(0.95 * len(residuos)) - 1)]
        cumple = "cumple" if len(errores) >= 8 and p95 <= ERROR_RUMBO_MAX else "NO cumple"
        lineas += [f"- Comprobaciones: {len(errores)} (mínimo 8, en sitios distintos)",
                   f"- Sesgo medio: {sesgo:+.1f}° → declinación sugerida: {declinacion - sesgo:.1f}° "
                   f"(hoy {declinacion}°). Si el sesgo pasa de 3°, cambiar DECLINACION en este script.",
                   f"- Error tras corregir el sesgo: p95 {p95:.1f}°, máximo {residuos[-1]:.1f}° → RNF-27 **{cumple}**",
                   f"- Sin corregir: máximo {max(abs(e) for e in errores):.1f}°",
                   f"- Con aviso de calibración: {sum(1 for b in datos['brujula'] if b.get('descalibrada'))}", ""]

    # Pruebas de la guía
    lineas += ["## Pruebas de la guía", ""]
    if not datos["pruebas"]:
        lineas += ["Ninguna todavía: hay que caminar las cinco paradas.", ""]
    else:
        lineas += ["| Destino | Ruta | Llegada detectada | Error de llegada | Recálculos | Indicaciones mal | Resultado |",
                   "|---|---|---|---|---|---|---|"]
        for p in datos["pruebas"]:
            eventos = p.get("eventos", [])
            recalculos = sum(1 for e in eventos if e.get("tipo") == "fuera_de_ruta")
            malas = sum(1 for e in eventos if e.get("tipo") == "indicacion_mala")
            llegada, puerta = p.get("llegada_app"), p.get("puerta_real")
            if llegada and puerta:
                error = metros((llegada["lat"], llegada["lng"]), (puerta["lat"], puerta["lng"]))
                error_txt = f"{error:.1f} m"
                ok = (error <= RADIO_LLEGADA_M and not malas
                      and llegada.get("precision", math.inf) <= RADIO_LLEGADA_M
                      and puerta.get("precision", math.inf) <= PRECISION_ACEPTABLE_M)
            else:
                error_txt = "—"
                ok = False
            detectada = "sí" if llegada else "no"
            lineas.append(f"| {p.get('destino', p.get('poi_id'))} | {p.get('metros_ruta', 0):.0f} m | {detectada} | "
                          f"{error_txt} | {recalculos} | {malas} | {'✅' if ok else '❌'} |")
        lineas += ["", f"Pasa si la app detecta la llegada a {RADIO_LLEGADA_M:.0f} m o menos de la puerta real "
                   "y ninguna indicación se marcó como equivocada. La precisión debe ser de 10 m o mejor "
                   "en la llegada y de 5 m o mejor al marcar la puerta.", ""]

    # Tramos y recorridos
    lineas += ["## Tramos y recorridos", "",
               f"- Tramos marcados: {len(datos['tramos'])} "
               f"({sum(1 for t in datos['tramos'] if t.get('escalones'))} con escalones, "
               f"{sum(1 for t in datos['tramos'] if t.get('techado'))} techados, "
               f"{sum(1 for t in datos['tramos'] if t.get('tipo') == 'rampa')} rampas)",
               f"- Recorridos grabados: {len(datos['recorridos'])}: "
               + (", ".join(r.get("etiqueta") or "sin etiqueta" for r in datos["recorridos"]) or "ninguno"),
               "- Un camino que falta (el puente A3–A5, un pasillo) se graba como recorrido y se "
               "agrega en OpenStreetMap; `scripts/mapa_campus.py` y este script lo recogen después.", ""]
    return "\n".join(lineas)


def recorridos_geojson(datos: dict[str, list]) -> dict:
    return {"type": "FeatureCollection", "features": [
        {"type": "Feature",
         "properties": {"etiqueta": r.get("etiqueta") or "", "fecha": r.get("fecha", ""),
                        "puntos": len(r.get("puntos", []))},
         "geometry": {"type": "LineString",
                      "coordinates": [[p["lng"], p["lat"]] for p in r.get("puntos", [])]}}
        for r in datos["recorridos"] if len(r.get("puntos", [])) >= 2]}


def main(levantamientos: list[str], solo_informe: bool = False,
         geojson: str | None = None) -> None:
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

    datos = cargar_levantamientos(levantamientos)

    # Tramos marcados en el campus, antes de enganchar las entradas: al partir
    # un tramo, las dos mitades heredan lo marcado.
    sin_tramo = []
    for t in datos["tramos"]:
        i, _, distancia = proyectar((t["lat"], t["lng"]))
        if i < 0 or distancia > RADIO_MARCA_TRAMO_M:
            sin_tramo.append(t)
            continue
        e = aristas[i]
        if t.get("tipo") in TIPOS_TRAMO:
            e["tipo"] = t["tipo"]
        if "escalones" in t:
            e["escalones"] = bool(t["escalones"])
        if "techado" in t:
            e["techado"] = bool(t["techado"])

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

    poligonos = {f["properties"].get("osm"): f for f in plano["features"]
                 if f["geometry"]["type"] == "Polygon"}

    # Las entradas estimadas de cada lugar: la del catálogo y las extra.
    estimadas: list[tuple[dict, str, float, float, bool, str]] = []
    for poi in catalogo:
        if poi.get("lat") is None:
            continue
        estimadas.append((poi, poi["nombre"], poi["lat"], poi["lng"], True,
                          f"catálogo: {poi['fuente_posicion']}"))
        for nombre, osm in ACCESOS_EXTRA.get(poi["id"], []):
            anillo = poligonos[osm]["geometry"]["coordinates"][0]
            lat = sum(c[1] for c in anillo) / len(anillo)
            lng = sum(c[0] for c in anillo) / len(anillo)
            estimadas.append((poi, nombre, lat, lng, False, f"centro de OSM {osm}"))

    # Las medidas reemplazan a la estimada del mismo nombre; un nombre nuevo
    # es una entrada que el catálogo no tenía.
    medidas: dict[tuple[int, str], list[dict]] = {}
    for m in datos["accesos"]:
        medidas.setdefault((int(m["poi_id"]), m.get("nombre") or ""), []).append(m)
    por_poi = {p["id"]: p for p in catalogo}
    conocidas = {(poi["id"], nombre) for poi, nombre, *_ in estimadas}
    for (pid, nombre) in medidas:
        if (pid, nombre) not in conocidas and pid in por_poi:
            poi = por_poi[pid]
            estimadas.append((poi, nombre or poi["nombre"], poi["lat"], poi["lng"], False, "nueva en el campus"))

    accesos = []
    for poi, nombre, lat, lng, principal, fuente in estimadas:
        r = evaluar_acceso(medidas.get((poi["id"], nombre), []))
        if r["estado"] != "sin_medidas_utiles":
            lat, lng = r["lat"], r["lng"]
            fuente = f"levantamiento ±{r['precision']:.1f} m: {r['motivo']}"
        accesos.append(enganchar(nombre, poi, lat, lng, principal,
                                 r["estado"] == "aceptado", fuente))

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

    if solo_informe:
        print(informe(datos, catalogo, accesos, DECLINACION))
        if sin_tramo:
            print(f"\n{len(sin_tramo)} tramos marcados quedaron a más de {RADIO_MARCA_TRAMO_M:.0f} m "
                  "de cualquier tramo de OSM: falta ese camino en OSM.")
        if geojson:
            Path(geojson).write_text(json.dumps(recorridos_geojson(datos), ensure_ascii=False),
                                     encoding="utf-8")
            print(f"\nRecorridos en {geojson}")
        return

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
    if sin_tramo:
        print(f"{len(sin_tramo)} tramos marcados sin tramo de OSM a {RADIO_MARCA_TRAMO_M:.0f} m (ver --informe)")
    print(SALIDA, f"{SALIDA.stat().st_size // 1024} KB")


if __name__ == "__main__":
    argumentos = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    argumentos.add_argument("levantamientos", nargs="*", help="JSON exportados por la app de levantamiento")
    argumentos.add_argument("--informe", action="store_true", help="solo imprimir el estado del levantamiento")
    argumentos.add_argument("--geojson", help="con --informe, dónde escribir los recorridos grabados")
    a = argumentos.parse_args()
    try:
        main(a.levantamientos, a.informe, a.geojson)
    except (FileNotFoundError, json.JSONDecodeError) as error:
        argumentos.error(str(error))
