#!/usr/bin/env python3
"""Prepara la maqueta de ElMapita como recurso local y sin red para el APK."""
import hashlib
import json
import struct
import urllib.request
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
CARPETA = RAIZ / "packages" / "tour_virtual" / "assets" / "mapa3d"


def preparar(contenido: bytes) -> bytes:
    if contenido[:4] != b"glTF" or struct.unpack_from("<I", contenido, 4)[0] != 2:
        raise ValueError("El recurso no es un GLB 2 válido")
    largo, tipo = struct.unpack_from("<II", contenido, 12)
    if tipo != 0x4E4F534A:
        raise ValueError("El GLB no tiene cabecera JSON")
    modelo = json.loads(contenido[20:20 + largo])
    # La imagen plana usada para modelar no es parte de la maqueta final.
    ocultos = {i for i, nodo in enumerate(modelo.get("nodes", []))
               if nodo.get("name") == "Plano_Referencia"}
    for escena in modelo.get("scenes", []):
        escena["nodes"] = [i for i in escena.get("nodes", []) if i not in ocultos]
    for nodo in modelo.get("nodes", []):
        if "children" in nodo:
            nodo["children"] = [i for i in nodo["children"] if i not in ocultos]
    bloque = json.dumps(modelo, ensure_ascii=False, separators=(",", ":")).encode()
    bloque += b" " * (-len(bloque) % 4)
    resto = contenido[20 + largo:]
    return (struct.pack("<III", 0x46546C67, 2, 20 + len(bloque) + len(resto))
            + struct.pack("<II", len(bloque), tipo) + bloque + resto)


def main() -> None:
    origen = json.loads((CARPETA / "origen.json").read_text(encoding="utf-8"))
    with urllib.request.urlopen(origen["url"], timeout=60) as respuesta:
        contenido = respuesta.read(20 * 1024 * 1024 + 1)
    if hashlib.sha256(contenido).hexdigest() != origen["sha256"]:
        raise ValueError("El modelo cambió: revisar su procedencia y calibración antes de actualizar origen.json")
    destino = CARPETA / "campus_elmapita.glb"
    destino.write_bytes(preparar(contenido))
    print(f"Modelo preparado: {destino} ({destino.stat().st_size / 1e6:.1f} MB)")


if __name__ == "__main__":
    main()
