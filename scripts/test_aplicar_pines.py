"""Las entradas corregidas en el campus mueven los pines, sin tocar archivos."""
import json
import tempfile
import unittest
from pathlib import Path

import aplicar_pines as pines


class CorreccionesDeCampoTest(unittest.TestCase):
    def test_la_entrada_principal_corregida_mueve_el_pin(self):
        ajustes = [
            {"poi_id": 4, "nombre": "Zona T", "lat": 10.3695, "lng": -75.4657, "principal": True},
            # Pin aparte: la Cancha de fútbol conserva el suyo en el centro.
            {"poi_id": 16, "nombre": "Cancha de fútbol", "lat": 10.37, "lng": -75.466,
             "principal": True, "pin": {"lat": 10.3701, "lng": -75.4667}},
        ]
        correcciones = {"formato": "correcciones-guia-1", "anuladas": ["deshecha"], "correcciones": [
            {"id": "a", "tipo": "entrada", "fecha": "2026-11-23T10:00:00", "autor": "Kevin",
             "poi_id": 4, "nombre": "Zona T", "lat": 10.36945, "lng": -75.46565},
            {"id": "deshecha", "tipo": "entrada", "fecha": "2026-11-23T11:00:00",
             "poi_id": 4, "nombre": "Zona T", "lat": 10.3, "lng": -75.4},
            {"id": "b", "tipo": "entrada", "fecha": "2026-11-23T10:05:00",
             "poi_id": 16, "nombre": "Cancha de fútbol", "lat": 10.37005, "lng": -75.46605},
            # Una entrada nueva no es la principal: no mueve nada.
            {"id": "c", "tipo": "entrada", "fecha": "2026-11-23T10:10:00",
             "poi_id": 4, "nombre": "Zona T, entrada 2", "lat": 10.2, "lng": -75.2},
        ]}
        with tempfile.TemporaryDirectory() as carpeta:
            archivo = Path(carpeta) / "correcciones-kevin.json"
            archivo.write_text(json.dumps(correcciones), encoding="utf-8")
            nuevos = pines.pines(pines.con_correcciones(ajustes, [archivo]))
        self.assertEqual(nuevos[4][:2], (10.36945, -75.46565))
        self.assertIn("en el campus (Kevin)", nuevos[4][2])
        self.assertEqual(nuevos[16][:2], (10.3701, -75.4667))

    def test_un_archivo_que_no_es_de_correcciones_se_rechaza(self):
        with tempfile.TemporaryDirectory() as carpeta:
            archivo = Path(carpeta) / "otro.json"
            archivo.write_text(json.dumps({"accesos": []}), encoding="utf-8")
            with self.assertRaises(SystemExit):
                pines.con_correcciones([], [archivo])


if __name__ == "__main__":
    unittest.main()
