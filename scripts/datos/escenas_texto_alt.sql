-- Texto alternativo de las cinco panoramicas (Escenas."TextoAlt").
--
-- Los textos salen de escenas_texto_alt.json; si cambias uno alli, cambialo
-- tambien aqui. Cada escena se reconoce por su nombre o por el nombre de su
-- panoramica (por ejemplo panoramas/biblioteca.jpg), no por su id.
-- Solo toca la columna "TextoAlt". Se puede ejecutar mas de una vez.
--
-- Requiere la migracion AgregarTextoAltEscena (dotnet ef database update).
-- Al final muestra cuantas escenas cambio cada texto: deberia ser 1 en las
-- cinco filas. Un 0 quiere decir que esa escena no existe o tiene otro nombre.
begin;

with textos (slug, nombres, texto) as (values
  ('biblioteca', array['Biblioteca'],
   'Vestíbulo amplio y luminoso de la biblioteca, de techo alto y piso claro. En el centro hay un mostrador de atención curvo. A la izquierda se abre un pasillo largo con estanterías y mesas de lectura; a la derecha, mesas junto a ventanales que dan a un jardín con palmeras. Al fondo a la derecha, una escalera con el letrero de salida.'),
  ('puente-a3-a5', array['Puente A3 - A5'],
   'Pasarela elevada y techada, con barandas metálicas a los dos lados, que une dos edificios de aulas de tres pisos. Desde ella se ven, abajo, árboles frondosos, senderos y un jardín con letras formadas por arbustos, y arriba, un cielo azul con nubes.'),
  ('enfermeria', array['Enfermeria', 'Enfermería'],
   'Sala de atención de la enfermería, blanca y bien iluminada. A la izquierda hay un escritorio con computador y, junto a la puerta de entrada, una pequeña sala de espera con sillas verdes. Al centro y a la derecha, cubículos separados por cortinas, uno de ellos con biombos azules, y equipos como un tanque de oxígeno.'),
  ('zona-t', array['Zona T'],
   'Plazoleta al aire libre a la sombra de árboles grandes y palmeras, con mesas metálicas y sillas de colores. A un lado se abre una explanada de césped; al otro, un edificio con columnas y una escalera exterior de peldaños amarillos.'),
  ('cancha-softbol', array['Cancha de softbol'],
   'Campo abierto de césped seco bajo un cielo azul con nubes, rodeado de árboles. Al fondo se ve el edificio deportivo de dos pisos, con una torre de luz.')
),
actualizadas as (
  update "Escenas" e
     set "TextoAlt" = t.texto
    from textos t
   where e."LugarId" = 1
     and (e."Nombre" = any (t.nombres)
          or lower(coalesce(e."ImagenUrl", '')) like '%' || t.slug || '%')
  returning e."Id", t.slug
)
select t.slug, count(a."Id") as escenas_actualizadas
  from textos t
  left join actualizadas a on a.slug = t.slug
 group by t.slug
 order by t.slug;

commit;
