#!/usr/bin/env python3
"""Sube las narraciones de entrega-backend-2026-10-24.zip por la API de admin.

Lee `narraciones/manifiesto.csv` (una fila por narracion) y, por cada fila,
crea un medio de tipo audio en su POI con POST /api/admin/pois/{id}/medios:
el MP3, su subtitulo .vtt, el idioma, la duracion y el texto alternativo. El
POI se busca por nombre en GET /api/lugares/{lugar}/pois.

Por defecto solo SIMULA: muestra lo que haria y no cambia nada. Para subir de
verdad hay que pasar `--subir`.

Se puede ejecutar mas de una vez: si un POI ya tiene una narracion con
subtitulos en ese idioma, la fila se salta.

`--reemplazar-espanol` borra los audios viejos en espanol (sin idioma o "es" y
sin subtitulos) de cada POI, pero solo despues de comprobar que la narracion
nueva en espanol de ese POI ya esta cargada. Borrar no tiene vuelta atras.

La clave de administracion se lee de la variable de entorno UTB_ADMIN_KEY,
para que no quede en el historial de la terminal. En Development, sin clave
configurada en la API, puede quedar vacia.

Uso (PowerShell, con la API corriendo):

    $env:UTB_ADMIN_KEY = "..."
    python scripts/narraciones/cargar_narraciones.py ~/Downloads/entrega-backend-2026-10-24.zip
    python scripts/narraciones/cargar_narraciones.py ~/Downloads/entrega-backend-2026-10-24.zip --subir
    python scripts/narraciones/cargar_narraciones.py ~/Downloads/entrega-backend-2026-10-24.zip --subir --reemplazar-espanol

La entrega puede ser el zip tal cual o la carpeta ya descomprimida.
"""

from __future__ import annotations

import argparse
import csv
import io
import json
import os
import sys
import unicodedata
import urllib.error
import urllib.request
import uuid
import zipfile
from pathlib import Path

# Mismo orden que la app; define el campo Orden de cada medio.
IDIOMAS = ["es", "en", "pt", "pt-PT", "fr", "it", "de", "tr", "ko", "ja", "zh"]


class Entrega:
    """Lee archivos de la entrega, sea el zip o la carpeta descomprimida."""

    def __init__(self, ruta: Path):
        self.zip = zipfile.ZipFile(ruta) if ruta.is_file() else None
        self.carpeta = ruta
        if self.zip is None and (ruta / "narraciones").is_dir():
            self.carpeta = ruta / "narraciones"

    def leer(self, relativa: str) -> bytes:
        if self.zip is not None:
            for nombre in (f"narraciones/{relativa}", relativa):
                try:
                    return self.zip.read(nombre)
                except KeyError:
                    continue
            raise FileNotFoundError(relativa)
        return (self.carpeta / relativa).read_bytes()


def clave_nombre(texto: str) -> str:
    return unicodedata.normalize("NFC", texto).strip().casefold()


def idioma_de(medio: dict) -> str:
    return (medio.get("idioma") or "es").strip()


class Api:
    def __init__(self, base: str, clave: str | None):
        self.base = base.rstrip("/")
        self.clave = clave

    def _pedir(self, metodo: str, ruta: str, cuerpo: bytes | None = None,
               tipo: str | None = None):
        peticion = urllib.request.Request(self.base + ruta, data=cuerpo, method=metodo)
        if tipo:
            peticion.add_header("Content-Type", tipo)
        if self.clave:
            peticion.add_header("X-Admin-Key", self.clave)
        try:
            with urllib.request.urlopen(peticion, timeout=120) as respuesta:
                datos = respuesta.read()
        except urllib.error.HTTPError as error:
            detalle = error.read().decode("utf-8", "replace")[:300]
            raise RuntimeError(f"{metodo} {ruta} respondio {error.code}: {detalle}") from None
        except urllib.error.URLError as error:
            raise RuntimeError(f"No se pudo conectar con {self.base}: {error.reason}") from None
        return json.loads(datos) if datos else None

    def pois(self, lugar: int) -> list[dict]:
        return self._pedir("GET", f"/api/lugares/{lugar}/pois")

    def medios(self, poi_id: int) -> list[dict]:
        return self._pedir("GET", f"/api/pois/{poi_id}")["medios"]

    def borrar_medio(self, medio_id: int) -> None:
        self._pedir("DELETE", f"/api/admin/medios/{medio_id}")

    def subir_medio(self, poi_id: int, campos: dict[str, str],
                    archivos: dict[str, tuple[str, bytes, str]]) -> dict:
        frontera = uuid.uuid4().hex
        cuerpo = io.BytesIO()
        for nombre, valor in campos.items():
            cuerpo.write(f"--{frontera}\r\nContent-Disposition: form-data; "
                         f'name="{nombre}"\r\n\r\n{valor}\r\n'.encode("utf-8"))
        for nombre, (archivo, contenido, tipo) in archivos.items():
            cuerpo.write(f"--{frontera}\r\nContent-Disposition: form-data; "
                         f'name="{nombre}"; filename="{archivo}"\r\n'
                         f"Content-Type: {tipo}\r\n\r\n".encode("utf-8"))
            cuerpo.write(contenido)
            cuerpo.write(b"\r\n")
        cuerpo.write(f"--{frontera}--\r\n".encode("utf-8"))
        return self._pedir("POST", f"/api/admin/pois/{poi_id}/medios", cuerpo.getvalue(),
                           f"multipart/form-data; boundary={frontera}")


