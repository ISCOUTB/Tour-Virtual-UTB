-- =============================================================================
-- Datos de desarrollo
--
-- Los cinco POI son los definidos para la demo del MVP, ubicados sobre el
-- render isometrico oficial del campus (assets/Mapa_UTB.pdf). Las coordenadas
-- map_x / map_y no se estimaron a ojo: salen de la posicion de los marcadores
-- numerados del propio PDF, normalizadas contra la ilustracion base.
--
-- El numero entre parentesis es el del mapa institucional.
--
-- Las descripciones quedan nulas a proposito: el texto definitivo lo redacta
-- el equipo de contenido, y no conviene sembrar la base con relleno que luego
-- alguien tome por bueno.
--
-- No ejecutar en produccion.
-- =============================================================================

insert into public.lugares (nombre, slug)
values ('Campus Tecnologico Ternera', 'campus-ternera');

insert into public.pois (lugar_id, nombre, categoria, map_x, map_y, audiencias)
values
  -- (1) Auditorio
  (1, 'Auditorio', 'Cultura', 0.2558, 0.5118,
   array['externo','estudiante','docente']::public.audiencia[]),

  -- (3) En el mapa institucional figura como Ed. Alcatraz.
  (1, 'Placita', 'Servicios', 0.3059, 0.3557,
   array['externo','estudiante','docente']::public.audiencia[]),

  -- (7) Biblioteca
  (1, 'Biblioteca', 'Recursos', 0.4067, 0.2745,
   array['externo','estudiante','docente']::public.audiencia[]),

  -- (4) Maloka
  (1, 'Maloka', 'Academico', 0.3947, 0.4949,
   array['externo','estudiante','docente']::public.audiencia[]),

  -- (13) En el mapa institucional figura como Edificio A5. Se deja restringido
  -- a la comunidad universitaria para que el filtrado por audiencia de RLS siga
  -- siendo comprobable: un visitante anonimo debe recibir 4 de los 5 POI.
  (1, 'Quantum', 'Academico', 0.6477, 0.1529,
   array['estudiante','docente']::public.audiencia[]);

-- Las URL son marcadores de posicion. Las panoramicas reales solo se cargan
-- tras pasar por el pipeline de ingesta descrito en la seccion 7.1 de
-- docs/arquitectura.md: difuminado de rostros, revision manual y limpieza EXIF.
insert into public.escenas (lugar_id, poi_id, nombre, imagen_url, es_escena_principal, orden)
values
  (1, null, 'Entrada principal', 'https://placeholder.invalid/360/entrada.jpg', true, 0),
  (1, 2, 'Placita',              'https://placeholder.invalid/360/placita.jpg', false, 1),
  (1, 3, 'Biblioteca',           'https://placeholder.invalid/360/biblioteca.jpg', false, 2);

insert into public.hotspots (escena_id, tipo, pitch, yaw, escena_destino_id, etiqueta)
values
  (1, 'navegacion', -5, 45,  2, 'Ir a la Placita'),
  (1, 'navegacion', -5, -60, 3, 'Ir a la Biblioteca');

insert into public.rutas (lugar_id, nombre, descripcion, audiencia)
values
  (1, 'Conoce la UTB', 'Recorrido institucional para visitantes.', 'externo'),
  (1, 'Tu dia a dia',  'Espacios de uso frecuente.',               'estudiante'),
  (1, 'Espacios academicos', 'Aulas y recursos docentes.',         'docente');

insert into public.ruta_pois (ruta_id, poi_id, orden)
values
  (1, 1, 0), (1, 2, 1), (1, 3, 2), (1, 4, 3),
  (2, 2, 0), (2, 3, 1), (2, 4, 2), (2, 5, 3),
  (3, 3, 0), (3, 4, 1), (3, 5, 2);
