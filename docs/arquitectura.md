# UTB Tour Virtual — Arquitectura y plan de desarrollo

**Fecha:** 3 de agosto de 2026
**Estado:** decisiones fundacionales cerradas, pendiente ejecución de Fase 0
**Documento previo:** [utb-tour-inmersivo-mvp.md](utb-tour-inmersivo-mvp.md) (define el alcance funcional del recorrido; este documento define cómo se construye)

---

## 0) Cambio de alcance respecto al MVP original

El documento de MVP cubría únicamente la app móvil con contenido mock. El alcance actual añade tres ejes que no estaban contemplados:

- **Panel web de administración** con gestión de POIs, multimedia, rutas y analítica.
- **Tres perfiles de usuario** (externo, estudiante, docente) con recorridos diferenciados.
- **Autenticación, auditoría y cumplimiento legal** de tratamiento de datos personales.

El esfuerzo estimado pasa de 10 a 14–16 semanas.

### Inconsistencia resuelta

Los mockups del panel administrativo mencionan «configurar navegación y visualización AR». El documento de MVP descartó explícitamente la realidad aumentada en favor del recorrido 360 por escenas panorámicas (Ruta A). **Se mantiene 360.** Cualquier funcionalidad AR se trata como fase posterior con su propio análisis.

---

## 1) Decisiones de arquitectura

| Decisión | Elección | Motivo |
|---|---|---|
| Panel administrativo | Next.js 15 + React 19 + TypeScript | Ecosistema maduro para tablas, formularios y el editor visual de hotspots; hosting gratuito |
| Backend | Supabase + API .NET 9 | Aprovecha la API existente; Supabase resuelve auth, Postgres, storage y RLS sin construirlos |
| Almacenamiento de medios | Cloudflare R2 | 10 GB gratis y egreso sin costo; Supabase Storage (1 GB) no soporta panorámicas ni video |
| Perfil «externo» | Visitantes externos a la UTB | Aspirantes, familias y público general; no implica internacionalización inmediata |
| Autenticación | Supabase Auth: anónima + OTP por dominio | Los externos no poseen cuenta institucional; forzar login los excluiría |
| Internacionalización | Diferida a Fase 4, esquema creado en Fase 0 | Añadir el modelo de traducciones más tarde es un retrofit costoso |
| Ruta de datos del móvil | Supabase directo | RLS aplica el filtrado por audiencia sin intermediario; elimina el riesgo de que un salto extra lo anule |

### 1.1) Ruta de datos y el riesgo de `service_role`

La aplicación móvil consume Supabase directamente mediante `supabase_flutter`:
autenticación y lectura de contenido pasan por PostgREST, donde las políticas
RLS ya resuelven el filtrado por audiencia verificado en la Fase 0.

La API .NET conserva un alcance acotado:

- Escrituras del panel de administración que requieren lógica de negocio.
- Agregación de analítica para el módulo de reportes.
- Cualquier operación que combine varias fuentes o aplique reglas que no
  convenga expresar en SQL.

> **Regla que no se puede relajar.** Todo componente que consulte Postgres en
> nombre de un usuario final debe reenviar el JWT de ese usuario. Conectarse
> con `service_role` **omite RLS por completo**: el filtrado por audiencia
> dejaría de aplicar y cualquier usuario podría leer el contenido curado para
> otro perfil. `service_role` queda reservado para tareas de servidor sin
> usuario asociado, como la purga programada de eventos.

En consecuencia, los caminos de lectura descritos en el contrato OpenAPI
(`/Escenas`, `/Hotspots`, `/Pois`, `/Rutas`) documentan la API .NET, no la ruta
que sigue la aplicación móvil.

---

## 2) Estructura del repositorio

```
utbtour/
  apps/
    mobile/              Flutter — aplicación de usuarios (hoy utb_virtual_placeholder)
    admin/               Next.js — panel de administración
  services/
    api/                 .NET 9 Minimal API
  packages/
    contracts/           Especificación OpenAPI y clientes generados (Dart + TypeScript)
  supabase/
    migrations/          Migraciones SQL versionadas
    policies/            Políticas RLS
  docs/
```

