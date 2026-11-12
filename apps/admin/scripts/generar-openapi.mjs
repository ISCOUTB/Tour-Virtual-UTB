// Copia el contrato OpenAPI de la API local a packages/contracts/openapi.yaml.
//
// El archivo sale del Swagger de la API (Swashbuckle lo sirve tambien en
// YAML), asi que siempre coincide con los endpoints reales. La API tiene que
// estar corriendo en modo Development:
//
//   cd services/api && dotnet run --launch-profile http
//
// Otra direccion: API_URL=http://localhost:5000 npm run generar:openapi

import { writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";

const api = process.env.API_URL ?? "http://localhost:5209";
const origen = `${api}/swagger/v1/swagger.yaml`;
const destino = fileURLToPath(
  new URL("../../../packages/contracts/openapi.yaml", import.meta.url),
);

const encabezado = [
  "# Archivo generado desde el Swagger de la API. No lo edites a mano:",
  "# cambia el codigo de services/api y ejecuta en apps/admin",
  "# `npm run generar:openapi` con la API corriendo.",
  "",
].join("\n");

let respuesta;
try {
  respuesta = await fetch(origen);
} catch {
  console.error(`No se pudo conectar con ${origen}.`);
  console.error("Arranca la API: cd services/api && dotnet run --launch-profile http");
  process.exit(1);
}
if (!respuesta.ok) {
  console.error(`${origen} respondio ${respuesta.status}.`);
  process.exit(1);
}

const yaml = (await respuesta.text()).replace(/\r\n/g, "\n").trimEnd();
await writeFile(destino, `${encabezado}${yaml}\n`, "utf8");
console.log(`Contrato guardado en ${destino}`);
