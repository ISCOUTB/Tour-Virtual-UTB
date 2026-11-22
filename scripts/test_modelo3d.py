"""Verifica la preparación del GLB sin descargar recursos externos."""
import json
import struct
import unittest

from preparar_modelo3d import preparar


class PrepararModeloTest(unittest.TestCase):
    def test_excluye_la_referencia_y_conserva_la_geometria_binaria(self):
        modelo = {"asset": {"version": "2.0"}, "scenes": [{"nodes": [0, 1]}],
                  "nodes": [{"name": "Terreno", "children": [1]}, {"name": "Plano_Referencia"}]}
        bloque = json.dumps(modelo).encode()
        bloque += b" " * (-len(bloque) % 4)
        geometria = struct.pack("<II", 4, 0x004E4942) + b"ABCD"
        original = (struct.pack("<III", 0x46546C67, 2, 20 + len(bloque) + len(geometria))
                    + struct.pack("<II", len(bloque), 0x4E4F534A) + bloque + geometria)
        resultado = preparar(original)
        largo = struct.unpack_from("<I", resultado, 12)[0]
        convertido = json.loads(resultado[20:20 + largo])
        self.assertEqual(convertido["scenes"][0]["nodes"], [0])
        self.assertEqual(convertido["nodes"][0]["children"], [])
        self.assertEqual(resultado[20 + largo:], geometria)
        self.assertEqual(struct.unpack_from("<I", resultado, 8)[0], len(resultado))

    def test_excluye_los_rotulos_horneados(self):
        modelo = {"asset": {"version": "2.0"}, "scenes": [{"nodes": [0, 1, 2]}],
                  "nodes": [{"name": "Biblioteca_1"}, {"name": "Etq_Biblioteca"},
                            {"name": "Etiquetas_no"}]}
        bloque = json.dumps(modelo).encode()
        bloque += b" " * (-len(bloque) % 4)
        original = (struct.pack("<III", 0x46546C67, 2, 20 + len(bloque))
                    + struct.pack("<II", len(bloque), 0x4E4F534A) + bloque)
        resultado = preparar(original)
        largo = struct.unpack_from("<I", resultado, 12)[0]
        convertido = json.loads(resultado[20:20 + largo])
        self.assertEqual(convertido["scenes"][0]["nodes"], [0, 2])

    def test_rechaza_un_archivo_que_no_es_glb(self):
        with self.assertRaises(ValueError):
            preparar(b"un archivo distinto")
