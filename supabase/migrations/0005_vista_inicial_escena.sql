-- =============================================================================
-- 0005 — Vista inicial de cada escena
--
-- Hasta ahora el visor abria toda panoramica mirando al yaw 0, que es el
-- centro horizontal del archivo y no significa nada: depende de hacia donde
-- apuntaba la camara al disparar. En las panoramicas reales eso cae sobre una
-- mampara lisa en Enfermeria, sobre el tronco de un arbol en la Zona T y sobre
-- cesped vacio en la cancha. El primer fotograma decide si el lugar se
-- entiende, asi que se guarda con el contenido y no en el cliente.
--
-- Mismos grados y mismo convenio que `hotspots`: el visor los consume como
-- `PanoramaViewer.longitude` y `.latitude`, con yaw 0 en el centro horizontal
-- de la imagen creciendo hacia la derecha, y pitch 0 en el horizonte.
--
-- Nulos a proposito: una escena sin encuadrar abre en 0,0 como antes.
-- =============================================================================

alter table public.escenas
  add column vista_inicial_yaw   double precision
    check (vista_inicial_yaw between -180 and 180),
  add column vista_inicial_pitch double precision
    check (vista_inicial_pitch between -90 and 90);

comment on column public.escenas.vista_inicial_yaw is
  'Grados hacia donde abre la escena. Null abre al centro del archivo.';
comment on column public.escenas.vista_inicial_pitch is
  'Grados sobre el horizonte al abrir la escena. Null abre al horizonte.';
