#!/usr/bin/env python3
"""Compila el APK de demostracion, que funciona sin red ni servidor.

Copia dentro de la app las panoramicas, las narraciones y los subtitulos, y
compila en modo demo con los medios empaquetados:

    flutter build apk --release --dart-define=DATOS=demo
                      --dart-define=MEDIOS_DEMO=empaquetados

El contenido (lugares, escenas, hotspots, textos) es el del modo demo, copia de
`services/api/Data/ContenidoInicial.cs`. No necesita la API ni la base: sirve
para ensenar el proyecto en cualquier sitio, con o sin wifi.

Los medios son material institucional y no se versionan. Se esperan en
`assets/narraciones/generadas/` (`panoramas/`, `audios/`, `subtitulos/`): las
narraciones las deja ahi `scripts/narraciones/generar_narraciones.py` y las
panoramicas `scripts/subir_medios.py --solo-preparar --destino ...`.

El APK queda firmado con la clave de depuracion (ver
android/app/build.gradle.kts): se instala en cualquier telefono permitiendo
«instalar apps de origen desconocido», pero no sirve para Play Store. Lleva
panoramicas sin difuminar: es para ensenarlo, no para distribuirlo.

Uso:

    python scripts/preparar_apk_demo.py              # copia y compila
    python scripts/preparar_apk_demo.py --solo-copiar
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
ORIGEN = RAIZ / "assets" / "narraciones" / "generadas"
MOVIL = RAIZ / "apps" / "mobile"
DESTINO = MOVIL / "android" / "app" / "src" / "assets" / "demo"
CARPETAS = {"panoramas": "*.jpg", "audios": "*.mp3", "subtitulos": "*.vtt"}
APK = MOVIL / "build" / "app" / "outputs" / "flutter-apk" / "app-release.apk"


def copiar() -> bool:
    completo = True
    for carpeta, patron in CARPETAS.items():
        destino = DESTINO / carpeta
        destino.mkdir(parents=True, exist_ok=True)
        # Vacia lo copiado antes, sin tocar el .gitkeep que mantiene la carpeta.
        for viejo in destino.glob(patron):
            viejo.unlink()
        archivos = sorted((ORIGEN / carpeta).glob(patron))
        for archivo in archivos:
            shutil.copy2(archivo, destino / archivo.name)
        megas = sum(a.stat().st_size for a in archivos) / 1e6
        print(f"  {carpeta:11s} {len(archivos):3d} archivos  {megas:5.1f} MB")
        completo &= bool(archivos)
    return completo


def main() -> int:
    argumentos = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    argumentos.add_argument("--solo-copiar", action="store_true")
    opciones = argumentos.parse_args()

    print(f"Copiando medios de {ORIGEN}")
    if not copiar():
        print("Falta alguna carpeta de medios; el APK saldria sin ellos.", file=sys.stderr)
        return 1
    if opciones.solo_copiar:
        return 0

    flutter = shutil.which("flutter") or shutil.which("flutter.bat")
    if not flutter:
        print("No encuentro flutter en el PATH.", file=sys.stderr)
        return 1
    subprocess.run(
        [flutter, "build", "apk", "--release",
         "--dart-define=DATOS=demo", "--dart-define=MEDIOS_DEMO=empaquetados"],
        cwd=MOVIL, check=True)
    print(f"\nAPK: {APK} ({APK.stat().st_size / 1e6:.0f} MB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
