#!/usr/bin/env python3
"""Genera las narraciones de los lugares con VoiceStudio y el motor VoxCPM2.

Usa la API local de VoiceStudio (http://127.0.0.1:3900). La app tiene que estar
abierta. Si se lanza desde una terminal de VS Code, antes hay que quitar
ELECTRON_RUN_AS_NODE, o la app se cierra al instante.

Siempre pide el motor `voxcpm2`. El que VoiceStudio trae activo por defecto,
OmniVoice, tiene pesos CC-BY-NC y no sirve para contenido publicado.

La voz es DISENADA, no clonada de una persona: se describe y el modelo la
genera. Para que todos los clips de un idioma suenen igual, se trabaja en dos
pasos:

1. `muestras`: genera varias voces candidatas por idioma, una por semilla, a
   partir de la descripcion. Alguien las escucha y elige una. La elegida se
   copia a `--voces` como `<idioma>.wav`, junto con su texto en `<idioma>.txt`.

       python scripts/narraciones/generar_narraciones.py muestras --idiomas es en --salida muestras

   `elegir` hace esa eleccion sola cuando nadie va a escuchar las candidatas:
   la que, transcrita, mas se parece al guion y, entre las que empatan, la de
   tono mas cercano a la voz espanola.

2. `generar`: cada clip del idioma toma esa muestra como referencia. Es una
   voz sintetica, no la de nadie, asi que no hay consentimiento que pedir.
   Despues:
   - transcribe el clip y lo compara con el guion, para detectar palabras
     saltadas o inventadas;
   - hace los subtitulos alineando el guion con los tiempos de la
     transcripcion;
   - normaliza a -16 LUFS y -1 dBTP;
   - exporta MP3 mono a 64 kbps.

   Los nombres son los de docs/ACCESIBILIDAD.md: audios/<lugar>.mp3 para el
   espanol y audios/<lugar>.<idioma>.mp3 para los demas; igual con los .vtt
   en subtitulos/.

       python scripts/narraciones/generar_narraciones.py generar --voces voces --salida medios

La carpeta de salida se puede servir tal cual al modo demo de la app
(MEDIOS_DEMO; ver docs/GUIA_DESARROLLO.md) para revisarla antes de subirla.
"""

from __future__ import annotations

import argparse
import difflib
import glob
import json
import os
import re
import shutil
import subprocess
import sys
import unicodedata
import urllib.request
import uuid
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent.parent
GUIONES = RAIZ / "scripts" / "narraciones" / "guiones.json"
API = "http://127.0.0.1:3900"
MOTOR = "voxcpm2"

# Lo que se pidio el 2026-10-24: femenina adulta, calida, ritmo pausado, tono
# de publicidad. Las narraciones anteriores rondan 216 Hz de F0 mediana, con
# mucha variacion, y unas 2 palabras por segundo contando las pausas.
DESCRIPCION = (
    "Adult woman, warm and friendly voice, medium pitch, polished radio "
    "commercial voice-over, very slow and deliberate pace, long pauses between "
    "phrases, crisp diction"
)

# VoxCPM2 ignora el parametro `speed` de VoiceStudio (medido: 10.1 s con o sin
# el). Aun pidiendo ritmo lento en la descripcion, habla a unas 2.6 palabras
# por segundo, y la narracion anterior iba a 1.9. Se ralentiza al exportar con
# `atempo` de ffmpeg, que conserva el tono; por debajo de ~0.85 empieza a
# sonar procesado.
TEMPO = 0.88
ACENTO = {
    # Pedido el 2026-10-24: espanol latino, colombiano si se logra o neutro.
    "es": "native Colombian Spanish speaker, soft neutral Latin American accent",
    "en": "native American English speaker",
    "pt": "native Brazilian Portuguese speaker",
    "pt-PT": "native European Portuguese speaker from Lisbon",
    "fr": "native French speaker from France",
    "it": "native Italian speaker",
    "de": "native German speaker",
    "tr": "native Turkish speaker",
    "ko": "native Korean speaker",
    "ja": "native Japanese speaker",
    "zh": "native Mandarin Chinese speaker",
}

# Caracteres por linea de subtitulo. 42 es la norma para escritura latina; en
# chino, japones y coreano cada caracter ocupa el doble.
CJK = {"ja", "zh", "ko"}


