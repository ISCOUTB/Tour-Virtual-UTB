-- =============================================================================
-- Datos de desarrollo
--
-- Los cinco POI son los lugares de los que existe panoramica 360 real, tomadas
-- en campus el 29 de agosto de 2026. Se eligieron a partir de los nombres de
-- los archivos entregados y de la leyenda del mapa institucional; el numero
-- entre parentesis es el del mapa.
--
-- Las coordenadas map_x / map_y salen de la posicion de los marcadores
-- numerados dentro de assets/Mapa_UTB.pdf, normalizadas contra la ilustracion
-- base. No se estimaron a ojo, salvo donde se indica.
--
-- Las imagenes no son URL absolutas sino rutas de objeto en Storage
-- ("bucket/archivo"). El repositorio las resuelve contra el host configurado,
-- de modo que la misma fila sirve en escritorio y en emulador, donde el
-- anfitrion es 10.0.2.2. Una URL absoluta tambien se acepta, que es como
-- quedara al mover los medios a Cloudflare R2.
--
-- Sobre las descripciones: del guion oficial de estaciones solo coincide la
-- Biblioteca, y ese texto va literal. Las otras cuatro llevan una
-- descripcion PROVISIONAL, factual y sin tono promocional, escrita para que
-- la ficha no salga vacia en desarrollo. No es texto institucional y hay
-- que sustituirla cuando Comunicaciones entregue el suyo. Ver
-- docs/contenido-estaciones.md.
--
-- No ejecutar en produccion.
-- =============================================================================

insert into public.lugares (nombre, slug)
values ('Campus Tecnologico Ternera', 'campus-ternera');

insert into public.pois (lugar_id, nombre, categoria, descripcion, map_x, map_y, audiencias)
values
  -- (7) Biblioteca. Unica parada del guion oficial de estaciones que ya tiene
  -- panoramica, asi que es la unica con descripcion definitiva.
  (1, 'Biblioteca', 'Recursos',
   'Mas que una biblioteca: concentracion, disciplina, tecnologia y '
   'construccion de suenos.',
   0.4067, 0.2745,
   array['externo','estudiante','docente']::public.audiencia[]),

  -- Pasarela elevada entre los edificios A3 (11) y A5 (13). No es un marcador
  -- de la leyenda: la posicion es el punto medio entre ambos. Se deja
  -- restringida a la comunidad universitaria, por ser circulacion interna, lo
  -- que ademas mantiene comprobable el filtrado por audiencia de RLS: un
  -- visitante anonimo debe recibir 4 de los 5 POI.
  (1, 'Puente A3 - A5', 'Academico',
   'Pasarela elevada que une los edificios A3 y A5 sin bajar a nivel de '
   'calle. Es la circulacion mas corta entre ambos bloques de aulas.',
   0.6191, 0.1793,
   array['estudiante','docente']::public.audiencia[]),

  -- (10) Enfermeria
  (1, 'Enfermeria', 'Bienestar',
   'Servicio de atencion primaria del campus: consulta, curaciones y '
   'primeros auxilios durante la jornada academica.',
   0.6186, 0.5055,
   array['externo','estudiante','docente']::public.audiencia[]),

  -- Zona de mesas al aire libre. Tampoco figura en la leyenda. La posicion es
  -- una ESTIMACION a partir de su ubicacion descrita: debajo de los marcadores
  -- 9 y 10, encima del 15 y sobre la rampa. Recalibrar desde el panel de
  -- administracion cuando exista su editor visual.
  (1, 'Zona T', 'Servicios',
   'Zona de mesas al aire libre y a la sombra, junto al Centro Deportivo '
   'y Cultural. Punto habitual para comer o estudiar entre clases.',
   0.5450, 0.5550,
   array['externo','estudiante','docente']::public.audiencia[]),

  -- (15) Cancha de softbol
  (1, 'Cancha de softbol', 'Deporte',
   'Campo abierto del area deportiva, usado para softbol y para '
   'entrenamientos al aire libre.',
   0.5195, 0.6580,
   array['externo','estudiante','docente']::public.audiencia[]);

