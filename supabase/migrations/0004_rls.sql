-- =============================================================================
-- 0004 — Row Level Security
--
-- Politica por defecto: denegar. RLS queda activo en todas las tablas y una
-- tabla sin politica es inaccesible. Cada permiso se concede explicitamente.
--
-- Notas sobre roles de Postgres en Supabase:
--   anon          — peticion sin sesion
--   authenticated — sesion valida, incluidas las sesiones anonimas de visitantes
--   service_role   — omite RLS; reservado para la API .NET y tareas de servidor
-- =============================================================================

alter table public.lugares         enable row level security;
alter table public.pois            enable row level security;
alter table public.escenas         enable row level security;
alter table public.hotspots        enable row level security;
alter table public.medios          enable row level security;
alter table public.rutas           enable row level security;
alter table public.ruta_pois       enable row level security;
alter table public.traducciones    enable row level security;
alter table public.perfiles        enable row level security;
alter table public.consentimientos enable row level security;
alter table public.eventos         enable row level security;
alter table public.auditoria       enable row level security;

grant usage on schema public to anon, authenticated;

grant select on
  public.lugares, public.pois, public.escenas, public.hotspots,
  public.medios, public.rutas, public.ruta_pois, public.traducciones
  to anon, authenticated;

grant select, insert, update on public.perfiles to authenticated;
grant insert on public.consentimientos to anon, authenticated;
grant select on public.consentimientos to authenticated;
grant insert on public.eventos to anon, authenticated;
grant select on public.eventos, public.auditoria to authenticated;
grant insert, update, delete on
  public.lugares, public.pois, public.escenas, public.hotspots,
  public.medios, public.rutas, public.ruta_pois, public.traducciones
  to authenticated;
grant usage on all sequences in schema public to authenticated;

-- -----------------------------------------------------------------------------
-- Contenido: lectura publica del material activo, escritura solo de admin
-- -----------------------------------------------------------------------------

create policy lugares_lectura on public.lugares
  for select to anon, authenticated using (true);

create policy lugares_escritura on public.lugares
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

-- El filtrado por audiencia se aplica en la base, no en el cliente: es lo que
-- impide que un usuario vea contenido curado para otro perfil manipulando la
-- peticion.
create policy pois_lectura on public.pois
  for select to anon, authenticated
  using (
    public.es_admin()
    or (activo and public.audiencia_actual() = any (audiencias))
  );

create policy pois_escritura on public.pois
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

create policy escenas_lectura on public.escenas
  for select to anon, authenticated
  using (
    public.es_admin()
    or poi_id is null
    or exists (
      select 1 from public.pois p
      where p.id = escenas.poi_id
        and p.activo
        and public.audiencia_actual() = any (p.audiencias)
    )
  );

create policy escenas_escritura on public.escenas
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

create policy hotspots_lectura on public.hotspots
  for select to anon, authenticated
  using (
    public.es_admin()
    or exists (select 1 from public.escenas e where e.id = hotspots.escena_id)
  );

create policy hotspots_escritura on public.hotspots
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

create policy medios_lectura on public.medios
  for select to anon, authenticated
  using (
    public.es_admin()
    or exists (
      select 1 from public.pois p
      where p.id = medios.poi_id
        and p.activo
        and public.audiencia_actual() = any (p.audiencias)
    )
  );

create policy medios_escritura on public.medios
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

create policy rutas_lectura on public.rutas
  for select to anon, authenticated
  using (public.es_admin() or (activa and audiencia = public.audiencia_actual()));

create policy rutas_escritura on public.rutas
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

create policy ruta_pois_lectura on public.ruta_pois
  for select to anon, authenticated
  using (exists (select 1 from public.rutas r where r.id = ruta_pois.ruta_id));

create policy ruta_pois_escritura on public.ruta_pois
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

create policy traducciones_lectura on public.traducciones
  for select to anon, authenticated using (true);

create policy traducciones_escritura on public.traducciones
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

-- -----------------------------------------------------------------------------
-- Perfiles
-- -----------------------------------------------------------------------------

create policy perfiles_lectura_propia on public.perfiles
  for select to authenticated
  using (user_id = auth.uid() or public.es_admin());

-- El usuario no actualiza su perfil por escritura directa: rol y verificado se
-- cambian mediante public.declarar_perfil(), que valida el dominio del correo e
-- impide autoconcederse el rol admin.
create policy perfiles_escritura_admin on public.perfiles
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

-- -----------------------------------------------------------------------------
-- Consentimientos
-- -----------------------------------------------------------------------------
-- Se insertan pero nunca se modifican ni se borran: son evidencia de
-- cumplimiento y deben ser inmutables.

create policy consentimientos_registro on public.consentimientos
  for insert to anon, authenticated
  with check (user_id is null or user_id = auth.uid());

create policy consentimientos_lectura on public.consentimientos
  for select to authenticated
  using (user_id = auth.uid() or public.es_admin());

-- -----------------------------------------------------------------------------
-- Eventos
-- -----------------------------------------------------------------------------
-- Cualquiera puede emitir eventos de su propia sesion; solo un administrador
-- puede leerlos. Un usuario no debe poder consultar el recorrido de otro.

create policy eventos_emision on public.eventos
  for insert to anon, authenticated
  with check (user_id is null or user_id = auth.uid());

create policy eventos_lectura_admin on public.eventos
  for select to authenticated using (public.es_admin());

-- -----------------------------------------------------------------------------
-- Auditoria
-- -----------------------------------------------------------------------------
-- Solo lectura, y solo para administradores. Las inserciones las hace el
-- trigger registrar_auditoria(), que es SECURITY DEFINER y no pasa por RLS.
-- No existe politica de update ni de delete: el registro es inalterable.

create policy auditoria_lectura_admin on public.auditoria
  for select to authenticated using (public.es_admin());
