-- Pines ajustados con el levantamiento del campus (último cambio: 2026-11-23).
-- Generado por scripts/aplicar_pines.py. Correr una vez en el editor SQL de Supabase:
-- la carga inicial (pois_campus.sql) no cambia lugares que ya existen. Son updates
-- por nombre: correrlo otra vez no cambia nada que ya esté bien.
begin;
update "Pois" set "Lat" = 10.3699308, "Lng" = -75.4651281 where "LugarId" = 1 and "Nombre" = 'Biblioteca';  -- 10 m
update "Pois" set "Lat" = 10.3693299, "Lng" = -75.4646038 where "LugarId" = 1 and "Nombre" = 'Puente A3 - A5';  -- 18 m
update "Pois" set "Lat" = 10.3692929, "Lng" = -75.4660428 where "LugarId" = 1 and "Nombre" = 'Enfermería';  -- 57 m
update "Pois" set "Lat" = 10.3695983, "Lng" = -75.4657454 where "LugarId" = 1 and "Nombre" = 'Zona T';  -- 50 m
update "Pois" set "Lat" = 10.3698371, "Lng" = -75.4658858 where "LugarId" = 1 and "Nombre" = 'Cancha de softbol';  -- 55 m
update "Pois" set "Lat" = 10.3699525, "Lng" = -75.4654466 where "LugarId" = 1 and "Nombre" = 'Edificio A1';  -- 24 m
update "Pois" set "Lat" = 10.3706609, "Lng" = -75.4656804 where "LugarId" = 1 and "Nombre" = 'Edificio A2';  -- fachada sur (2026-11-23)
update "Pois" set "Lat" = 10.3693457, "Lng" = -75.4646923 where "LugarId" = 1 and "Nombre" = 'Edificio A3';  -- 16 m
update "Pois" set "Lat" = 10.3694377, "Lng" = -75.4646386 where "LugarId" = 1 and "Nombre" = 'Edificio A4';  -- 19 m
update "Pois" set "Lat" = 10.3691514, "Lng" = -75.4646644 where "LugarId" = 1 and "Nombre" = 'Edificio A5';  -- 6 m
update "Pois" set "Lat" = 10.3704508, "Lng" = -75.4653829 where "LugarId" = 1 and "Nombre" = 'Edificio Alcatraz';  -- 15 m
update "Pois" set "Lat" = 10.3704466, "Lng" = -75.4658228 where "LugarId" = 1 and "Nombre" = 'Auditorio';  -- 14 m
update "Pois" set "Lat" = 10.3702309, "Lng" = -75.4657558 where "LugarId" = 1 and "Nombre" = 'Plaza Maloca';  -- 21 m
update "Pois" set "Lat" = 10.3696445, "Lng" = -75.4652676 where "LugarId" = 1 and "Nombre" = 'Rectoría';  -- 6 m
update "Pois" set "Lat" = 10.3697995, "Lng" = -75.465167 where "LugarId" = 1 and "Nombre" = 'Laboratorio El Patio';  -- 18 m
update "Pois" set "Lat" = 10.3692698, "Lng" = -75.4658852 where "LugarId" = 1 and "Nombre" = 'Centro de Cuidado Integral (QUID)';  -- 23 m
update "Pois" set "Lat" = 10.3694196, "Lng" = -75.4657638 where "LugarId" = 1 and "Nombre" = 'Centro Deportivo y Cultural';  -- 20 m
update "Pois" set "Lat" = 10.3704736, "Lng" = -75.4653829 where "LugarId" = 1 and "Nombre" = 'Salas de estudio';  -- 11 m
update "Pois" set "Lat" = 10.3704828, "Lng" = -75.4655097 where "LugarId" = 1 and "Nombre" = 'Cafetería';  -- 18 m
update "Pois" set "Lat" = 10.3694262, "Lng" = -75.464639 where "LugarId" = 1 and "Nombre" = 'Tienda';  -- 162 m
update "Pois" set "Lat" = 10.3705445, "Lng" = -75.4659509 where "LugarId" = 1 and "Nombre" = 'Cajero automático';  -- 5 m
update "Pois" set "Lat" = 10.3704479, "Lng" = -75.4657786 where "LugarId" = 1 and "Nombre" = 'Pasillo de la conexión';  -- 42 m
update "Pois" set "Lat" = 10.3702256, "Lng" = -75.4654775 where "LugarId" = 1 and "Nombre" = 'Solo Café';  -- 8 m
update "Pois" set "Lat" = 10.3702491, "Lng" = -75.4653206 where "LugarId" = 1 and "Nombre" = 'La Placita';  -- 32 m
update "Pois" set "Lat" = 10.3691307, "Lng" = -75.4646339 where "LugarId" = 1 and "Nombre" = 'QuantaLab';  -- 5 m
commit;
