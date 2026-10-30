# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

> Se publica también en iOS con el mismo lenguaje visual de marca, sin adaptarse
> a las convenciones de cada sistema. Se registra `android` porque es el único
> objetivo ejercitado hasta hoy y el que define las rutas de assets y el
> empaquetado; al abordar iOS hay que cargar además su guía de plataforma. No es
> `adaptive`: la decisión explícita fue un solo diseño para ambas tiendas.

## Users

- **Visitante externo** (principal). Aspirantes, familias y público general sin
  vínculo con la universidad. No tienen cuenta institucional y entran sin
  registrarse.
- **Estudiante.** Miembro de la comunidad con correo `@utb.edu.co`.
- **Docente.** Mismo dominio de correo; el perfil se distingue por
  autodeclaración, no por el correo.
- **Administrador.** Personal institucional que gestiona contenido desde el
  panel web. Solo por invitación.

En todos los perfiles hay personas de otros países (Brasil, Portugal, Italia,
Estados Unidos, Francia, Turquía, Corea, China, Japón…) y personas con
discapacidad visual, auditiva, motriz, del habla o cognitiva. El módulo tiene
que servirles a todas; ver Accessibility & Inclusion.

## Product Purpose

Permitir recorrer el campus de la Universidad Tecnológica de Bolívar sin estar
físicamente allí, y que cada perfil vea un recorrido curado para él.

El éxito del piloto se mide con: proporción de usuarios que abren el módulo, que
ven al menos una escena 360, que interactúan con hotspots y que completan los
cinco POI; tiempo promedio dentro del recorrido; y satisfacción percibida.

## Positioning

Es el recorrido **oficial** de la institución: panorámicas reales del campus y
contenido aprobado por la universidad, no una reconstrucción de terceros ni una
capa sobre cartografía genérica.

El mecanismo que lo distingue es la curaduría por audiencia: el mismo campus se
cuenta distinto a un aspirante, a un estudiante y a un docente, y esa separación
se aplica en la base de datos, no en la interfaz.

## Operating Context

Tres escenas de uso confirmadas, todas vigentes:

1. **En casa, decidiendo dónde estudiar.** Sesiones largas y exploratorias, en
   el teléfono propio, sin acompañamiento.
2. **En ferias y visitas guiadas.** Alguien de la universidad la muestra durante
   un evento de admisiones. Sesiones cortas, con acompañante, y con conectividad
   frecuentemente mala.
3. **Dentro del campus, orientándose.** El usuario ya está en la universidad y
   la usa para ubicarse, lo que carga el peso sobre el mapa y no sobre el
   recorrido 360.

El contenido lo produce personal institucional, no el equipo de desarrollo.

## Capabilities and Constraints

- Mapa isométrico del campus con marcadores de POI posicionados desde base de
  datos.
- Recorrido 360 por escenas panorámicas enlazadas mediante hotspots.
- Ficha por POI con descripción, galería, video y audio narrado.
- Tres recorridos curados, uno por audiencia.
- Panel web de administración con auditoría de cambios. **Aún no existe.**
- El alcance cerrado del MVP son **cinco POI**. Ampliarlo es una decisión de
  producto, no técnica.
- El filtrado por audiencia se aplica con RLS en Postgres. Reimplementarlo en el
  cliente lo volvería evadible.
- El visitante externo no necesita cuenta: sesión anónima.
- Objetivo explícito de QA en dispositivos de gama media y baja.
- Toda la infraestructura vive en niveles gratuitos, con techos de
  almacenamiento que el video agota primero.
- Interfaz en once variantes de idioma, con el español como original;
  documentación en español. El contenido institucional llega en español
  hasta que el backend lo traduzca.
- Las panorámicas deben pasar por difuminado de rostros y limpieza de metadatos
  antes de subirse.
- Cumplimiento de la Ley 1581 de 2012. La inscripción ante la SIC está
  **pendiente** y depende de la universidad.

## Brand Commitments

- Nombre del producto: **UTB Tour Virtual**.
- El logo de la UTB y el azul institucional son vinculantes.
- **El tour es un módulo de la app UTB** oficial (Play Store y App Store) y
  adopta su lenguaje visual tal cual, sin estilo propio: tema oscuro,
  cabeceras azules con arcos que colapsan, tarjetas grafito, Roboto,
  sobretítulos en versalitas, el selector segmentado de Agenda y los anillos de
  avance. La referencia son las capturas de `docs/capturas_utbapp/`; los tonos
  se miden ahí, no se inventan. El módulo no tiene barra inferior propia porque
  la pone la app anfitriona, y tampoco replica su asistente (el robot), que es
  global de la anfitriona. Decidido el 2026-10-11.
- **No existe manual de marca formal.** Fuera de lo que la app anfitriona ya
  fija, no hay guía que obligue composición ni paleta extendida.
- El texto de interfaz se escribe primero en español y se traduce; el nombre
  de la universidad no se traduce.

## Evidence on Hand

- `assets/Mapa_UTB.pdf` — mapa isométrico oficial del campus, con dieciséis
  edificios nombrados y sus posiciones. Es material institucional real.
- `docs/capturas_utbapp/` — capturas de la app UTB anfitriona: la autoridad
  visual del módulo. No se versionan: muestran datos personales.
- `packages/tour_virtual/assets/` — logo institucional (extraído del
  vector de `assets/Mapa_UTB.pdf`) y la tipografía Roboto.
- `docs/utb-tour-inmersivo-mvp.md` y `docs/arquitectura.md` — alcance y
  decisiones técnicas.

Ausencias que no se deben rellenar inventando:

- **No hay panorámicas incorporadas.** Existen capturas, pero no han pasado por
  el pipeline de ingesta; el seed apunta a URL inexistentes a propósito.
- **No hay textos definitivos de POI ni audios narrados.** Las descripciones
  están vacías deliberadamente.
- **No hay datos de uso reales**, ni testimonios, ni métricas de adopción.

## Product Principles

1. **La curaduría por audiencia se decide en el servidor.** Es una regla de
   integridad del producto, no una optimización.
2. **Nada falla en silencio.** Si algo no carga, la interfaz lo dice y ofrece
   salida.
3. **No se inventa contenido institucional.** Un dato vacío es preferible a uno
   verosímil pero falso.
4. **La gama baja es el objetivo, no el caso límite.**
5. **El visitante externo entra sin fricción.** Pedirle una cuenta excluiría al
   público principal.

## Accessibility & Inclusion

Objetivo WCAG 2.2 nivel AA. El detalle, con el reparto del trabajo y lo que
falta, está en `docs/ACCESIBILIDAD.md`.

- Interfaz en español, inglés, portugués (Brasil y Portugal), francés,
  italiano, alemán, turco, coreano, japonés y chino; sigue el idioma del
  teléfono y cae al inglés.
- Subtítulos en vivo y transcripción de audio y video; narración por idioma;
  video en Lengua de Señas Colombiana cuando exista.
- Lector de pantalla en todo el módulo, incluido el visor 360, que se recorre
  con botones sin arrastrar.
- Texto hasta 200 %, alto contraste AAA, reducción de movimiento y giroscopio
  desactivable, sumados a los ajustes del sistema.

El audio narrado por POI, previsto como recurso editorial, cumple además una
función de accesibilidad.