# --- HTTP --------------------------------------------------------------------


def multipart(campos: dict) -> tuple[bytes, str]:
    limite = uuid.uuid4().hex
    partes = []
    for nombre, valor in campos.items():
        if valor is None:
            continue
        if isinstance(valor, tuple):  # (nombre_archivo, bytes, tipo)
            archivo, datos, tipo = valor
            cabecera = (
                f'--{limite}\r\nContent-Disposition: form-data; name="{nombre}"; '
                f'filename="{archivo}"\r\nContent-Type: {tipo}\r\n\r\n'
            )
            partes.append(cabecera.encode() + datos + b"\r\n")
        else:
            partes.append(
                f'--{limite}\r\nContent-Disposition: form-data; name="{nombre}"'
                f"\r\n\r\n{valor}\r\n".encode()
            )
    partes.append(f"--{limite}--\r\n".encode())
    return b"".join(partes), f"multipart/form-data; boundary={limite}"


def pedir(ruta: str, campos: dict | None = None, timeout: int = 900):
    datos, tipo = multipart(campos) if campos is not None else (None, None)
    pedido = urllib.request.Request(API + ruta, data=datos, method="POST" if datos else "GET")
    if tipo:
        pedido.add_header("Content-Type", tipo)
    with urllib.request.urlopen(pedido, timeout=timeout) as respuesta:
        cuerpo = respuesta.read()
        if respuesta.headers.get_content_type().startswith("audio/"):
            return cuerpo
        return json.loads(cuerpo)


def audio_de(respuesta) -> bytes:
    """/generate responde con el audio o con un JSON que lo referencia."""
    if isinstance(respuesta, bytes):
        return respuesta
    for clave in ("audio_url", "url", "audio_path", "output_url"):
        valor = respuesta.get(clave)
        if isinstance(valor, str) and valor:
            if valor.startswith("/"):
                return pedir(valor) if not Path(valor).exists() else Path(valor).read_bytes()
            if valor.startswith("http"):
                with urllib.request.urlopen(valor, timeout=120) as r:
                    return r.read()
            return Path(valor).read_bytes()
    raise RuntimeError(f"/generate no devolvio audio: {json.dumps(respuesta)[:300]}")


def generar_voz(texto: str, idioma: str, *, semilla: int, referencia: Path | None = None,
                texto_referencia: str | None = None, acento: str | None = None) -> bytes:
    campos = {
        "text": texto,
        "language": idioma,
        "engine": MOTOR,
        "seed": semilla,
    }
    if referencia is None:
        campos["instruct"] = f"{DESCRIPCION}, {acento or ACENTO[idioma]}"
    else:
        campos["ref_audio"] = (referencia.name, referencia.read_bytes(), "audio/wav")
        campos["ref_text"] = texto_referencia
    return audio_de(pedir("/generate", campos))


def transcribir(wav: Path, idioma: str) -> dict:
    campos = {
        "file": (wav.name, wav.read_bytes(), "audio/wav"),
        "model": "whisper-1",
        "language": idioma.split("-")[0],
        "response_format": "verbose_json",
        "timestamp_granularities[]": "word",
    }
    return pedir("/v1/audio/transcriptions", campos)


# --- Audio -------------------------------------------------------------------


def ffmpeg() -> str:
    en_path = shutil.which("ffmpeg")
    if en_path:
        return en_path
    datos = os.environ.get("APPDATA", "")
    candidatos = glob.glob(os.path.join(datos, "OmniVoice", "media_tools", "ffbin-*", "win32", "ffmpeg.exe"))
    if candidatos:
        return candidatos[0]
    sys.exit("No hay ffmpeg: ni en el PATH ni el que trae VoiceStudio. `scoop install ffmpeg`.")


def ralentizar(origen: Path, destino: Path, tempo: float) -> None:
    subprocess.run([ffmpeg(), "-hide_banner", "-v", "error", "-y", "-i", str(origen),
                    "-af", f"atempo={tempo}", str(destino)], check=True)