El contrato OpenAPI es la fuente de verdad de la interfaz entre capas. Los clientes de Dart y TypeScript se generan a partir de él, lo que impide que el móvil y el panel se desincronicen del backend.

El proyecto `utb_virtual_placeholder` se renombra a `mobile` con el nombre de paquete `utb_tour`.

---

## 3) Stack técnico

### Aplicación móvil (Flutter)

| Necesidad | Paquete | Notas |
|---|---|---|
| Estado | `flutter_riverpod` + `riverpod_generator` | Hoy no existe capa de estado |
| Navegación | `go_router` | Habilita deep links directos a un POI |
| Modelos | `freezed` + `json_serializable` | Reemplaza los `Map<String, dynamic>` crudos actuales |
| HTTP | `dio` | Interceptores, reintentos, refresco de token |
| Caché offline | `drift` (SQLite) | Recorrido y metadatos disponibles sin red |
| Imágenes | `cached_network_image` | |
| Video | `video_player` + `chewie` | Requiere subtítulos por accesibilidad |
| Audio | `just_audio` | Narración por POI |
| Panorámicas | `panorama_viewer` | Ya integrado |
| Animación | `flutter_animate` | Ya integrado |
| Credenciales | `flutter_secure_storage` | Keychain / Keystore, nunca SharedPreferences |
| Traducciones | `flutter_localizations` + ARB | Se activa en Fase 4 |

**Mapa del campus.** El diseño aprobado utiliza un render ilustrado del campus, no cartografía de tiles. Se descarta `flutter_map` y Mapbox en esta etapa: la imagen ilustrada se muestra dentro de un `InteractiveViewer` con marcadores posicionados mediante coordenadas normalizadas (`map_x`, `map_y`) provenientes de base de datos. Es más liviano, sin costo de tiles y fiel al diseño.

Esto sustituye a `_CampusPlaceholderPainter` y a la generación aleatoria de POIs del código actual. Se conservan además `lat` y `lng` reales en el modelo para habilitar cartografía real en el futuro sin migración.

**Patrones de interfaz.** Ficha de POI como `DraggableScrollableSheet` con puntos de anclaje y cabecera colapsable; transición `Hero` desde el marcador del mapa hacia la escena 360; parallax en la galería mediante `SliverAppBar` sobre el desplazamiento; esqueletos de carga en lugar de indicadores circulares. Se debe respetar `MediaQuery.disableAnimations` para usuarios con sensibilidad al movimiento.

### Panel de administración (Next.js)

- Next.js 15, React 19, TypeScript, Tailwind CSS, shadcn/ui.
- TanStack Table para listados; Recharts para el módulo de analítica.
- Motion y Lenis para transiciones y desplazamiento suave.
- **Editor visual de hotspots:** visor 360 en web (`pannellum` o `three.js`) sobre el que el administrador hace clic para fijar `pitch` y `yaw`. Esto elimina el riesgo de «complejidad de posicionar hotspots precisos» identificado en el documento de MVP.
- Despliegue en Cloudflare Pages o Vercel (nivel gratuito).

### Backend

- **Supabase:** Postgres, Auth, RLS, Realtime. Nivel gratuito: 500 MB de base de datos, 50 000 usuarios activos mensuales.
- **API .NET 9 Minimal API:** valida el JWT emitido por Supabase, concentra las escrituras administrativas, la lógica de negocio y la agregación de analítica. Conserva el trabajo ya realizado sobre `Escenas` y `Hotspots`.
- **Cloudflare R2:** panorámicas equirectangulares, video, audio y galerías. La subida se realiza mediante URL firmada emitida por la API; el cliente nunca recibe credenciales de almacenamiento.

Techos a vigilar: Supabase Storage (1 GB) y R2 (10 GB). El video es lo que agota ambos. Si el catálogo crece, la salida es alojar video en YouTube o Vimeo como no listado.

---

## 4) Modelo de datos

