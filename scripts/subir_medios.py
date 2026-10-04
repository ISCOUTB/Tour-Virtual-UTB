#!/usr/bin/env python3
"""Prepara las panoramicas y los audios y los sube al Storage del stack local.

`supabase db reset` reconstruye toda la base, y el Storage guarda su indice en
esa misma base: tras un reset los buckets quedan vacios y las escenas y los
medios de `seed.sql` apuntan a objetos que ya no existen. Ni el visor 360 ni el
reproductor fallan de forma visible, solo se quedan en negro o en un error
generico. Hay que volver a ejecutar esto despues de cada reset.

Los originales no estan en el repositorio: son contenido institucional. Se
esperan en `assets/ZONAS UTB/` y `assets/AUDIOS/`, tal como los entrego la
universidad.

Panoramicas: reduce a 4096x2048 y genera ademas una variante de 1024x512. Las
originales rondan los 9000 px de ancho y entre 7 y 17 MB; a ese tamano la carga
por una wifi compartida se hace eterna. La variante ligera se muestra mientras
baja la completa. En conjunto, 63.8 MB pasan a 8.5 MB. Descarta EXIF y XMP al
convertir: no traian GPS, pero si modelo de telefono y fecha.

Audios: llegaron a 320 kbps mono, unas cinco veces lo que necesita una voz. Si
hay ffmpeg en el PATH se recomprimen a 64 kbps y se les quitan las etiquetas;
si no, se suben tal cual y se avisa. Para instalarlo: `scoop install ffmpeg`.

Lo que NO hace, y hay que hacer antes a mano si una panoramica lleva gente:
difuminar rostros con `deface` y la revision manual. Ver la seccion 7.1 de
docs/arquitectura.md. En las cinco actuales no aparece nadie.

Uso:

    python scripts/subir_medios.py                 # prepara y sube
    python scripts/subir_medios.py --solo-preparar # deja los archivos y para

La clave de servicio sale de `supabase status -o json`, o de SUPABASE_URL y
SUPABASE_SERVICE_ROLE_KEY si estan definidas.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
PANORAMAS = RAIZ / "assets" / "ZONAS UTB"
AUDIOS = RAIZ / "assets" / "AUDIOS"
BUCKET_PANORAMAS = "panoramas"
BUCKET_AUDIOS = "audios"

# Nombre del archivo entregado -> slug que usa seed.sql.
NOMBRES = {
    "Biblioteca.jpg": "biblioteca",
    "A5 Y A3.jpg": "puente-a3-a5",
    "Enfermeria.jpg": "enfermeria",
    "Zona t.jpg": "zona-t",
    "Cancha 1.jpg": "cancha-softbol",
}

NOMBRES_AUDIO = {
    "Biblioteca.mp3": "biblioteca",
    "Puente.mp3": "puente-a3-a5",
    "Enfermeria.mp3": "enfermeria",
    "Zona_T.mp3": "zona-t",
    "Softbol.mp3": "cancha-softbol",
}

# (ancho, sufijo, calidad). La equirectangular es 2:1, el alto sale solo.
VARIANTES = ((4096, "", 82), (1024, "-baja", 70))

# Voz mono: 64 kbps es de sobra y pesa una quinta parte que el original.
BITRATE_VOZ = "64k"


def _ejecutar(orden: list[str]) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(
        orden,
        capture_output=True,
        check=True,
        shell=sys.platform == "win32",
    )


def credenciales() -> tuple[str, str]:
    url = os.environ.get("SUPABASE_URL")
    clave = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    if url and clave:
        return url, clave

    try:
        salida = subprocess.run(
            ["supabase", "status", "-o", "json"],
            cwd=RAIZ,
            capture_output=True,
            text=True,
            check=True,
            shell=sys.platform == "win32",
        ).stdout
    except (OSError, subprocess.CalledProcessError) as error:
        sys.exit(
            "No se pudo leer el estado de Supabase. Arranca el stack con "
            "`supabase start` o define SUPABASE_URL y "
            f"SUPABASE_SERVICE_ROLE_KEY.\n{error}"
        )

    estado = json.loads(salida)
    return estado["API_URL"], estado["SERVICE_ROLE_KEY"]


def preparar_panoramas(destino: Path) -> list[Path]:
    if not PANORAMAS.is_dir():
        print(f"  (sin panoramicas en {PANORAMAS})")
        return []

    Image.MAX_IMAGE_PIXELS = None
    listos: list[Path] = []
    origen_total = salida_total = 0

    for archivo, slug in NOMBRES.items():
        ruta = PANORAMAS / archivo
        if not ruta.is_file():
            print(f"  FALTA  {archivo}", file=sys.stderr)
            continue
        origen_total += ruta.stat().st_size

        with Image.open(ruta) as imagen:
            ancho, alto = imagen.size
            if abs(ancho / alto - 2) > 0.01:
                print(
                    f"  AVISO  {archivo} no es 2:1 ({ancho}x{alto}); una "
                    "equirectangular que no lo sea sale deformada en el visor",
                    file=sys.stderr,
                )
            # convert() deja atras EXIF y XMP.
            base = imagen.convert("RGB")
            for px, sufijo, calidad in VARIANTES:
                vista = base.resize((px, px // 2), Image.LANCZOS)
                salida = destino / f"{slug}{sufijo}.jpg"
                vista.save(
                    salida,
                    "JPEG",
                    quality=calidad,
                    optimize=True,
                    progressive=True,
                )
                salida_total += salida.stat().st_size
                listos.append(salida)
                print(f"  {salida.name:26} {salida.stat().st_size / 1e6:6.2f} MB")

    if origen_total:
        print(
            f"  {origen_total / 1e6:.1f} MB originales -> "
            f"{salida_total / 1e6:.1f} MB servidos "
            f"({salida_total / origen_total:.1%})"
        )
    return listos


def _hay_ffmpeg() -> bool:
    try:
        _ejecutar(["ffmpeg", "-version"])
        return True
    except (OSError, subprocess.CalledProcessError):
        return False


def preparar_audios(destino: Path) -> list[Path]:
    """Deja cada narracion lista para subir, recomprimida si se puede."""
    if not AUDIOS.is_dir():
        print(f"  (sin audios en {AUDIOS})")
        return []

    recomprime = _hay_ffmpeg()
    if not recomprime:
        print(
            "  ffmpeg no esta en el PATH: los audios se suben tal cual, a "
            "320 kbps mono.\n  `scoop install ffmpeg` los deja en 64 kbps."
        )

    listos: list[Path] = []
    origen_total = salida_total = 0

    for archivo, slug in NOMBRES_AUDIO.items():
        ruta = AUDIOS / archivo
        if not ruta.is_file():
            print(f"  FALTA  {archivo}", file=sys.stderr)
            continue
        origen_total += ruta.stat().st_size
        salida = destino / f"{slug}.mp3"

        hecho = False
        if recomprime:
            try:
                _ejecutar(
                    [
                        "ffmpeg", "-y", "-i", str(ruta),
                        "-ac", "1",
                        "-b:a", BITRATE_VOZ,
                        "-map_metadata", "-1",
                        str(salida),
                    ]
                )
                hecho = True
            except (OSError, subprocess.CalledProcessError) as error:
                print(
                    f"  AVISO  no se pudo recomprimir {archivo}: {error}",
                    file=sys.stderr,
                )
        if not hecho:
            salida.write_bytes(ruta.read_bytes())

        salida_total += salida.stat().st_size
        listos.append(salida)
        print(f"  {salida.name:26} {salida.stat().st_size / 1e6:6.2f} MB")

    if origen_total:
        print(
            f"  {origen_total / 1e6:.1f} MB de audio -> "
            f"{salida_total / 1e6:.1f} MB "
            f"({salida_total / origen_total:.1%})"
        )
    return listos


def peticion(metodo: str, url: str, clave: str, cuerpo: bytes | None, tipo: str):
    cabeceras = {"Authorization": f"Bearer {clave}", "Content-Type": tipo}
    pet = urllib.request.Request(url, data=cuerpo, headers=cabeceras, method=metodo)
    try:
        with urllib.request.urlopen(pet) as respuesta:
            return respuesta.status, respuesta.read()
    except urllib.error.HTTPError as error:
        return error.code, error.read()


def subir(
    archivos: list[Path],
    api: str,
    clave: str,
    bucket: str,
    tipo: str,
) -> int:
    # Los buckets son publicos: panoramicas y narraciones son contenido
    # institucional abierto, y el filtrado por audiencia lo hace RLS sobre
    # `escenas` y `pois`, no el Storage.
    estado, cuerpo = peticion(
        "POST",
        f"{api}/storage/v1/bucket",
        clave,
        json.dumps(
            {
                "id": bucket,
                "name": bucket,
                "public": True,
                "file_size_limit": 10 * 1024 * 1024,
                "allowed_mime_types": [tipo],
            }
        ).encode(),
        "application/json",
    )
    if estado in (200, 201):
        print(f"bucket {bucket}: creado")
    elif b"already exists" in cuerpo or b"Duplicate" in cuerpo:
        print(f"bucket {bucket}: ya existia")
    else:
        sys.exit(
            f"No se pudo preparar el bucket {bucket}: HTTP {estado} "
            f"{cuerpo.decode(errors='replace')[:200]}"
        )

    fallos = 0
    for archivo in archivos:
        # upsert para poder reejecutar sin borrar antes.
        url = f"{api}/storage/v1/object/{bucket}/{archivo.name}"
        datos = archivo.read_bytes()
        estado, cuerpo = peticion("PUT", url, clave, datos, tipo)
        if estado not in (200, 201):
            estado, cuerpo = peticion("POST", url, clave, datos, tipo)
        ok = estado in (200, 201)
        fallos += 0 if ok else 1
        detalle = "" if ok else " " + cuerpo.decode(errors="replace")[:120]
        print(f"  {'ok ' if ok else 'ERR'} {archivo.name:26} HTTP {estado}{detalle}")
    return fallos


def main() -> int:
    analizador = argparse.ArgumentParser(description=__doc__)
    analizador.add_argument(
        "--solo-preparar",
        action="store_true",
        help="genera los archivos y no los sube",
    )
    analizador.add_argument(
        "--destino",
        type=Path,
        help="donde dejar los archivos preparados (por defecto, un temporal)",
    )
    args = analizador.parse_args()

    with tempfile.TemporaryDirectory() as temporal:
        destino = args.destino or Path(temporal)
        carpeta_pano = destino / "panoramas"
        carpeta_audio = destino / "audios"
        carpeta_pano.mkdir(parents=True, exist_ok=True)
        carpeta_audio.mkdir(parents=True, exist_ok=True)
        print(f"Preparando en {destino}")

        print("\nPanoramicas:")
        panoramas = preparar_panoramas(carpeta_pano)
        print("\nAudios:")
        audios = preparar_audios(carpeta_audio)
        if not panoramas and not audios:
            return 1

        if args.solo_preparar:
            if not args.destino:
                print(
                    "\nAviso: sin --destino los archivos estaban en un "
                    "temporal y se acaban de borrar.",
                    file=sys.stderr,
                )
            return 0

        api, clave = credenciales()
        fallos = 0
        print()
        if panoramas:
            fallos += subir(panoramas, api, clave, BUCKET_PANORAMAS, "image/jpeg")
        if audios:
            fallos += subir(audios, api, clave, BUCKET_AUDIOS, "audio/mpeg")
        return 1 if fallos else 0


if __name__ == "__main__":
    raise SystemExit(main())