-- Panoramicas equirectangulares 2:1 reducidas a 4096x2048 y sin EXIF. Las
-- originales pesaban entre 7 y 17 MB cada una; a ese tamano ninguna wifi de
-- feria las sirve. La variante de baja resolucion se muestra mientras descarga
-- la completa.
--
-- vista_inicial_yaw / _pitch encuadran el primer fotograma. El yaw 0 del
-- archivo no significa nada: es hacia donde miraba la camara al disparar, y
-- aqui caia sobre una mampara lisa en Enfermeria, el tronco de un arbol en la
-- Zona T y cesped vacio en la cancha. Cada escena abre ahora sobre algo que
-- identifica el lugar, y con su salida principal ya dentro de cuadro.
insert into public.escenas
  (lugar_id, poi_id, nombre, imagen_url, imagen_url_baja, es_escena_principal, orden,
   vista_inicial_yaw, vista_inicial_pitch)
values
  -- Escalera y cartel de SALIDA: es la ruta de salida y lleva el unico
  -- hotspot de la escena. La sala de lectura, que es mejor estampa, queda
  -- a la espalda; se prefiere abrir donde esta el control.
  (1, 1, 'Biblioteca',        'panoramas/biblioteca.jpg',     'panoramas/biblioteca-baja.jpg',     true,  0,  152, -5),
  -- La pasarela a lo largo, que es lo que da nombre al punto, con su
  -- hotspot algo a la izquierda del centro.
  (1, 2, 'Puente A3 - A5',    'panoramas/puente-a3-a5.jpg',   'panoramas/puente-a3-a5-baja.jpg',   false, 1,  -58, -5),
  -- Recepcion y sala de espera; la puerta de salida entra por la izquierda.
  (1, 3, 'Enfermeria',        'panoramas/enfermeria.jpg',     'panoramas/enfermeria-baja.jpg',     false, 2, -158, -6),
  -- Mesas bajo los arboles con la explanada al fondo.
  (1, 4, 'Zona T',            'panoramas/zona-t.jpg',         'panoramas/zona-t-baja.jpg',         false, 3,  -55, -6),
  -- El campo es casi todo igual: lo unico que ubica es el edificio deportivo.
  (1, 5, 'Cancha de softbol', 'panoramas/cancha-softbol.jpg', 'panoramas/cancha-softbol-baja.jpg', false, 4,  -40, -3);

-- Cada POI entra por su propia escena.
update public.pois p set escena_principal_id = e.id
  from public.escenas e where e.poi_id = p.id;