def medir(audio: Path, objetivo: str = "I=-16:TP=-2:LRA=11") -> dict:
    salida = subprocess.run(
        [ffmpeg(), "-hide_banner", "-i", str(audio), "-af", f"loudnorm={objetivo}:print_format=json",
         "-f", "null", "-"], capture_output=True, text=True, check=True).stderr
    return json.loads(salida[salida.rindex("{"):salida.rindex("}") + 1])


def a_mp3(wav: Path, mp3: Path) -> dict:
    """Normaliza a -16 LUFS en dos pasadas y exporta MP3 mono 64 kbps.

    El pico queda bajo -1 dBTP gracias a un limitador a -3 dBFS despues de
    normalizar. Sin el, loudnorm pasa a modo dinamico cuando la ganancia lineal
    no cabe, el MP3 rebasa unas decimas al codificar, y un clip llego a
    -0.2 dBTP."""
    m = medir(wav)
    mp3.parent.mkdir(parents=True, exist_ok=True)
    # Si aun asi el MP3 rebasa (paso con un clip en chino), se baja el limite.
    for limite in (0.708, 0.56, 0.45):
        filtro = (f"loudnorm=I=-16:TP=-2:LRA=11:measured_I={m['input_i']}:measured_TP={m['input_tp']}:"
                  f"measured_LRA={m['input_lra']}:measured_thresh={m['input_thresh']}:"
                  f"offset={m['target_offset']}:linear=true,"
                  f"alimiter=limit={limite}:level=0:attack=2:release=50")
        subprocess.run([ffmpeg(), "-hide_banner", "-v", "error", "-y", "-i", str(wav), "-af", filtro,
                        "-ar", "44100", "-ac", "1", "-b:a", "64k", "-map_metadata", "-1", str(mp3)],
                       check=True)
        if float(medir(mp3)["input_tp"]) <= -1.0:
            break
    return m


def orden_reexportar(opciones) -> int:
    """Rehace los MP3 desde los WAV intermedios, sin volver a generar voz."""
    salida = Path(opciones.salida)
    fuera = 0
    for wav in sorted((salida / "_wav").glob("*.wav")):
        if wav.name.endswith(".bruto.wav"):
            continue
        mp3 = salida / "audios" / f"{wav.stem}.mp3"
        a_mp3(wav, mp3)
        final = medir(mp3)
        ok = float(final["input_tp"]) <= -1.0 and abs(float(final["input_i"]) + 16) <= 1.0
        fuera += not ok
        print(f"  {'OK' if ok else 'FUERA':5s} {mp3.name:28s} {final['input_i']} LUFS  {final['input_tp']} dBTP")
    print(f"\n{fuera} archivos fuera de -16 LUFS (±1) o por encima de -1 dBTP.")
    return 1 if fuera else 0


# --- Texto, comparacion y subtitulos -----------------------------------------


def normalizar(texto: str) -> str:
    texto = unicodedata.normalize("NFKC", texto).lower()
    return "".join(c for c in texto if c.isalnum())


def error_por_caracter(guion: str, oido: str) -> float:
    a, b = normalizar(guion), normalizar(oido)
    if not a:
        return 0.0
    return 1 - difflib.SequenceMatcher(None, a, b, autojunk=False).ratio()


def tiempos_por_caracter(guion: str, palabras: list[dict], duracion: float) -> list[float]:
    """Tiempo de cada caracter del guion, alineando el guion con lo que oyo el
    reconocedor. Se alinea por caracteres y no por palabras para que sirva
    igual en japones o chino, que no separan palabras con espacios."""
    oido, t_oido = [], []
    for p in palabras:
        letras = normalizar(p.get("word", ""))
        ini, fin = float(p["start"]), float(p["end"])
        for i, c in enumerate(letras):
            oido.append(c)
            t_oido.append(ini + (fin - ini) * (i + 0.5) / max(len(letras), 1))
    guion_n = [c for c in unicodedata.normalize("NFKC", guion).lower()]
    tiempos: list[float | None] = [None] * len(guion_n)
    indices = [i for i, c in enumerate(guion_n) if c.isalnum()]
    seq = [guion_n[i] for i in indices]
    for bloque in difflib.SequenceMatcher(None, seq, oido, autojunk=False).get_matching_blocks():
        for k in range(bloque.size):
            tiempos[indices[bloque.a + k]] = t_oido[bloque.b + k]
    # Interpola lo que no se emparejo (puntuacion, palabras mal oidas).
    conocidos = [(i, t) for i, t in enumerate(tiempos) if t is not None]
    if not conocidos:
        return [duracion * i / max(len(guion_n), 1) for i in range(len(guion_n))]
    resultado = []
    for i in range(len(guion_n)):
        if tiempos[i] is not None:
            resultado.append(tiempos[i]); continue
        antes = max(((j, t) for j, t in conocidos if j < i), default=(0, 0.0))
        despues = min(((j, t) for j, t in conocidos if j > i), default=(len(guion_n), duracion))
        f = (i - antes[0]) / max(despues[0] - antes[0], 1)
        resultado.append(antes[1] + (despues[1] - antes[1]) * f)
    return resultado


