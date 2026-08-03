-- =============================================================================
-- 0002 — Perfiles, asignacion de rol y consentimientos
--
-- La UTB opera un unico dominio de correo (utb.edu.co) tanto para estudiantes
-- como para docentes, de modo que el dominio distingue entre miembro de la
-- universidad y externo, pero no entre estudiante y docente. El rol se afina
-- por autodeclaracion del usuario y puede ser corregido desde el panel de
-- administracion. Ver docs/arquitectura.md seccion 6.
-- =============================================================================

create table public.perfiles (
  user_id     uuid primary key references auth.users (id) on delete cascade,
  rol         public.rol_usuario not null default 'externo',

  -- false mientras el rol provenga del dominio o de la autodeclaracion del
  -- usuario. Solo un administrador lo pone en true.
  verificado  boolean not null default false,

  -- Lo que el usuario declaro de si mismo en el primer inicio de sesion.
  -- Se conserva aparte del rol efectivo para poder auditar discrepancias.
  rol_declarado public.rol_usuario,

  creado_en   timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

comment on column public.perfiles.rol is
  'Rol efectivo. Nunca se asigna admin por dominio ni por autodeclaracion.';

create trigger perfiles_actualizado_en before update on public.perfiles
  for each row execute function public.tocar_actualizado_en();

-- -----------------------------------------------------------------------------
-- Alta automatica de perfil
-- -----------------------------------------------------------------------------

create or replace function public.crear_perfil_para_usuario()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  rol_inicial public.rol_usuario;
begin
  -- Los usuarios anonimos (visitantes externos que entran sin cuenta) no
  -- tienen correo. El dominio institucional otorga el rol base 'estudiante',
  -- que el usuario puede refinar a 'docente' al declararse.
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

create trigger al_crear_usuario
  after insert on auth.users
  for each row execute function public.crear_perfil_para_usuario();

-- -----------------------------------------------------------------------------
-- Funciones de apoyo para RLS
-- -----------------------------------------------------------------------------

-- SECURITY DEFINER y STABLE: las politicas RLS de perfiles no deben recursar
-- sobre si mismas al consultar el rol.
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

-- La audiencia de contenido que corresponde al rol. Un administrador ve todo,
-- pero para efectos de filtrado de contenido se le trata como externo.
create or replace function public.audiencia_actual()
returns public.audiencia
language sql
stable
as $$
  select case public.rol_actual()
    when 'estudiante' then 'estudiante'::public.audiencia
    when 'docente'    then 'docente'::public.audiencia
    else 'externo'::public.audiencia
  end;
$$;

-- -----------------------------------------------------------------------------
-- Autodeclaracion de perfil
-- -----------------------------------------------------------------------------

create or replace function public.declarar_perfil(rol_nuevo public.rol_usuario)
returns public.perfiles
language plpgsql
security definer
set search_path = public
as $$
declare
  perfil public.perfiles;
begin
  if auth.uid() is null then
    raise exception 'Se requiere una sesion activa';
  end if;

  -- El rol admin jamas se obtiene por esta via.
  if rol_nuevo = 'admin' then
    raise exception 'El rol admin solo se asigna por invitacion';
  end if;

  -- Un usuario cuyo rol ya fue verificado por un administrador no puede
  -- revertirlo por su cuenta.
  select * into perfil from public.perfiles where user_id = auth.uid();
  if perfil.verificado then
    return perfil;
  end if;

  -- Quien no tiene correo institucional no puede declararse miembro de la
  -- universidad.
  if rol_nuevo in ('estudiante', 'docente') then
    if not exists (
      select 1 from auth.users
      where id = auth.uid() and lower(email) like '%@utb.edu.co'
    ) then
      raise exception 'Se requiere un correo institucional @utb.edu.co';
    end if;
  end if;

  update public.perfiles
     set rol = rol_nuevo,
         rol_declarado = rol_nuevo
   where user_id = auth.uid()
  returning * into perfil;

  return perfil;
end;
$$;

-- -----------------------------------------------------------------------------
-- Consentimientos (Ley 1581 de 2012)
-- -----------------------------------------------------------------------------
-- El consentimiento debe quedar registrado con la version exacta del documento
-- aceptado y la fecha. Sin esto no se puede demostrar el cumplimiento.

create table public.consentimientos (
  id          bigint generated always as identity primary key,
  user_id     uuid references auth.users (id) on delete set null,

  -- Permite registrar la aceptacion de un visitante que aun no tiene sesion.
  sesion_id   uuid,

  tipo        text not null,      -- 'tratamiento_datos' | 'analitica' | 'terminos'
  version     text not null,      -- version del documento aceptado
  aceptado    boolean not null,
  aceptado_en timestamptz not null default now(),

  -- Hash, no la IP en claro: sirve como evidencia sin conservar el dato
  -- identificador mas de lo necesario.
  ip_hash     text,

  constraint consentimiento_con_sujeto check (user_id is not null or sesion_id is not null)
);

create index consentimientos_user_idx on public.consentimientos (user_id, tipo, aceptado_en desc);
