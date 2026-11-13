-- =============================================================================
-- Perfiles, eventos y auditoria para el panel de administracion
--
-- Crea SOLO estas tres tablas y lo que necesitan para funcionar:
--   - el tipo rol_usuario
--   - la funcion y el trigger que crean un perfil al registrarse un usuario
--   - las funciones rol_actual() y es_admin()
--   - RLS (seguridad por filas) en las tres tablas
--
-- Viene de supabase/migrations 0002, 0003 y 0004, adaptado a la base real:
--   - NO crea lugares, pois, escenas, medios, etc. Esas ya existen con los
--     nombres de EF ("Pois", "Escenas", "Medios"...) y las maneja la API.
--   - eventos apunta a "Pois" y "Escenas" (id entero) en vez de pois/escenas.
--   - auditoria no se engancha a las tablas de contenido: la API escribe con
--     su propio usuario de base, asi que el trigger no sabria quien hizo el
--     cambio. Llenarla le toca a la API mas adelante.
--
-- Se puede correr dos veces sin dañar nada. Va todo en una transaccion: si
-- algo falla, no queda nada a medias.
-- =============================================================================

begin;

-- -----------------------------------------------------------------------------
-- Tipo de rol
-- -----------------------------------------------------------------------------

do $$
begin
  if not exists (
    select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'rol_usuario'
  ) then
    create type public.rol_usuario as enum ('externo', 'estudiante', 'docente', 'admin');
  end if;
end;
$$;

create or replace function public.tocar_actualizado_en()
returns trigger
language plpgsql
as $$
begin
  new.actualizado_en := now();
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- Perfiles: un perfil por cada usuario de Supabase Auth
-- -----------------------------------------------------------------------------

create table if not exists public.perfiles (
  user_id        uuid primary key references auth.users (id) on delete cascade,
  rol            public.rol_usuario not null default 'externo',
  verificado     boolean not null default false,
  rol_declarado  public.rol_usuario,
  creado_en      timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

comment on column public.perfiles.rol is
  'Rol efectivo. Nunca se asigna admin por dominio ni por autodeclaracion.';

drop trigger if exists perfiles_actualizado_en on public.perfiles;
create trigger perfiles_actualizado_en before update on public.perfiles
  for each row execute function public.tocar_actualizado_en();

-- Al crearse un usuario en Supabase Auth, se le crea su perfil.
-- Correo @utb.edu.co empieza como estudiante; el resto, como externo.
create or replace function public.crear_perfil_para_usuario()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  rol_inicial public.rol_usuario;
begin
  if new.email is not null and lower(new.email) like '%@utb.edu.co' then
    rol_inicial := 'estudiante';
  else
    rol_inicial := 'externo';
  end if;

  insert into public.perfiles (user_id, rol)
  values (new.id, rol_inicial)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists al_crear_usuario on auth.users;
create trigger al_crear_usuario
  after insert on auth.users
  for each row execute function public.crear_perfil_para_usuario();

-- Usuarios que ya existian antes de este script: tambien reciben perfil.
insert into public.perfiles (user_id, rol)
select u.id,
       case when lower(coalesce(u.email, '')) like '%@utb.edu.co'
            then 'estudiante'::public.rol_usuario
            else 'externo'::public.rol_usuario end
from auth.users u
on conflict (user_id) do nothing;

create or replace function public.rol_actual()
returns public.rol_usuario
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select rol from public.perfiles where user_id = auth.uid()),
    'externo'::public.rol_usuario
  );
$$;

create or replace function public.es_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.rol_actual() = 'admin';
$$;

-- -----------------------------------------------------------------------------
-- Eventos de uso (para las metricas del panel)
-- -----------------------------------------------------------------------------

create table if not exists public.eventos (
  id         bigint generated always as identity primary key,
  sesion_id  uuid not null,
  user_id    uuid references auth.users (id) on delete set null,
  rol        public.rol_usuario,
  tipo       text not null,
  poi_id     integer references public."Pois" ("Id") on delete set null,
  escena_id  integer references public."Escenas" ("Id") on delete set null,
  payload    jsonb not null default '{}'::jsonb,
  ts         timestamptz not null default now()
);

create index if not exists eventos_ts_idx on public.eventos (ts desc);
create index if not exists eventos_tipo_idx on public.eventos (tipo, ts desc);
create index if not exists eventos_sesion_idx on public.eventos (sesion_id);

comment on table public.eventos is
  'Retencion maxima 12 meses. La purga la ejecuta public.purgar_eventos_vencidos().';

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
-- Auditoria (para la actividad del panel)
-- -----------------------------------------------------------------------------

create table if not exists public.auditoria (
  id          bigint generated always as identity primary key,
  actor_id    uuid references auth.users (id) on delete set null,
  accion      text not null,
  entidad     text not null,
  entidad_id  text,
  antes       jsonb,
  despues     jsonb,
  ip          inet,
  ts          timestamptz not null default now()
);

create index if not exists auditoria_entidad_idx on public.auditoria (entidad, entidad_id, ts desc);
create index if not exists auditoria_actor_idx on public.auditoria (actor_id, ts desc);

create or replace function public.registrar_auditoria()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  id_afectado text;
begin
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

-- Cambiar el rol de alguien queda registrado.
drop trigger if exists auditar_perfiles on public.perfiles;
create trigger auditar_perfiles
  after update on public.perfiles
  for each row execute function public.registrar_auditoria();

-- -----------------------------------------------------------------------------
-- RLS: por defecto nadie ve nada; cada permiso se da a proposito.
-- La API entra como dueña de las tablas y no pasa por estas reglas.
-- -----------------------------------------------------------------------------

alter table public.perfiles  enable row level security;
alter table public.eventos   enable row level security;
alter table public.auditoria enable row level security;

grant select on public.perfiles to authenticated;
grant insert on public.eventos to anon, authenticated;
grant select on public.eventos, public.auditoria to authenticated;

-- Cada quien ve su propio perfil; un admin ve todos.
drop policy if exists perfiles_lectura_propia on public.perfiles;
create policy perfiles_lectura_propia on public.perfiles
  for select to authenticated
  using (user_id = auth.uid() or public.es_admin());

-- Solo un admin cambia perfiles (por ejemplo, el rol de otra persona).
grant insert, update, delete on public.perfiles to authenticated;
drop policy if exists perfiles_escritura_admin on public.perfiles;
create policy perfiles_escritura_admin on public.perfiles
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

-- Cualquiera puede registrar eventos de su sesion; solo un admin los lee.
drop policy if exists eventos_emision on public.eventos;
create policy eventos_emision on public.eventos
  for insert to anon, authenticated
  with check (user_id is null or user_id = auth.uid());

drop policy if exists eventos_lectura_admin on public.eventos;
create policy eventos_lectura_admin on public.eventos
  for select to authenticated using (public.es_admin());

-- Auditoria: solo lectura y solo para admins. No se puede editar ni borrar.
drop policy if exists auditoria_lectura_admin on public.auditoria;
create policy auditoria_lectura_admin on public.auditoria
  for select to authenticated using (public.es_admin());

commit;

-- Comprobacion: debe mostrar las 3 tablas.
select table_name
from information_schema.tables
where table_schema = 'public' and table_name in ('perfiles', 'eventos', 'auditoria')
order by table_name;