def cortar_en_frases(texto: str, maximo: int) -> list[tuple[int, int]]:
    """Trozos de como mucho dos lineas de `maximo` caracteres, cortando
    primero por puntuacion y luego por espacios."""
    trozos, inicio = [], 0
    limite = 2 * maximo
    cortes = [m.end() for m in re.finditer(r"[.!?。！？]\s*|[,;:，、；：]\s*", texto)]
    while inicio < len(texto):
        fin = len(texto)
        if fin - inicio > limite:
            candidatos = [c for c in cortes if inicio < c <= inicio + limite]
            if candidatos:
                fin = candidatos[-1]
            else:
                espacio = texto.rfind(" ", inicio, inicio + limite)
                fin = espacio + 1 if espacio > inicio else inicio + limite
        else:
            siguientes = [c for c in cortes if inicio < c < fin and texto[c - 2:c].strip()[-1:] in ".!?。！？"]
            if siguientes and fin - inicio > maximo:
                fin = siguientes[0]
        trozos.append((inicio, fin))
        inicio = fin
    return [(a, b) for a, b in trozos if texto[a:b].strip()]


def en_lineas(texto: str, maximo: int) -> str:
    texto = texto.strip()
    if len(texto) <= maximo:
        return texto
    if " " not in texto:  # CJK: se parte por la mitad
        mitad = len(texto) // 2
        return texto[:mitad] + "\n" + texto[mitad:]
    mitad = len(texto) // 2
    espacios = [i for i, c in enumerate(texto) if c == " "]
    corte = min(espacios, key=lambda i: abs(i - mitad))
    return texto[:corte] + "\n" + texto[corte + 1:]


def marca(t: float) -> str:
    m, s = divmod(max(t, 0.0), 60)
    return f"{int(m):02d}:{s:06.3f}"


def vtt(guion: str, idioma: str, palabras: list[dict], duracion: float) -> str:
    maximo = 18 if idioma in CJK else 42
    tiempos = tiempos_por_caracter(guion, palabras, duracion)
    bloques = ["WEBVTT", ""]
    trozos = cortar_en_frases(guion, maximo)
    for n, (a, b) in enumerate(trozos, 1):
        ini = tiempos[a]
        fin = tiempos[min(b, len(tiempos)) - 1] + 0.25
        if n < len(trozos):
            fin = min(fin, tiempos[trozos[n][0]])
        fin = min(max(fin, ini + 1.0), duracion)
        bloques += [str(n), f"{marca(ini)} --> {marca(fin)}", en_lineas(guion[a:b], maximo), ""]
    return "\n".join(bloques)


# --- Ordenes -----------------------------------------------------------------


def cargar_guiones(idiomas: list[str] | None, lugares: list[str] | None):
    datos = json.loads(GUIONES.read_text(encoding="utf-8"))
    guiones = [g for g in datos["guiones"] if "pendiente" not in g]
    if lugares:
        guiones = [g for g in guiones if g["lugar"] in lugares]
    return guiones, idiomas or datos["idiomas"]


