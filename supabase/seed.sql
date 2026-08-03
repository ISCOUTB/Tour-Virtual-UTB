-- =============================================================================
-- Datos de desarrollo
--
-- Los cinco POI corresponden a los definidos en docs/utb-tour-inmersivo-mvp.md.
-- Las URL de imagen son marcadores de posicion: las panoramicas reales solo se
-- cargan tras pasar por el pipeline de ingesta descrito en la seccion 7.1 de
-- docs/arquitectura.md.
--
-- No ejecutar en produccion.
-- =============================================================================

insert into public.lugares (nombre, slug)
values ('Campus Tecnologico Ternera', 'campus-ternera');

-- Las coordenadas map_x / map_y estan normalizadas sobre el render ilustrado
-- del campus. Los valores de aqui son provisionales: deben recalibrarse contra
-- el asset definitivo desde el panel de administracion.
insert into public.pois (lugar_id, nombre, categoria, descripcion, map_x, map_y, audiencias)
values
  (1, 'Zona de comidas', 'Servicios',
   'Punto de encuentro y alimentacion del campus.',
   0.42, 0.58, array['externo','estudiante','docente']::public.audiencia[]),

  (1, 'Murales UTB', 'Cultura',
   'Intervenciones artisticas que recorren los pasillos del campus.',
   0.28, 0.34, array['externo','estudiante','docente']::public.audiencia[]),

  (1, 'Salones representativos', 'Academico',
   'Espacios de clase representativos de la vida academica.',
   0.55, 0.46, array['estudiante','docente']::public.audiencia[]),

  (1, 'Biblioteca', 'Recursos',
   'Centro de recursos bibliograficos y espacios de estudio.',
   0.63, 0.30, array['externo','estudiante','docente']::public.audiencia[]),

  (1, 'Bienestar universitario', 'Comunidad',
   'Servicios de acompanamiento, salud y deporte.',
   0.36, 0.72, array['externo','estudiante','docente']::public.audiencia[]);

insert into public.escenas (lugar_id, poi_id, nombre, imagen_url, es_escena_principal, orden)
values
  (1, null, 'Entrada principal', 'https://placeholder.invalid/360/entrada.jpg', true, 0),
  (1, 1, 'Zona de comidas',      'https://placeholder.invalid/360/comidas.jpg', false, 1),
  (1, 4, 'Biblioteca',           'https://placeholder.invalid/360/biblioteca.jpg', false, 2);

-- Hotspots de navegacion desde la escena de entrada.
insert into public.hotspots (escena_id, tipo, pitch, yaw, escena_destino_id, etiqueta)
values
  (1, 'navegacion', -5, 45,  2, 'Ir a la zona de comidas'),
  (1, 'navegacion', -5, -60, 3, 'Ir a la biblioteca');

-- Una ruta curada por audiencia.
insert into public.rutas (lugar_id, nombre, descripcion, audiencia)
values
  (1, 'Conoce la UTB', 'Recorrido institucional para visitantes.', 'externo'),
  (1, 'Tu dia a dia',  'Servicios y espacios de uso frecuente.',   'estudiante'),
  (1, 'Espacios academicos', 'Laboratorios y recursos docentes.',  'docente');

insert into public.ruta_pois (ruta_id, poi_id, orden)
values
  (1, 1, 0), (1, 2, 1), (1, 4, 2), (1, 5, 3),
  (2, 1, 0), (2, 3, 1), (2, 4, 2), (2, 5, 3),
  (3, 3, 0), (3, 4, 1);