def main() -> int:
    analizador = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    analizador.add_argument("entrega", type=Path,
                            help="entrega-backend-2026-10-24.zip o su carpeta descomprimida")
    analizador.add_argument("--api", default="http://localhost:5209",
                            help="direccion de la API (por defecto %(default)s)")
    analizador.add_argument("--lugar", type=int, default=1, help="id del lugar (por defecto 1)")
    analizador.add_argument("--subir", action="store_true",
                            help="sube de verdad; sin esto solo simula")
    analizador.add_argument("--reemplazar-espanol", action="store_true",
                            help="borra los audios viejos en espanol cuando el nuevo ya esta cargado")
    args = analizador.parse_args()

    entrega = Entrega(args.entrega.expanduser())
    filas = list(csv.DictReader(io.StringIO(entrega.leer("manifiesto.csv").decode("utf-8-sig"))))
    api = Api(args.api, os.environ.get("UTB_ADMIN_KEY"))
    modo = "SUBIENDO" if args.subir else "SIMULACION (no se cambia nada; usa --subir)"
    print(f"{modo}. {len(filas)} narraciones en el manifiesto.\n")

    try:
        pois = {clave_nombre(p["nombre"]): p for p in api.pois(args.lugar)}
    except RuntimeError as error:
        print(error, file=sys.stderr)
        return 1

    faltan = sorted({f["poi"] for f in filas if clave_nombre(f["poi"]) not in pois})
    if faltan:
        print("Estos POI no existen en la base (corre antes pois_campus.sql):", file=sys.stderr)
        for nombre in faltan:
            print(f"  - {nombre}", file=sys.stderr)
        return 1

    subidas = saltadas = errores = borradas = 0
    por_poi: dict[int, list[dict]] = {}
    for fila in filas:
        poi = pois[clave_nombre(fila["poi"])]
        idioma = fila["idioma"].strip()
        medios = por_poi.setdefault(poi["id"], api.medios(poi["id"]))
        etiqueta = f"{fila['poi']} [{idioma}]"

        ya_esta = any(m["tipo"] == "audio" and m.get("subtitulos_url")
                      and idioma_de(m).casefold() == idioma.casefold() for m in medios)
        if ya_esta:
            print(f"  ya cargada   {etiqueta}")
            saltadas += 1
            continue

        if not args.subir:
            print(f"  subiria      {etiqueta}  {fila['archivo_audio']} + {fila['archivo_subtitulos']}")
            # Para que la simulacion de --reemplazar-espanol vea la narracion nueva.
            medios.append({"id": None, "tipo": "audio", "subtitulos_url": "(simulado)",
                           "idioma": idioma})
            subidas += 1
            continue

        try:
            audio = entrega.leer(fila["archivo_audio"])
            vtt = entrega.leer(fila["archivo_subtitulos"])
            nuevo = api.subir_medio(
                poi["id"],
                {
                    "Tipo": "audio",
                    "Orden": str(IDIOMAS.index(idioma) if idioma in IDIOMAS else len(IDIOMAS)),
                    "DuracionSeg": fila["duracion_seg"],
                    "TextoAlt": fila["texto_alt"],
                    "Idioma": idioma,
                },
                {
                    "Archivo": (Path(fila["archivo_audio"]).name, audio, "audio/mpeg"),
                    "Subtitulos": (Path(fila["archivo_subtitulos"]).name, vtt, "text/vtt"),
                },
            )
            medios.append(nuevo)
            print(f"  subida       {etiqueta}  (medio {nuevo['id']})")
            subidas += 1
        except (RuntimeError, FileNotFoundError) as error:
            print(f"  ERROR        {etiqueta}: {error}", file=sys.stderr)
            if any(f"respondio {codigo}" in str(error) for codigo in (401, 403, 503)):
                print("La API rechazo la clave de administracion (revisa UTB_ADMIN_KEY). "
                      "No se sigue.", file=sys.stderr)
                return 1
            errores += 1

    if args.reemplazar_espanol:
        print("\nAudios viejos en espanol:")
        for poi_id, medios in por_poi.items():
            nuevo_es = any(m["tipo"] == "audio" and m.get("subtitulos_url")
                           and idioma_de(m) == "es" for m in medios)
            viejos = [m for m in medios if m["tipo"] == "audio" and not m.get("subtitulos_url")
                      and idioma_de(m) == "es"]
            for viejo in viejos:
                if not nuevo_es:
                    print(f"  se conserva  medio {viejo['id']} (POI {poi_id}): aun no hay narracion nueva en espanol")
                elif not args.subir:
                    print(f"  borraria     medio {viejo['id']} (POI {poi_id}) {viejo['url'][:60]}")
                else:
                    try:
                        api.borrar_medio(viejo["id"])
                        print(f"  borrado      medio {viejo['id']} (POI {poi_id})")
                        borradas += 1
                    except RuntimeError as error:
                        print(f"  ERROR        medio {viejo['id']}: {error}", file=sys.stderr)
                        errores += 1

    verbo = "subidas" if args.subir else "por subir"
    print(f"\n{subidas} {verbo}, {saltadas} ya cargadas, {borradas} borradas, {errores} errores.")
    return 1 if errores else 0


if __name__ == "__main__":
    sys.exit(main())
