-- =============================================================================
-- 0001 — Esquema de contenido
--
-- Las tablas de contenido usan `bigint generated always as identity` en lugar
-- de uuid para mantener compatibilidad con la API .NET existente, que ya
-- expone identificadores enteros (por ejemplo GET /api/Escenas/lugar/1).
-- Los identificadores son publicos y el contenido tambien, asi que la
-- enumerabilidad no representa un riesgo aqui.
--
-- Las tablas ligadas a usuarios (perfiles, consentimientos, eventos) usan uuid
-- porque referencian auth.users.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Tipos
-- -----------------------------------------------------------------------------

-- 'externo' cubre a aspirantes, familias y publico general que no pertenece a
-- la universidad. No implica extranjeria.
create type public.rol_usuario as enum ('externo', 'estudiante', 'docente', 'admin');

-- Espejo de rol_usuario sin 'admin': el rol administrativo no define contenido,
-- solo permisos.
create type public.audiencia as enum ('externo', 'estudiante', 'docente');

create type public.tipo_medio as enum ('imagen', 'video', 'audio');

-- 'navegacion' salta a otra escena; 'info' abre la ficha del POI.
create type public.tipo_hotspot as enum ('navegacion', 'info');

-- -----------------------------------------------------------------------------
-- Contenido
-- -----------------------------------------------------------------------------

create table public.lugares (
  id          bigint generated always as identity primary key,
  nombre      text not null,
  slug        text not null unique,
  creado_en   timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

comment on table public.lugares is
  'Sedes o campus. El MVP solo contempla el campus principal de Ternera.';

create table public.pois (
  id           bigint generated always as identity primary key,
  lugar_id     bigint not null references public.lugares (id) on delete cascade,
  nombre       text not null,
  categoria    text,
  descripcion  text,

  -- Coordenadas geograficas reales. Todavia no se usan: el mapa del MVP es un
  -- render ilustrado. Se capturan desde ya para poder migrar a cartografia
  -- real sin volver a levantar los datos.
  lat          double precision,
  lng          double precision,

  -- Posicion del marcador sobre el render ilustrado, normalizada a [0,1].
  -- Reemplaza la generacion aleatoria que hacia el cliente.
  map_x        double precision check (map_x between 0 and 1),
  map_y        double precision check (map_y between 0 and 1),

  audiencias   public.audiencia[] not null default
                 array['externo','estudiante','docente']::public.audiencia[],
  activo       boolean not null default true,
  creado_en    timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

create index pois_lugar_idx on public.pois (lugar_id) where activo;
create index pois_audiencias_idx on public.pois using gin (audiencias);

create table public.escenas (
  id                  bigint generated always as identity primary key,
  lugar_id            bigint not null references public.lugares (id) on delete cascade,
  poi_id              bigint references public.pois (id) on delete set null,
  nombre              text,

  -- URL en Cloudflare R2. La panoramica solo llega aqui despues de pasar por
  -- el pipeline de ingesta: difuminado de rostros, revision manual, limpieza
  -- de EXIF y compresion. Ver docs/arquitectura.md seccion 7.1.
  imagen_url          text not null,
  imagen_url_baja     text,

  es_escena_principal boolean not null default false,
  orden               integer not null default 0,
  creado_en           timestamptz not null default now(),
  actualizado_en      timestamptz not null default now()
);

create index escenas_lugar_idx on public.escenas (lugar_id);

-- Solo puede haber una escena principal por lugar: es el punto de entrada del
-- recorrido. El cliente actual hace firstWhere sobre esEscenaPrincipal y
-- asume unicidad, asi que se garantiza en la base.
create unique index escenas_una_principal_por_lugar
  on public.escenas (lugar_id)
  where es_escena_principal;

alter table public.pois
  add column escena_principal_id bigint references public.escenas (id) on delete set null;

create table public.hotspots (
  id                 bigint generated always as identity primary key,
  escena_id          bigint not null references public.escenas (id) on delete cascade,
  tipo               public.tipo_hotspot not null default 'navegacion',

  -- Coordenadas esfericas en grados. El visor las consume como
  -- Hotspot.latitude (pitch) y Hotspot.longitude (yaw).
  pitch              double precision not null check (pitch between -90 and 90),
  yaw                double precision not null check (yaw between -180 and 180),

  escena_destino_id  bigint references public.escenas (id) on delete cascade,
  poi_id             bigint references public.pois (id) on delete cascade,
  etiqueta           text,
  creado_en          timestamptz not null default now(),

  -- Un hotspot de navegacion necesita destino; uno de informacion necesita POI.
  constraint hotspot_destino_coherente check (
    (tipo = 'navegacion' and escena_destino_id is not null) or
    (tipo = 'info' and poi_id is not null)
  ),

  -- Un hotspot que navega a su propia escena deja al usuario atrapado.
  constraint hotspot_sin_autoreferencia check (escena_destino_id is distinct from escena_id)
);

create index hotspots_escena_idx on public.hotspots (escena_id);

create table public.medios (
  id             bigint generated always as identity primary key,
  poi_id         bigint not null references public.pois (id) on delete cascade,
  tipo           public.tipo_medio not null,
  url            text not null,
  orden          integer not null default 0,
  duracion_seg   integer check (duracion_seg is null or duracion_seg > 0),

  -- Obligatorios para accesibilidad WCAG 2.2 AA. No se declaran NOT NULL para
  -- no bloquear la carga inicial de contenido, pero el panel de administracion
  -- debe exigirlos antes de publicar.
  texto_alt      text,
  subtitulos_url text,

  creado_en      timestamptz not null default now()
);

create index medios_poi_idx on public.medios (poi_id, tipo, orden);

-- -----------------------------------------------------------------------------
-- Rutas: un recorrido curado por tipo de usuario
-- -----------------------------------------------------------------------------

create table public.rutas (
  id          bigint generated always as identity primary key,
  lugar_id    bigint not null references public.lugares (id) on delete cascade,
  nombre      text not null,
  descripcion text,
  audiencia   public.audiencia not null,
  activa      boolean not null default true,
  creado_en   timestamptz not null default now()
);

create table public.ruta_pois (
  ruta_id  bigint not null references public.rutas (id) on delete cascade,
  poi_id   bigint not null references public.pois (id) on delete cascade,
  orden    integer not null,
  primary key (ruta_id, poi_id),
  unique (ruta_id, orden) deferrable initially deferred
);

-- -----------------------------------------------------------------------------
-- Traducciones
-- -----------------------------------------------------------------------------
-- La internacionalizacion esta diferida a la Fase 4, pero el esquema se crea
-- desde ahora: incorporarlo mas tarde obligaria a migrar todo el contenido ya
-- cargado.

create table public.traducciones (
  entidad     text not null,
  entidad_id  bigint not null,
  campo       text not null,
  idioma      text not null check (idioma ~ '^[a-z]{2}(-[A-Z]{2})?$'),
  valor       text not null,
  primary key (entidad, entidad_id, campo, idioma)
);

-- -----------------------------------------------------------------------------
-- actualizado_en automatico
-- -----------------------------------------------------------------------------

create or replace function public.tocar_actualizado_en()
returns trigger
language plpgsql
as $$
begin
  new.actualizado_en := now();
  return new;
end;
$$;

create trigger lugares_actualizado_en before update on public.lugares
  for each row execute function public.tocar_actualizado_en();
create trigger pois_actualizado_en before update on public.pois
  for each row execute function public.tocar_actualizado_en();
create trigger escenas_actualizado_en before update on public.escenas
  for each row execute function public.tocar_actualizado_en();