```sql
lugares(id, nombre, slug)

pois(id, lugar_id, nombre, categoria, descripcion,
     lat, lng, map_x, map_y, escena_principal_id, audiencias[], activo)

escenas(id, lugar_id, poi_id, imagen_url, es_escena_principal, orden)

hotspots(id, escena_id, tipo, pitch, yaw, escena_destino_id, poi_id)
  -- tipo: 'navegacion' | 'info'

medios(id, poi_id, tipo, url, orden, duracion_seg, texto_alt, subtitulos_url)
  -- tipo: 'imagen' | 'video' | 'audio'

rutas(id, nombre, audiencia, activa)
ruta_pois(ruta_id, poi_id, orden)

traducciones(entidad, entidad_id, campo, idioma, valor)

perfiles(user_id, rol, audiencia, creado_en)
  -- rol: 'externo' | 'estudiante' | 'docente' | 'admin'

consentimientos(user_id, sesion_id, tipo, version, aceptado_en, ip_hash)

eventos(id, sesion_id, user_id, tipo, poi_id, escena_id, payload jsonb, ts)

auditoria(id, actor_id, accion, entidad, entidad_id, antes jsonb, despues jsonb, ip, ts)
```

`eventos` cubre los KPI definidos en el documento de MVP: `virtual_map_open`, `scene_viewed`, `hotspot_tapped`, `poi_media_played`, `tour_completed`.

`auditoria` no es opcional. Los administradores modifican contenido institucional publicado; debe existir registro de quién cambió o eliminó qué, y cuál era el estado anterior.

---

## 5) Perfiles de usuario

La diferenciación se implementa mediante rutas curadas y filtrado de contenido, no mediante aplicaciones distintas.

| Perfil | Acceso | Recorrido |
|---|---|---|
| **Externo** | Sin cuenta, sesión anónima | Ruta institucional: fachada, biblioteca, bienestar, zona de comidas, murales |
| **Estudiante** | Correo `@utb.edu.co` | Ruta de servicios: trámites, salones, laboratorios del programa, bienestar |
| **Docente** | Correo `@utb.edu.co`, perfil declarado | Ruta académica: laboratorios, salas de profesores, recursos de investigación |

El campo `pois.audiencias[]` y `rutas.audiencia` controlan la visibilidad. El rol viaja como *claim* dentro del JWT y **se valida siempre en el servidor**; el cliente nunca decide su propio nivel de acceso.

---

## 6) Autenticación

Tres niveles sobre Supabase Auth:

1. **Sesión anónima** (`signInAnonymously`) para externos. Acceso inmediato, sin recolección de datos personales. El usuario obtiene un `user_id` válido, de modo que RLS y analítica funcionan con normalidad. Rol asignado: `externo`.
2. **OTP por correo** para miembros de la universidad. No depende de la disponibilidad de TI para arrancar.
3. **OIDC institucional** (Microsoft Entra ID o Google Workspace) como proveedor adicional, incorporable más adelante sin migrar usuarios existentes.

**Promoción de sesión.** Supabase permite vincular una identidad real a un usuario anónimo previo. Un visitante externo que decida crear cuenta conserva su progreso e historial sin generar registros duplicados.

### Asignación de rol

La UTB opera un **único dominio de correo**, `utb.edu.co`, tanto para estudiantes como para docentes. El dominio distingue por tanto entre miembro de la universidad y externo, pero no entre estudiante y docente. El mecanismo es:

1. Un *trigger* sobre `auth.users` asigna rol según el dominio: `@utb.edu.co` produce `estudiante` con `verificado = false`; cualquier otro dominio produce `externo`.
2. En el primer inicio de sesión, el usuario **declara su perfil** (estudiante o docente). La declaración se registra pero no se considera verificada.
3. El panel de administración permite verificar o corregir el rol de cualquier usuario.

La autodeclaración es proporcionada al riesgo: el rol solo determina qué recorrido curado se muestra, no da acceso a datos sensibles ni a operaciones privilegiadas. El peor caso es que un usuario vea el recorrido equivocado. Si en el futuro se integra el sistema académico o LDAP, la verificación se automatiza sin cambiar el modelo.

**El rol `admin` nunca se asigna por dominio ni por autodeclaración.** Solo por invitación explícita, con MFA obligatorio.

---

## 7) Seguridad, privacidad y cumplimiento

### Marco legal aplicable

La UTB opera en Colombia, por lo que aplica la **Ley 1581 de 2012** (Habeas Data) y el **Decreto 1377 de 2013**. Si se recibe tráfico de usuarios europeos, aplica adicionalmente el GDPR.

