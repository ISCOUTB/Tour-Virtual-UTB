-- Generado por scripts/mapa_campus.py. No editar a mano.
--
-- Pone lat/lng y los textos del guion a las cinco paradas, y crea los
-- demas lugares del campus si no existen (se reconocen por nombre).
-- No toca escenas, hotspots ni medios. Se puede ejecutar mas de una vez.
begin;

update "Pois" set "Nombre" = 'Biblioteca', "Categoria" = 'Recursos', "Descripcion" = 'Más que una biblioteca: concentración, disciplina, tecnología y construcción de sueños.', "Lat" = 10.3699965, "Lng" = -75.4650668
 where "LugarId" = 1 and "Nombre" in ('Biblioteca');

update "Pois" set "Nombre" = 'Puente A3 - A5', "Categoria" = 'Academico', "Descripcion" = 'Un punto que conecta espacios, personas y recorridos dentro del campus. Cada trayecto en la UTB hace parte de una experiencia que conecta tu presente con lo que quieres construir.', "Lat" = 10.3692169, "Lng" = -75.4647217
 where "LugarId" = 1 and "Nombre" in ('Puente A3 - A5');

update "Pois" set "Nombre" = 'Enfermería', "Categoria" = 'Bienestar', "Descripcion" = 'Bienestar y cuidado integral. Un espacio para atender tu salud, recibir orientación y recordar que cuidar de ti también hace parte de la experiencia universitaria.', "Lat" = 10.3692651, "Lng" = -75.4655196
 where "LugarId" = 1 and "Nombre" in ('Enfermeria', 'Enfermería');

update "Pois" set "Nombre" = 'Zona T', "Categoria" = 'Servicios', "Descripcion" = 'Punto de encuentro, pausa y conexión. Un lugar para compartir con otros estudiantes, conversar y disfrutar los espacios que hacen del campus una comunidad.', "Lat" = 10.3691852, "Lng" = -75.4655576
 where "LugarId" = 1 and "Nombre" in ('Zona T');

update "Pois" set "Nombre" = 'Cancha de softbol', "Categoria" = 'Deporte', "Descripcion" = 'El campus también se vive en movimiento. Espacio para el deporte, la disciplina, el trabajo en equipo y las experiencias que se construyen más allá del aula.', "Lat" = 10.3695823, "Lng" = -75.4663148
 where "LugarId" = 1 and "Nombre" in ('Cancha de softbol');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Edificio A1', 'Academico', null, 10.3697646, -75.465347, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Edificio A1');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Edificio A2', 'Academico', null, 10.3707763, -75.4656241, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Edificio A2');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Edificio A3', 'Academico', null, 10.3692983, -75.4648329, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Edificio A3');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Edificio A4', 'Academico', null, 10.3695805, -75.4645402, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Edificio A4');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Edificio A5', 'Academico', null, 10.3691355, -75.4646105, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Edificio A5');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Edificio Alcatraz', 'Academico', null, 10.3703807, -75.4652636, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Edificio Alcatraz');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Auditorio', 'Cultura', null, 10.3705694, -75.4657944, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Auditorio');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Plaza Maloca', 'Cultura', null, 10.3700456, -75.4657625, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Plaza Maloca');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Rectoría', 'Administrativo', null, 10.3695939, -75.4652554, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Rectoría');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Laboratorio El Patio', 'Academico', null, 10.3696815, -75.4650578, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Laboratorio El Patio');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Centro de Cuidado Integral (QUID)', 'Bienestar', null, 10.3690673, -75.4658707, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Centro de Cuidado Integral (QUID)');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Centro Deportivo y Cultural', 'Deporte', null, 10.3692615, -75.4656845, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Centro Deportivo y Cultural');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Cancha de fútbol', 'Deporte', null, 10.3701542, -75.4667058, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Cancha de fútbol');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Salas de estudio', 'Recursos', null, 10.3705483, -75.4654429, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Salas de estudio');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Cafetería', 'Servicios', null, 10.37042, -75.4653547, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Cafetería');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Tienda', 'Servicios', null, 10.3692206, -75.4661076, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Tienda');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Cajero automático', 'Servicios', null, 10.3705307, -75.4659036, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Cajero automático');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Pasillo de la conexión', 'Administrativo', null, 10.3707567, -75.4659942, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Pasillo de la conexión');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Solo Café', 'Servicios', 'Espacio de conexión, ideas y conversaciones que también transforman la experiencia universitaria. Aquí nacen amistades, proyectos y networking.', 10.3702285, -75.4655508, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Solo Café');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'La Placita', 'Cultura', 'Inspirada en las plazas del Caribe. Un espacio creado para compartir, desconectarse y sentirse en casa dentro de la UTB.', 10.3704913, -75.465484, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'La Placita');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'QuantaLab', 'Academico', 'Laboratorio de analítica, IA y datos. El futuro pertenece a quienes saben interpretar información y tomar decisiones.', 10.3690907, -75.4646518, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'QuantaLab');

commit;
