"use client";

import { useEffect, useState } from "react";
import { api, type Poi } from "@/lib/api";

export default function PoisPage() {
  const [pois, setPois] = useState<Poi[] | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    api<Poi[]>("/api/lugares/1/pois")
      .then(setPois)
      .catch((e: Error) => setError(e.message));
  }, []);

  if (error) return <p className="p-6 text-red-600">Error: {error}</p>;
  if (!pois) return <p className="p-6">Cargando…</p>;

  return (
    <main className="p-6">
      <h1 className="mb-4 text-2xl font-semibold">POIs</h1>
      <table className="w-full border-collapse text-left">
        <thead>
          <tr className="border-b">
            <th className="p-2">ID</th>
            <th className="p-2">Nombre</th>
            <th className="p-2">Categoría</th>
            <th className="p-2">Audiencias</th>
            <th className="p-2">Activo</th>
          </tr>
        </thead>
        <tbody>
          {pois.map((p) => (
            <tr key={p.id} className="border-b">
              <td className="p-2">{p.id}</td>
              <td className="p-2">{p.nombre}</td>
              <td className="p-2">{p.categoria}</td>
              <td className="p-2">{p.audiencias?.join(", ")}</td>
              <td className="p-2">{p.activo ? "Sí" : "No"}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </main>
  );
}