Obligaciones a cubrir antes del piloto:

- Política de Tratamiento de Datos Personales, publicada y versionada.
- Aviso de privacidad presentado antes de recolectar cualquier dato.
- Consentimiento expreso, granular y registrado, con versión y fecha (tabla `consentimientos`).
- Inscripción de la base de datos ante la SIC en el RNBD. Es una obligación institucional, no técnica: debe escalarse a la universidad.
- Términos de servicio y canal habilitado para el ejercicio de derechos (consulta, rectificación, supresión).

**Derechos de imagen.** Las panorámicas 360 del campus capturan personas identificables, lo que constituye tratamiento de datos personales. Las capturas ya existen y se irán incorporando de forma progresiva, por lo que la mitigación es retroactiva y se implementa como paso obligatorio del pipeline de ingesta, descrito en la sección 7.1.

### 7.1) Pipeline de ingesta de panorámicas

Ninguna panorámica se sube a R2 sin pasar por estos pasos:

1. **Difuminado automático de rostros** con [`deface`](https://github.com/ORB-HD/deface) (Python, licencia MIT), procesable por lote sobre imágenes y video.
2. **Revisión visual manual.** La proyección equirectangular deforma los rostros cerca de los polos y reduce la tasa de detección; el paso automático no es suficiente por sí solo.
3. **Eliminación de metadatos EXIF/GPS**, que en cámaras 360 incluyen ubicación y número de serie del equipo.
4. **Compresión** a WebP o JPEG progresivo, con una variante de menor resolución para dispositivos de gama baja.
5. Subida mediante URL firmada y registro en la tabla `escenas`.

El difuminado también evita que las imágenes puedan clasificarse como datos biométricos, categoría sensible bajo la Ley 1581 con régimen reforzado de tratamiento.

### 7.2) Registro ante la SIC (RNBD)

El Registro Nacional de Bases de Datos es un directorio público administrado por la Superintendencia de Industria y Comercio. Base legal: Ley 1581 de 2012 (artículo 25), Decreto 1074 de 2015 y Circular Externa 002 de 2015 de la SIC.

> Los umbrales de obligatoriedad y los plazos de reporte deben confirmarse contra la fuente oficial vigente de la SIC antes de actuar; se modifican por decreto.

**Obligados:** entidades públicas y personas jurídicas privadas cuyos activos totales superen el umbral en UVT fijado por el Decreto 090 de 2018. La UTB, como institución privada de educación superior, con alta probabilidad está obligada y muy posiblemente ya tenga bases inscritas (admisiones, nómina, egresados).

**Requisito previo:** existencia de una Política de Tratamiento de Datos Personales y un Aviso de Privacidad aprobados y publicados. Lo previsible es que la UTB ya los tenga y que falte incorporar la finalidad específica del recorrido virtual.

**Información que solicita el formulario:** identificación del responsable y del encargado; canal de atención a titulares; nombre y finalidad de la base; tipos de datos, señalando datos sensibles y de menores; medidas de seguridad; política de tratamiento vigente; transferencias y transmisiones nacionales e internacionales.

**Puntos específicos de este proyecto:**

- Las imágenes de personas identificables en las panorámicas son datos personales. El difuminado descrito en 7.1 evita que escalen a categoría sensible.
- Supabase y Cloudflare alojan datos fuera de Colombia, lo que constituye **transmisión internacional** y debe declararse. La región contratada de cada proveedor debe elegirse y documentarse en Fase 0.

**Obligaciones continuas:** actualización anual de novedades dentro del primer trimestre, reporte de reclamos de titulares y reporte de incidentes de seguridad en un plazo breve en días hábiles desde su detección.

**Interlocutor institucional:** Secretaría General o Dirección Jurídica; si existe un Oficial de Protección de Datos designado, es esa persona.

**Preguntas a resolver con la universidad:**

1. ¿La UTB está ya inscrita en el RNBD y con qué bases de datos?
2. ¿Esta base se inscribe como nueva o como novedad de una existente?
3. ¿La política de tratamiento vigente cubre la finalidad «recorrido virtual del campus con analítica de uso»?
4. ¿Quién es el responsable designado y cuál es el canal oficial de atención a titulares?
5. ¿Existe política institucional sobre alojamiento de datos fuera del país?

### Controles técnicos

- HTTPS obligatorio. `android:usesCleartextTraffic="false"`.
- Añadir el permiso `INTERNET` al `AndroidManifest.xml` principal. Actualmente solo está declarado en el manifest de depuración, por lo que un APK de release no alcanzará la API.
- JWT de vida corta con refresco rotatorio. Credenciales exclusivamente en `flutter_secure_storage`.
- RLS habilitado en **todas** las tablas de Postgres, con política por defecto de denegación.
- Panel administrativo: MFA obligatorio (TOTP), expiración de sesión, mínimo privilegio y registro de toda mutación en `auditoria`.
- Carga de medios: URL firmada, validación de MIME por *magic bytes* (no por extensión), límite de tamaño y **eliminación de metadatos EXIF/GPS** en imágenes.
- Analítica bajo consentimiento explícito, con IP anonimizada, retención definida (12 meses) y purga automática.
- Sin secretos en el repositorio. Configuración de compilación mediante `--dart-define`; secretos de CI en GitHub Secrets.
- Referencias de control: OWASP MASVS (móvil), OWASP ASVS (panel web).

### Accesibilidad

Objetivo WCAG 2.2 nivel AA:

- Subtítulos en video y transcripción del audio narrativo.
- Contraste verificado sobre la paleta institucional.
- Etiquetas `Semantics` en marcadores del mapa y hotspots de las escenas.
- Soporte de texto escalado y de la preferencia de reducción de movimiento.

---

## 8) Plan de desarrollo

### Fase 0 — Fundaciones (2 semanas)

Monorepo y renombrado del proyecto Flutter. Proyecto Supabase con esquema completo y RLS. Bucket R2. CI en GitHub Actions. Contrato OpenAPI v1. Corrección de la deuda existente: `test/widget_test.dart` roto y permiso `INTERNET` ausente.

### Fase 1 — Base móvil (2 semanas)

Incorporación de Riverpod, go_router, freezed y dio. Mapa ilustrado con marcadores provenientes de base de datos. Ficha de POI con hoja deslizable, galería, video y audio sobre datos reales.

### Fase 2 — Contenido y recorrido 360 (2–3 semanas, en paralelo)

Captura de 8–12 panorámicas, grabación de narraciones y redacción de textos. Grafo de escenas conectado. Reescritura de `RecorridoScreen` con modelos tipados y manejo visible de errores; actualmente los fallos de red se silencian en `debugPrint` y el usuario solo ve una pantalla vacía.

### Fase 3 — Panel de administración (3 semanas)

Next.js con autenticación y MFA. CRUD de POIs. Editor visual de hotspots sobre visor 360. Gestor de multimedia con subida firmada. Registro de auditoría.

### Fase 4 — Perfiles y rutas (2 semanas)

Autenticación institucional, filtrado por audiencia, tres rutas curadas, progreso persistido e internacionalización ES/EN.

### Fase 5 — Analítica y cumplimiento (1–2 semanas)

Emisión de eventos, tablero en el panel, captura de consentimientos, publicación de políticas y banner de aceptación.

### Fase 6 — QA, accesibilidad y piloto (2 semanas)

Pruebas en dispositivos de gama baja, optimización de peso de assets, verificación WCAG y piloto con los tres perfiles.

**Total estimado:** 14–16 semanas.
**Costo de infraestructura:** 0 USD en niveles gratuitos, sujeto a los techos de almacenamiento indicados en la sección 3.

---

## 9) Asuntos abiertos

- Render ilustrado del campus en alta resolución (el mockup lo muestra, falta el asset original).
- Responsables institucionales de contenido: textos y locución.
- Confirmación de si la universidad expone Microsoft 365 o Google Workspace para OIDC en el futuro.
- Registro RNBD ante la SIC: pendiente la conversación institucional descrita en 7.2.
- Región de alojamiento a contratar en Supabase y Cloudflare, para declararla como transmisión internacional.

### Resueltos

- **Dominio de correo:** `utb.edu.co`, único para estudiantes y docentes. Resuelto en la sección 6.
- **Panorámicas:** ya capturadas, se incorporan progresivamente. Mitigación retroactiva definida en la sección 7.1.