def orden_muestras(opciones) -> int:
    guiones, idiomas = cargar_guiones(opciones.idiomas, None)
    # La muestra lee el guion del Puente: es el mas largo y deja oir el ritmo.
    puente = next(g for g in guiones if g["lugar"] == "puente-a3-a5")
    salida = Path(opciones.salida)
    salida.mkdir(parents=True, exist_ok=True)
    for idioma in idiomas:
        for semilla in opciones.semillas:
            # La version en bruto es la que sirve de referencia para clonar;
            # la de escuchar lleva ya el ritmo con que sonaran los clips.
            variante = f"-{opciones.etiqueta}" if opciones.etiqueta else ""
            nombre = f"{idioma}{variante}-semilla{semilla}"
            bruto = salida / f"{nombre}.wav"
            bruto.write_bytes(generar_voz(puente["texto"][idioma], idioma, semilla=semilla,
                                          acento=opciones.acento))
            (salida / f"{nombre}.txt").write_text(puente["texto"][idioma], encoding="utf-8")
            escuchar = salida / f"{nombre}-escuchar.wav"
            ralentizar(bruto, escuchar, opciones.tempo)
            print(f"  {escuchar.name}")
    return 0


def tono_mediano(wav: Path) -> float:
    """F0 mediana en Hz, por autocorrelacion en ventanas de 40 ms."""
    import wave
    import numpy as np

    with wave.open(str(wav)) as w:
        sr = w.getframerate()
        x = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(float) / 32768
    n, paso, tonos = int(0.04 * sr), int(0.01 * sr), []
    lo, hi = int(sr / 400), int(sr / 70)
    for i in range(0, len(x) - n, paso):
        t = x[i:i + n] * np.hanning(n)
        if np.sqrt(np.mean(t ** 2)) < 0.01:
            continue
        espectro = np.fft.rfft(t, 2 * n)
        ac = np.fft.irfft(espectro * np.conj(espectro))[:n]
        k = lo + int(np.argmax(ac[lo:hi]))
        if ac[k] > 0.35 * ac[0]:
            tonos.append(sr / k)
    return float(np.median(tonos)) if tonos else 0.0


def orden_elegir(opciones) -> int:
    """Escoge por idioma la candidata de `muestras` que mejor dice su texto.

    Primero la que, transcrita, mas se parece al guion; entre las que empatan
    por menos de 2 puntos, la de tono mas cercano a la voz espanola elegida.
    Copia la elegida a `--voces` y deja las demas donde estan, por si alguien
    prefiere otra al escucharlas."""
    muestras, voces = Path(opciones.muestras), Path(opciones.voces)
    objetivo = tono_mediano(voces / "es.wav")
    print(f"tono de la voz espanola: {objetivo:.0f} Hz")
    for idioma in opciones.idiomas:
        candidatas = []
        for wav in sorted(muestras.glob(f"{idioma}-semilla*.wav")):
            if wav.stem.endswith("-escuchar"):
                continue
            texto = wav.with_suffix(".txt").read_text(encoding="utf-8")
            oido = transcribir(wav, idioma).get("text", "")
            candidatas.append((error_por_caracter(texto, oido), abs(tono_mediano(wav) - objetivo), wav, oido))
        if not candidatas:
            print(f"[{idioma}] sin candidatas en {muestras}")
            continue
        mejor_error = min(c[0] for c in candidatas)
        empatadas = [c for c in candidatas if c[0] <= mejor_error + 0.02]
        error, distancia, elegida, _ = min(empatadas, key=lambda c: c[1])
        shutil.copyfile(elegida, voces / f"{idioma}.wav")
        shutil.copyfile(elegida.with_suffix(".txt"), voces / f"{idioma}.txt")
        resumen = ", ".join(f"{c[2].stem.split('-')[-1]} {c[0]:.0%}" for c in candidatas)
        print(f"[{idioma}] {elegida.stem}  error {error:.1%}  tono a {distancia:.0f} Hz  ({resumen})")
    return 0


