"""El catálogo de MAPSUTB se convierte sin red y sin perder lugares."""
import json
import unittest
from pathlib import Path

import espacios_mapsutb as espacios

POIS = {p["id"]: p for p in json.loads(espacios.CATALOGO.read_text(encoding="utf-8"))}


def zona(ident, espacios_zona=(), lat=10.37, lng=-75.465):
    return {"id": ident, "nombre": f"Zona {ident}", "tipo": "Edificio", "lat": lat, "lng": lng,
            "pisos": [{"id": f"{ident}-piso1", "nombre": "Primer Piso"}], "espacios": list(espacios_zona)}


class ConversionTest(unittest.TestCase):
    def test_cada_edificio_lleva_al_lugar_con_su_entrada(self):
        salida = espacios.convertir([
            zona("a2", [{"id": "a2-esp-x", "nombre": "Salones  401-408", "tipo": "salon",
                         "pisos": ["a2-piso1"], "salones": [{"id": "a2-401", "nombre": "401",
                                                             "descripcion": "texto genérico"}]}]),
            zona("eda2"),
        ], POIS)
        a2, eda2 = salida["edificios"]
        self.assertEqual(a2["poi_id"], 7)
        self.assertEqual(a2["espacios"][0]["nombre"], "Salones 401-408")
        self.assertEqual(a2["espacios"][0]["salones"], [{"id": "a2-401", "nombre": "401"}])
        self.assertEqual((eda2["poi_id"], eda2["nota"]), (11, "junto al Edificio Alcatraz"))

    def test_un_espacio_que_es_un_lugar_del_tour_lleva_a_su_propia_entrada(self):
        salida = espacios.convertir([zona("zonat", [{"id": "zonat-esp-enfermeria", "nombre": "Enfermería",
                                                      "tipo": "servicio", "pisos": [], "salones": []}])], POIS)
        self.assertEqual(salida["edificios"][0]["espacios"][0]["poi_id"], 3)

    def test_una_zona_nueva_de_mapsutb_no_se_pierde_en_silencio(self):
        with self.assertRaisesRegex(ValueError, "sin lugar del tour: a9"):
            espacios.convertir([zona("a9")], POIS)

    def test_sin_ubicacion_queda_anotado_y_fuera_de_la_guia(self):
        salida = espacios.convertir([zona("contenedores", [{"id": "c1", "nombre": "Semilleros", "tipo": "servicio",
                                                             "pisos": [], "salones": []}], lat=0, lng=0)], POIS)
        self.assertEqual(salida["edificios"], [])
        self.assertEqual(salida["sin_ubicacion"], [{"zona": "Zona contenedores", "espacios": ["Semilleros"]}])

    def test_el_archivo_de_la_app_esta_al_dia_con_las_tablas(self):
        datos = json.loads(espacios.SALIDA.read_text(encoding="utf-8"))
        self.assertEqual(datos["formato"], "espacios-campus-1")
        self.assertIn(espacios.COMMIT[:7], datos["fuente"])
        for edificio in datos["edificios"]:
            self.assertEqual(edificio["poi_id"], espacios.ZONA_A_POI[edificio["id"]])
            for e in edificio["espacios"]:
                if e["id"] in espacios.ESPACIO_A_POI:
                    self.assertEqual(e["poi_id"], espacios.ESPACIO_A_POI[e["id"]])
                pisos = {p["id"] for p in edificio["pisos"]}
                self.assertTrue(set(e["pisos"]) <= pisos | {""}, e["id"])


if __name__ == "__main__":
    unittest.main()
