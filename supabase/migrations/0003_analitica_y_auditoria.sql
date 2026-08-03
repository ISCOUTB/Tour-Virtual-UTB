-- =============================================================================
-- 0003 — Analitica y auditoria
-- =============================================================================

-- Eventos de uso. Cubren los KPI definidos en docs/utb-tour-inmersivo-mvp.md:
-- virtual_map_open, scene_viewed, hotspot_tapped, poi_media_played,
-- tour_completed.
create table public.eventos (
  id         bigint generated always as identity primary key,

  -- Identificador de sesion generado en el cliente. Permite medir recorridos
  -- de visitantes anonimos sin asociarlos a una persona.
  sesion_id  uuid not null,

  user_id    uuid references auth.users (id) on delete set null,
  rol        public.rol_usuario,
  tipo       text not null,
  poi_id     bigint references public.pois (id) on delete set null,
  escena_id  bigint references public.escenas (id) on delete set null,
  payload    jsonb not null default '{}'::jsonb,
  ts         timestamptz not null default now()
);

create index eventos_ts_idx on public.eventos (ts desc);
create index eventos_tipo_idx on public.eventos (tipo, ts desc);
create index eventos_sesion_idx on public.eventos (sesion_id);

comment on table public.eventos is
  'Retencion maxima 12 meses. La purga la ejecuta public.purgar_eventos_vencidos().';

-- La Ley 1581 exige limitar la conservacion al tiempo necesario para la
-- finalidad declarada. 12 meses cubre la comparacion interanual de un piloto
-- academico.
create or replace function public.purgar_eventos_vencidos()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  borrados integer;
begin
  delete from public.eventos where ts < now() - interval '12 months';
  get diagnostics borrados = row_count;
  return borrados;
end;
$$;

-- -----------------------------------------------------------------------------
-- Auditoria
-- -----------------------------------------------------------------------------
-- Los administradores modifican contenido institucional publicado. Debe quedar
-- registro de quien cambio que y cual era el estado anterior.

create table public.auditoria (
  id          bigint generated always as identity primary key,
  actor_id    uuid references auth.users (id) on delete set null,
  accion      text not null,          -- 'insert' | 'update' | 'delete'
  entidad     text not null,
  entidad_id  text,
  antes       jsonb,
  despues     jsonb,
  ip          inet,
  ts          timestamptz not null default now()
);

create index auditoria_entidad_idx on public.auditoria (entidad, entidad_id, ts desc);
create index auditoria_actor_idx on public.auditoria (actor_id, ts desc);

create or replace function public.registrar_auditoria()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  id_afectado text;
begin
  -- Las tablas de contenido se identifican por 'id', pero perfiles lo hace por
  -- 'user_id'. Sin este segundo par, auditar un cambio de rol -- la operacion
  -- mas sensible del sistema -- dejaba entidad_id en nulo y el registro no
  -- servia para rastrear a quien se le cambio que.
  id_afectado := coalesce(
    to_jsonb(new) ->> 'id',
    to_jsonb(old) ->> 'id',
    to_jsonb(new) ->> 'user_id',
    to_jsonb(old) ->> 'user_id'
  );

  insert into public.auditoria (actor_id, accion, entidad, entidad_id, antes, despues)
  values (
    auth.uid(),
    lower(tg_op),
    tg_table_name,
    id_afectado,
    case when tg_op in ('UPDATE', 'DELETE') then to_jsonb(old) end,
    case when tg_op in ('INSERT', 'UPDATE') then to_jsonb(new) end
  );

  return coalesce(new, old);
end;
$$;

create trigger auditar_pois
  after insert or update or delete on public.pois
  for each row execute function public.registrar_auditoria();

create trigger auditar_escenas
  after insert or update or delete on public.escenas
  for each row execute function public.registrar_auditoria();

create trigger auditar_hotspots
  after insert or update or delete on public.hotspots
  for each row execute function public.registrar_auditoria();

create trigger auditar_medios
  after insert or update or delete on public.medios
  for each row execute function public.registrar_auditoria();

create trigger auditar_rutas
  after insert or update or delete on public.rutas
  for each row execute function public.registrar_auditoria();

-- Cambiar el rol de un usuario es una operacion privilegiada y debe auditarse.
create trigger auditar_perfiles
  after update on public.perfiles
  for each row execute function public.registrar_auditoria();
