-- Generado por scripts/mapa_campus.py. No editar a mano.
--
-- Pone lat/lng y los textos del guion a las cinco paradas, y crea los
-- demas lugares del campus si no existen (se reconocen por nombre).
-- No toca escenas, hotspots ni medios. Se puede ejecutar mas de una vez.
begin;

update "Pois" set "Nombre" = 'Biblioteca', "Categoria" = 'Recursos', "Descripcion" = 'Más que una biblioteca: concentración, disciplina, tecnología y construcción de sueños.', "Lat" = 10.3699308, "Lng" = -75.4651281
 where "LugarId" = 1 and "Nombre" in ('Biblioteca');

update "Pois" set "Nombre" = 'Puente A3 - A5', "Categoria" = 'Academico', "Descripcion" = 'Un punto que conecta espacios, personas y recorridos dentro del campus. Cada trayecto en la UTB hace parte de una experiencia que conecta tu presente con lo que quieres construir.', "Lat" = 10.3693299, "Lng" = -75.4646038
 where "LugarId" = 1 and "Nombre" in ('Puente A3 - A5');

update "Pois" set "Nombre" = 'Enfermería', "Categoria" = 'Bienestar', "Descripcion" = 'Bienestar y cuidado integral. Un espacio para atender tu salud, recibir orientación y recordar que cuidar de ti también hace parte de la experiencia universitaria.', "Lat" = 10.3692929, "Lng" = -75.4660428
 where "LugarId" = 1 and "Nombre" in ('Enfermeria', 'Enfermería');

update "Pois" set "Nombre" = 'Zona T', "Categoria" = 'Servicios', "Descripcion" = 'Punto de encuentro, pausa y conexión. Un lugar para compartir con otros estudiantes, conversar y disfrutar los espacios que hacen del campus una comunidad.', "Lat" = 10.3695983, "Lng" = -75.4657454
 where "LugarId" = 1 and "Nombre" in ('Zona T');

update "Pois" set "Nombre" = 'Cancha de softbol', "Categoria" = 'Deporte', "Descripcion" = 'El campus también se vive en movimiento. Espacio para el deporte, la disciplina, el trabajo en equipo y las experiencias que se construyen más allá del aula.', "Lat" = 10.3698371, "Lng" = -75.4658858
 where "LugarId" = 1 and "Nombre" in ('Cancha de softbol');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Edificio A1', 'Academico', null, 10.3699525, -75.4654466, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Edificio A1');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Edificio A2', 'Academico', null, 10.3706609, -75.4656804, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Edificio A2');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Edificio A3', 'Academico', null, 10.3693457, -75.4646923, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Edificio A3');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Edificio A4', 'Academico', null, 10.3694377, -75.4646386, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Edificio A4');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Edificio A5', 'Academico', null, 10.3691514, -75.4646644, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Edificio A5');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Edificio Alcatraz', 'Academico', null, 10.3704508, -75.4653829, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Edificio Alcatraz');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Auditorio', 'Cultura', null, 10.3704466, -75.4658228, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Auditorio');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Plaza Maloca', 'Cultura', null, 10.3702309, -75.4657558, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Plaza Maloca');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Rectoría', 'Administrativo', null, 10.3696445, -75.4652676, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Rectoría');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Laboratorio El Patio', 'Academico', null, 10.3697995, -75.465167, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Laboratorio El Patio');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Centro de Cuidado Integral (QUID)', 'Bienestar', null, 10.3692698, -75.4658852, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Centro de Cuidado Integral (QUID)');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Centro Deportivo y Cultural', 'Deporte', null, 10.3694196, -75.4657638, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Centro Deportivo y Cultural');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Cancha de fútbol', 'Deporte', null, 10.3701542, -75.4667058, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Cancha de fútbol');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Salas de estudio', 'Recursos', null, 10.3704736, -75.4653829, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Salas de estudio');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Cafetería', 'Servicios', null, 10.3704828, -75.4655097, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Cafetería');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Tienda', 'Servicios', null, 10.3694262, -75.464639, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Tienda');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Cajero automático', 'Servicios', null, 10.3705445, -75.4659509, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Cajero automático');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Pasillo de la conexión', 'Administrativo', null, 10.3704479, -75.4657786, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Pasillo de la conexión');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'Solo Café', 'Servicios', 'Espacio de conexión, ideas y conversaciones que también transforman la experiencia universitaria. Aquí nacen amistades, proyectos y networking.', 10.3702256, -75.4654775, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'Solo Café');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'La Placita', 'Cultura', 'Inspirada en las plazas del Caribe. Un espacio creado para compartir, desconectarse y sentirse en casa dentro de la UTB.', 10.3702491, -75.4653206, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'La Placita');

insert into "Pois" ("LugarId", "Nombre", "Categoria", "Descripcion", "Lat", "Lng", "Audiencias", "Activo")
select 1, 'QuantaLab', 'Academico', 'Laboratorio de analítica, IA y datos. El futuro pertenece a quienes saben interpretar información y tomar decisiones.', 10.3691307, -75.4646339, 'externo,estudiante,docente', true
 where not exists (select 1 from "Pois" where "LugarId" = 1 and "Nombre" = 'QuantaLab');

commit;
