"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const items = [
  { href: "/pois", label: "POIs", ready: true },
  { href: "/escenas", label: "Escenas 360", ready: false },
  { href: "/medios", label: "Medios", ready: false },
  { href: "/rutas", label: "Rutas", ready: false },
  { href: "/campus", label: "Campus", ready: false },
];

export function Sidebar() {
  const pathname = usePathname();

  return (
    <nav className="flex w-56 shrink-0 flex-col gap-1 border-r border-neutral-500/30 p-4">
      <p className="mb-4 text-lg font-semibold">Tour Virtual UTB</p>
      {items.map((item) =>
        item.ready ? (
          <Link
            key={item.href}
            href={item.href}
            className={`rounded px-3 py-2 hover:bg-neutral-500/20 ${
              pathname.startsWith(item.href) ? "bg-neutral-500/30 font-medium" : ""
            }`}
          >
            {item.label}
          </Link>
        ) : (
          <span
            key={item.href}
            className="cursor-not-allowed rounded px-3 py-2 opacity-40"
          >
            {item.label}
          </span>
        )
      )}
    </nav>
  );
}