def orden_generar(opciones) -> int:
    guiones, idiomas = cargar_guiones(opciones.idiomas, opciones.lugares)
    voces, salida = Path(opciones.voces), Path(opciones.salida)
    crudos = salida / "_wav"
    crudos.mkdir(parents=True, exist_ok=True)
    informe = []
    for idioma in idiomas:
        referencia = voces / f"{idioma}.wav"
        if not referencia.exists():
            print(f"[{idioma}] sin voz elegida en {referencia}; se salta")
            continue
        texto_ref = (voces / f"{idioma}.txt").read_text(encoding="utf-8").strip()
        sufijo = "" if idioma == "es" else f".{idioma}"
        for g in guiones:
            guion = g["texto"][idioma]
            bruto = crudos / f"{g['lugar']}{sufijo}.bruto.wav"
            bruto.write_bytes(generar_voz(guion, idioma, semilla=opciones.semilla,
                                          referencia=referencia, texto_referencia=texto_ref))
            wav = crudos / f"{g['lugar']}{sufijo}.wav"
            ralentizar(bruto, wav, opciones.tempo)
            oido = transcribir(wav, idioma)
            palabras = oido.get("words") or [w for s in oido.get("segments", []) for w in s.get("words", [])]
            duracion = float(oido.get("duration") or (palabras[-1]["end"] if palabras else 0))
            error = error_por_caracter(guion, oido.get("text", ""))
            medida = a_mp3(wav, salida / "audios" / f"{g['lugar']}{sufijo}.mp3")
            subs = salida / "subtitulos" / f"{g['lugar']}{sufijo}.vtt"
            subs.parent.mkdir(parents=True, exist_ok=True)
            subs.write_text(vtt(guion, idioma, palabras, duracion), encoding="utf-8")
            estado = "OK" if error <= opciones.tolerancia else "REVISAR"
            informe.append({"lugar": g["lugar"], "idioma": idioma, "segundos": round(duracion, 1),
                            "error_caracteres": round(error, 3), "estado": estado,
                            "oido": oido.get("text", ""), "lufs_original": medida["input_i"]})
            print(f"  {estado:7s} {g['lugar']}{sufijo}  {duracion:5.1f}s  error {error:.1%}")
    # Fusiona con el informe anterior: rehacer un solo clip no borra los demas.
    ruta_informe = salida / "informe.json"
    if ruta_informe.exists():
        nuevos = {(i["lugar"], i["idioma"]) for i in informe}
        previo = json.loads(ruta_informe.read_text(encoding="utf-8"))
        informe = [i for i in previo if (i["lugar"], i["idioma"]) not in nuevos] + informe
    ruta_informe.write_text(json.dumps(informe, ensure_ascii=False, indent=2), encoding="utf-8")
    malos = [i for i in informe if i["estado"] != "OK"]
    print(f"\n{len(informe) - len(malos)} de {len(informe)} clips sin diferencias con el guion."
          + (" Revisar a oido los marcados." if malos else ""))
    return 0


def main() -> int:
    global API
    analizador = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    analizador.add_argument("--api", default=API)
    analizador.add_argument("--tempo", type=float, default=TEMPO,
                            help="factor de atempo al exportar (1 = sin cambio)")
    sub = analizador.add_subparsers(dest="orden", required=True)
    m = sub.add_parser("muestras", help="voces candidatas para elegir")
    m.add_argument("--idiomas", nargs="+")
    m.add_argument("--semillas", nargs="+", type=int, default=[1, 2, 3])
    m.add_argument("--salida", required=True)
    m.add_argument("--acento", help="sustituye el acento del idioma en la descripcion")
    m.add_argument("--etiqueta", default="", help="nombre para distinguir variantes, p. ej. neutra")
    e = sub.add_parser("elegir", help="escoge por idioma la candidata que mejor dice su texto")
    e.add_argument("--muestras", required=True)
    e.add_argument("--voces", required=True)
    e.add_argument("--idiomas", nargs="+", required=True)
    r = sub.add_parser("reexportar", help="rehace los MP3 desde los WAV intermedios")
    r.add_argument("--salida", required=True)
    g = sub.add_parser("generar", help="todos los clips con la voz elegida")
    g.add_argument("--voces", required=True, help="carpeta con <idioma>.wav y <idioma>.txt")
    g.add_argument("--salida", required=True)
    g.add_argument("--idiomas", nargs="+")
    g.add_argument("--lugares", nargs="+")
    g.add_argument("--semilla", type=int, default=7)
    g.add_argument("--tolerancia", type=float, default=0.08,
                   help="error por caracter aceptable frente al guion (0.08 = 8 %%)")
    opciones = analizador.parse_args()
    API = opciones.api.rstrip("/")
    ordenes = {"muestras": orden_muestras, "elegir": orden_elegir, "generar": orden_generar,
               "reexportar": orden_reexportar}
    return ordenes[opciones.orden](opciones)


if __name__ == "__main__":
    sys.exit(main())
