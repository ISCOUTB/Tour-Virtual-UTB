"""Regresiones del flujo de importación de los datos de campo, sin red."""
import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import grafo_campus as grafo


class ImportacionTest(unittest.TestCase):
    def test_comodines_y_exportaciones_acumuladas_sin_duplicados(self):
        medida = {"poi_id": 1, "nombre": "Biblioteca", "lat": 10.37,
                  "lng": -75.465, "precision": 3, "fecha": "2026-11-23T09:00:00"}
        segunda = {**medida, "fecha": "2026-11-24T09:00:00"}
        with tempfile.TemporaryDirectory() as carpeta:
            raiz = Path(carpeta)
            primero = raiz / "levantamiento-dia1.json"
            primero.write_text(json.dumps({"accesos": [medida]}), encoding="utf-8")
            (raiz / "levantamiento-dia2.json").write_text(
                json.dumps({"accesos": [medida, segunda]}), encoding="utf-8")
            datos = grafo.cargar_levantamientos([str(raiz / "levantamiento-*.json"), str(primero)])
        self.assertEqual(datos["accesos"], [medida, segunda])
        self.assertEqual(grafo.evaluar_acceso(datos["accesos"])["estado"], "aceptado")

    def test_un_patron_sin_archivos_no_borra_las_mediciones_del_grafo(self):
        with tempfile.TemporaryDirectory() as carpeta:
            with self.assertRaisesRegex(FileNotFoundError, "No hay levantamientos"):
                grafo.cargar_levantamientos([str(Path(carpeta) / "levantamiento-*.json")])

    def test_corregir_declinacion_actualiza_el_norte_de_datos_anteriores(self):
        datos = grafo.cargar_levantamientos([])
        datos["nortes"] = [{"poi_id": 1, "objeto": "puerta", "rumbo_magnetico": 90,
                            "rumbo_geografico": 82.3, "yaw_objeto": 100}]
        texto = grafo.informe(datos, [{"id": 1, "nombre": "Biblioteca", "es_parada": True}], [], -5)
        self.assertIn("85.0° | 100.0° | 15.0°", texto)
        self.assertNotIn("82.3°", texto)

    def test_dos_comprobaciones_no_certifican_la_brujula(self):
        datos = grafo.cargar_levantamientos([])
        datos["brujula"] = [{"error": 1}, {"error": 1}]
        self.assertIn("RNF-27 **NO cumple**", grafo.informe(datos, [], [], -7.7))

    def test_recalibrar_no_vuelve_a_restar_el_sesgo_anterior(self):
        medida = {"rumbo_tramo": 85, "rumbo_magnetico": 90,
                  "declinacion": -7.7, "error": -2.7}
        self.assertAlmostEqual(grafo.errores_brujula([medida], -7.7)[0], -2.7)
        self.assertAlmostEqual(grafo.errores_brujula([medida], -5)[0], 0)

    def test_una_puerta_con_gps_impreciso_no_aprueba_la_guia(self):
        datos = grafo.cargar_levantamientos([])
        punto = {"lat": 10.37, "lng": -75.465, "precision": 3}
        datos["pruebas"] = [{"llegada_app": punto, "puerta_real": {**punto, "precision": 30}}]
        self.assertIn("| ❌ |", grafo.informe(datos, [], [], -7.7))

    def test_informe_no_modifica_el_grafo(self):
        with tempfile.TemporaryDirectory() as carpeta:
            salida = Path(carpeta) / "grafo.json"
            salida.write_text("grafo previo", encoding="utf-8")
            with patch.object(grafo, "SALIDA", salida), contextlib.redirect_stdout(io.StringIO()) as log:
                grafo.main([], solo_informe=True)
            self.assertIn("27 aceptadas", log.getvalue())
            self.assertEqual(salida.read_text(encoding="utf-8"), "grafo previo")

    def test_el_volcado_de_android_se_lee_como_un_levantamiento(self):
        medida = {"poi_id": 1, "nombre": "Biblioteca", "lat": 10.37,
                  "lng": -75.465, "precision": 3, "fecha": "2026-11-21T09:00:00"}
        with tempfile.TemporaryDirectory() as carpeta:
            ruta = Path(carpeta) / "kevin.json"
            ruta.write_text(json.dumps({"flutter.levantamiento.datos": json.dumps(
                {"formato": 2, "accesos": [medida]})}), encoding="utf-8")
            datos = grafo.cargar_levantamientos([str(ruta)])
        self.assertEqual(datos["accesos"], [medida])

    def test_un_ajuste_manual_manda_sobre_las_medidas_y_verifica(self):
        medida = {"poi_id": 4, "nombre": "Zona T", "lat": 10.3696, "lng": -75.4658,
                  "precision": 3, "fecha": "2026-11-21T09:00:00"}
        ajuste = {"formato": grafo.FORMATO_AJUSTES, "generado": "2026-11-21T22:00:00Z",
                  "entradas": [{"poi_id": 4, "nombre": "Zona T", "lat": 10.3695,
                                "lng": -75.4657, "principal": True, "nota": "puerta norte"}]}
        with tempfile.TemporaryDirectory() as carpeta:
            raiz = Path(carpeta)
            (raiz / "jose.json").write_text(json.dumps({"accesos": [medida]}), encoding="utf-8")
            (raiz / "ajustes.json").write_text(json.dumps(ajuste), encoding="utf-8")
            salida = raiz / "grafo.json"
            with patch.object(grafo, "SALIDA", salida), contextlib.redirect_stdout(io.StringIO()):
                grafo.main([str(raiz / "*.json")])
            zona_t = next(a for a in json.loads(salida.read_text(encoding="utf-8"))["accesos"]
                          if a["nombre"] == "Zona T")
        self.assertTrue(zona_t["verificado"])
        self.assertAlmostEqual(zona_t["lat"], 10.3695, places=6)
        self.assertIn("puerta norte", zona_t["fuente"])

    def test_las_correcciones_de_campo_llegan_al_grafo(self):
        """Lo que se corrigió con la guía en el campus (botón «Copiar» del modo
        campo) entra al grafo oficial: manda sobre el ajuste satelital, cierra
        el tramo, agrega el camino y no revive lo deshecho."""
        actual = json.loads(grafo.SALIDA.read_text(encoding="utf-8"))
        nodos = {n["id"]: n for n in actual["nodos"]}
        sendero = next(e for e in actual["aristas"] if e["tipo"] == "sendero" and e["metros"] > 20)
        a, b = nodos[sendero["a"]], nodos[sendero["b"]]
        ajuste = {"formato": grafo.FORMATO_AJUSTES, "generado": "2026-11-21T22:00:00Z",
                  "entradas": [{"poi_id": 4, "nombre": "Zona T", "lat": 10.3695,
                                "lng": -75.4657, "principal": True}]}
        correcciones = {"formato": grafo.FORMATO_CORRECCIONES, "anuladas": ["deshecha"], "correcciones": [
            {"id": "e1", "tipo": "entrada", "fecha": "2026-11-23T10:00:00", "autor": "Laura",
             "poi_id": 4, "nombre": "Zona T", "lat": 10.36945, "lng": -75.46565, "precision": 3.5},
            {"id": "deshecha", "tipo": "entrada", "fecha": "2026-11-23T11:00:00",
             "poi_id": 4, "nombre": "Zona T", "lat": 10.3, "lng": -75.4},
            {"id": "t1", "tipo": "tramo", "fecha": "2026-11-23T10:05:00",
             "desde": {"lat": a["lat"], "lng": a["lng"]}, "hasta": {"lat": b["lat"], "lng": b["lng"]},
             "bloqueado": True},
            {"id": "c1", "tipo": "camino", "fecha": "2026-11-23T10:10:00", "escalones": False,
             "puntos": [{"lat": a["lat"] + 0.00005, "lng": a["lng"]},
                        {"lat": a["lat"] + 0.0003, "lng": a["lng"] + 0.0002}]},
            {"id": "n1", "tipo": "nota", "fecha": "2026-11-23T10:15:00", "texto": "Reja cerrada",
             "lat": 10.37, "lng": -75.465},
        ]}
        with tempfile.TemporaryDirectory() as carpeta:
            raiz = Path(carpeta)
            (raiz / "ajustes.json").write_text(json.dumps(ajuste), encoding="utf-8")
            (raiz / "correcciones-laura.json").write_text(json.dumps(correcciones), encoding="utf-8")
            # Fuera de la carpeta del comodín: si no, el informe lo leería.
            (raiz / "salida").mkdir()
            salida = raiz / "salida" / "grafo.json"
            with patch.object(grafo, "SALIDA", salida), contextlib.redirect_stdout(io.StringIO()):
                grafo.main([str(raiz / "*.json")])
            with contextlib.redirect_stdout(io.StringIO()) as log:
                grafo.main([str(raiz / "*.json")], solo_informe=True)
            nuevo = json.loads(salida.read_text(encoding="utf-8"))
        zona_t = next(x for x in nuevo["accesos"] if x["nombre"] == "Zona T")
        self.assertAlmostEqual(zona_t["lat"], 10.36945, places=6)
        self.assertIn("corregida en el campus (Laura)", zona_t["fuente"])
        por_id = {n["id"]: n for n in nuevo["nodos"]}

        def sobre_el_cerrado(e):
            return all(grafo.metros((por_id[x]["lat"], por_id[x]["lng"]), (p["lat"], p["lng"])) < 1
                       for x, p in zip((e["a"], e["b"]), (a, b))) or \
                all(grafo.metros((por_id[x]["lat"], por_id[x]["lng"]), (p["lat"], p["lng"])) < 1
                    for x, p in zip((e["b"], e["a"]), (a, b)))
        self.assertFalse(any(sobre_el_cerrado(e) for e in nuevo["aristas"]))
        self.assertTrue(any(abs(por_id[e["b"]]["lat"] - (a["lat"] + 0.0003)) < 1e-6 or
                            abs(por_id[e["a"]]["lat"] - (a["lat"] + 0.0003)) < 1e-6
                            for e in nuevo["aristas"]))
        self.assertIn("Correcciones de la guía en el campus", log.getvalue())
        self.assertIn("Reja cerrada", log.getvalue())


if __name__ == "__main__":
    unittest.main()