-- Los hotspots conectan SOLO lugares que estan de verdad cerca.
--
-- Antes encadenaban las cinco escenas en bucle para que se pudiera recorrer
-- todo sin volver al mapa. Eso creaba saltos falsos: desde la Biblioteca se
-- llegaba a Enfermeria, que esta al otro lado del campus. Distancias entre
-- marcadores, normalizadas sobre la ilustracion:
--
--   Enfermeria - Zona T        0.089   se conecta
--   Zona T     - Cancha        0.106   se conecta
--   Biblioteca - Puente        0.233   se conecta
--   Biblioteca - Enfermeria    0.313   NO
--   Biblioteca - Zona T        0.313   NO
--   Puente     - Enfermeria    0.326   NO, es el salto mas largo de todos
--
-- El grafo queda en dos partes: {Biblioteca, Puente} y {Enfermeria, Zona T,
-- Cancha}. Es lo correcto —no hay forma de ir andando de una a otra sin
-- cruzar medio campus— y no deja a nadie atrapado: se sale con el boton de
-- atras, el mapa o la pestana Recorrido.
--
-- OJO con el efecto sobre el visitante anonimo: RLS le oculta el Puente, que
-- es el unico vecino de la Biblioteca, asi que para el esa escena se queda
-- sin hotspots. Se arregla quitandole la restriccion de audiencia al Puente,
-- a cambio de perder el caso de prueba de RLS.
--
-- pitch y yaw estan CALIBRADOS contra las panoramicas originales. La
-- conversion sale del mesh del visor: para un pixel (x,y) de la
-- equirectangular, yaw = 360*x/ancho - 180 y pitch = 90 - 180*y/alto. El
-- sentido se comprobo ademas en la app: el yaw crece hacia la derecha de la
-- pantalla, sin espejo.
--
-- Cada hotspot se apoya en una salida real de la escena, no en un angulo
-- redondo. Antes estaban todos en yaw 0 / 90 / 180 y varios caian sobre una
-- mampara, un tronco o el pasamanos de la pasarela.
--
-- Las panoramicas no traen rumbo de brujula: Teleport escribe
-- PoseHeadingDegrees=0 en las cinco, que es su valor por defecto y no una
-- lectura. Asi que los angulos orientan hacia la salida por la que se sale de
-- verdad, no hacia el rumbo geografico del destino.
insert into public.hotspots (escena_id, tipo, pitch, yaw, escena_destino_id, etiqueta)
values
  -- Biblioteca -> Puente: suelo libre al pie de la escalera, bajo el cartel
  -- de SALIDA. Es la ruta de salida del edificio.
  (1, 'navegacion', -12,  140, 2, 'Ir al puente A3 - A5'),

  -- Puente -> Biblioteca: la pasarela a lo largo, que es por donde se sale.
  (2, 'navegacion', -10,  -68, 1, 'Ir a la Biblioteca'),

  -- Enfermeria -> Zona T: la puerta blanca de EMPUJE, su unica salida.
  (3, 'navegacion',  -8, -172, 4, 'Ir a la Zona T'),

  -- Zona T -> Cancha: sobre la explanada, al otro lado del seto.
  (4, 'navegacion',  -4,  -66, 5, 'Ir a la cancha de softbol'),
  -- Zona T -> Enfermeria: dentro del vano de la puerta del edificio blanco,
  -- a la derecha de la escalera y detras del arbol. Antes apuntaba a la
  -- escalera (yaw 140), que sube a otro sitio.
  (4, 'navegacion',   1, -156, 3, 'Ir a Enfermeria'),

  -- Cancha -> Zona T: el pie de la escalera del edificio deportivo, el unico
  -- acceso visible desde el campo.
  (5, 'navegacion',  -2,  -34, 4, 'Ir a la Zona T');

-- Narraciones de cada lugar, entregadas por el equipo institucional el
-- 2026-10-04. Mismo esquema de rutas que las panoramicas: "bucket/archivo",
-- que el repositorio resuelve contra el host configurado.
--
-- La duracion sale de la cabecera MP3 y es solo informativa; el reproductor
-- usa la real del archivo.
--
-- OJO, BLOQUEA PUBLICACION: `subtitulos_url` queda nulo y estos audios son
-- contenido hablado. WCAG 2.2 AA (1.2.1, solo audio pregrabado) exige una
-- alternativa en texto, asi que hacen falta las transcripciones antes de
-- publicar. La columna es anulable para no frenar el desarrollo, nada mas.
insert into public.medios (poi_id, tipo, url, orden, duracion_seg, texto_alt)
values
  (1, 'audio', 'audios/biblioteca.mp3',     0, 10, 'Audio narrado de la Biblioteca'),
  (2, 'audio', 'audios/puente-a3-a5.mp3',   0, 16, 'Audio narrado del puente A3 - A5'),
  (3, 'audio', 'audios/enfermeria.mp3',     0, 11, 'Audio narrado de Enfermeria'),
  (4, 'audio', 'audios/zona-t.mp3',         0, 11, 'Audio narrado de la Zona T'),
  (5, 'audio', 'audios/cancha-softbol.mp3', 0, 12, 'Audio narrado de la cancha de softbol');

insert into public.rutas (lugar_id, nombre, descripcion, audiencia)
values
  (1, 'Conoce la UTB', 'Recorrido institucional para visitantes.', 'externo'),
  (1, 'Tu dia a dia',  'Espacios de uso frecuente.',               'estudiante'),
  (1, 'Espacios academicos', 'Aulas y recursos docentes.',         'docente');

insert into public.ruta_pois (ruta_id, poi_id, orden)
values
  (1, 1, 0), (1, 3, 1), (1, 4, 2), (1, 5, 3),
  (2, 1, 0), (2, 2, 1), (2, 3, 2), (2, 4, 3), (2, 5, 4),
  (3, 1, 0), (3, 2, 1), (3, 3, 2);
