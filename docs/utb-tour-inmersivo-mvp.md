# UTB Virtual — MVP de Recorrido Inmersivo (Flutter)

**Fecha de actualización:** 2 de marzo de 2026  
**Producto destino:** App móvil existente **UTB Virtual** (obligatorio Flutter)  
**Público principal:** personas nuevas que no pueden visitar físicamente la universidad, estudiantes y docentes.

---

## 1) Cambio de enfoque validado con cliente

El MVP deja de ser un flujo WebAR con QR como centro y pasa a ser una **experiencia inmersiva dentro de la app UTB Virtual en Flutter**, con tres capacidades núcleo:

1. **Mapa aéreo del campus** con puntos clave remarcados.
2. **Vista en primera persona tipo “streetview like”** para recorrer la universidad desde el celular sin estar en sitio.
3. **5 puntos interactivos flotantes** dentro de la vista inmersiva con fichas de información, galería, video y audio narrado.

Sí es posible lograrlo en Flutter para un MVP funcional y escalable.

---

## 2) Alcance MVP (definición cerrada)

### Funcionalidades obligatorias
- Pantalla de mapa aéreo con POI destacados.
- Pantalla inmersiva “streetview like” navegable por escenas.
- 5 POI interactivos con botón flotante/touch hotspot.
- Modal o panel con contenido por POI:
  - descripción,
  - imágenes,
  - video,
  - audio de historia.
- Integración en la app UTB Virtual (módulo nuevo).

### 5 POI sugeridos para demo
- Zona de comidas
- Murales
- Salones representativos
- Biblioteca
- Bienestar universitario

---

## 3) Stack tecnológico recomendado (Flutter-first)

## Frontend móvil (obligatorio)
- **Flutter (Dart)** como base única de UI y lógica de presentación.
- Gestión de estado: **Riverpod** (o Bloc si ya es estándar en UTB Virtual).
- Navegación: `go_router` (si la app ya usa Navigator 2.0, respetar estándar actual).

## Mapa aéreo
- **flutter_map** + tiles de OpenStreetMap (rápido para MVP)  
  o
- **Mapbox (mapbox_maps_flutter)** si requieren estilo visual y control avanzado.

## Vista “streetview like” en Flutter
Para un MVP realista hay dos rutas:

### Ruta A (recomendada para MVP): Tour 360 por escenas panorámicas
- Plugin sugerido: `panorama_viewer` (o equivalente mantenido).
- Se usan imágenes 360° (equirectangulares) por ubicación del campus.
- Navegación entre escenas mediante hotspots.

### Ruta B (fase posterior): video esférico / navegación más compleja
- Requiere pipeline audiovisual más pesado y optimización por dispositivo.
- Más costo de captura, compresión y QA.

> Decisión recomendada: **Ruta A** para cumplir tiempos del MVP con buena experiencia.

## Hotspots interactivos + multimedia
- Hotspots superpuestos en la escena 360.
- Contenido:
  - imágenes: `cached_network_image`
  - video: `video_player` (+ `chewie` opcional)
  - audio narrado: `just_audio`

## Backend y contenido
- **Firebase** o **Supabase** para:
  - catálogo de POI,
  - URLs de media,
  - analítica de interacción.

Estructura mínima de datos (`poi`):
- `id`, `nombre`, `categoria`
- `lat`, `lng` (mapa)
- `scene_id` (escena 360)
- `hotspot_x`, `hotspot_y` (posición hotspot en escena)
- `descripcion`
- `images[]`, `video_url`, `audio_url`

## Analítica
- **Firebase Analytics** o **PostHog**.
- Eventos clave:
  - `virtual_map_open`
  - `scene_viewed`
  - `hotspot_tapped`
  - `poi_media_played`
  - `tour_completed`

---

## 4) Arquitectura funcional del MVP

## Flujo de usuario
1. Usuario abre módulo **Recorrido Virtual UTB**.
2. Entra al **Mapa Aéreo** y visualiza puntos importantes.
3. Selecciona un punto o “Iniciar tour”.
4. Abre la **vista 360 en primera persona** de una escena.
5. Toca un hotspot flotante.
6. Se abre ficha multimedia del POI (texto + imagen/video + audio narrado).
7. Avanza al siguiente hotspot/escena hasta completar 5 puntos.

## Componentes de app
- `MapScreen` (mapa + marcadores)
- `VirtualWalkScreen` (panorama 360 + hotspots)
- `PoiDetailSheet` (información multimedia)
- `TourProgressController` (progreso de 5 POI)
- `ContentRepository` (fuente local/remota)

---

## 5) Roadmap recomendado (10 semanas)

## Fase 0 — Alineación técnica y de negocio (Semana 1)
- Revisar arquitectura actual de UTB Virtual (patrones, navegación, estado).
- Definir 5 POI del MVP y responsables de contenido.
- Definir alcance cerrado de demo institucional.

## Fase 1 — Captura y preparación de contenido (Semanas 2-3)
- Captura de panoramas 360 en campus (mínimo 8–12 escenas).
- Redacción de historias por POI.
- Producción de audio narrado + assets visuales optimizados.

## Fase 2 — Base Flutter del módulo (Semanas 3-4)
- Crear módulo `utb_virtual_tour` dentro de la app.
- Implementar `MapScreen` con marcadores.
- Definir modelos de datos y repositorio de contenido.

## Fase 3 — Vista inmersiva + hotspots (Semanas 5-6)
- Integrar visor 360.
- Crear hotspots flotantes touch.
- Conectar hotspots con panel de detalle multimedia.

## Fase 4 — Integración multimedia y analítica (Semana 7)
- Reproducción de audio/video por POI.
- Telemetría de eventos principales.

## Fase 5 — QA en dispositivos reales (Semanas 8-9)
- Pruebas Android/iOS (gama media y baja).
- Optimización de peso de assets y tiempos de carga.
- Ajustes de UX accesible (textos, contraste, controles).

## Fase 6 — Piloto + entrega (Semana 10)
- Piloto con usuarios objetivo (nuevos, estudiantes, docentes).
- Ajustes finales y release candidato.
- Documento de fase 2 (escalamiento).

---

## 6) Cómo lograrlo técnicamente (implementación)

1. **Montar módulo Flutter**
   - Nueva feature en UTB Virtual: `virtual_tour`.

2. **Publicar mapa aéreo**
   - Cargar tiles y marcadores con coordenadas oficiales del campus.

3. **Construir recorrido 360**
   - Vincular escenas 360 en secuencia o grafo de navegación.

4. **Agregar hotspots flotantes**
   - Cada hotspot abre la ficha del POI con multimedia.

5. **Incluir audio narrado**
   - Botón “Escuchar historia” en cada POI.

6. **Persistir progreso y métricas**
   - Guardar POI visitados y eventos de interacción.

7. **Optimizar**
   - Comprimir panoramas y videos.
   - Cache de contenido para mejor rendimiento.

---

## 7) Riesgos y mitigaciones

- **Assets 360 pesados y carga lenta**  
  Mitigación: compresión, lazy loading y cache local.

- **Diferencias de rendimiento entre dispositivos**  
  Mitigación: QA en múltiples gamas + fallback de calidad media.

- **Complejidad de posicionar hotspots precisos**  
  Mitigación: herramienta interna simple para calibración por escena.

- **Dependencia de contenido audiovisual**  
  Mitigación: backlog de producción con fechas y responsables claros.

---

## 8) KPIs para validar el MVP

- % de usuarios que abren módulo de Recorrido Virtual.
- % que ven al menos 1 escena 360.
- % que interactúan con hotspots.
- % que completan 5 POI.
- Tiempo promedio dentro del tour.
- Satisfacción percibida (encuesta breve in-app).

---

## 9) Requisitos del entorno (Windows + Flutter)

## Herramientas necesarias
- **Flutter SDK** (estable)
- **Git**
- **VS Code** (o Android Studio como IDE alterno)
- **Visual Studio 2022/2026 Build Tools** con carga de trabajo:
  - **Desktop development with C++**
  - Windows SDK 10/11

> Para compilar Flutter Desktop en Windows, Visual Studio C++ es obligatorio.

## Extensiones recomendadas en VS Code
- Flutter (Dart-Code.flutter)
- Dart (Dart-Code.dart-code)
- Error Lens (opcional)
- GitLens (opcional)

## Comprobación de entorno
Ejecutar:
- `flutter doctor -v`

Resultado esperado:
- Windows toolchain OK
- Visual Studio C++ OK
- Flutter y Dart detectados

---

## 10) Plan de implementación técnica inicial en UTB Virtual

## Sprint 1 (placeholder funcional)
- Pantalla 1: mapa aéreo mock con puntos.
- Pantalla 2: recorrido virtual mock “streetview like”.
- Pantalla 3: detalle de POI con multimedia simulada.

## Sprint 2
- Sustituir datos mock por backend real.
- Integrar assets 360 reales.
- Integrar audio/video reales por POI.

## Sprint 3
- Integración final en app UTB Virtual.
- Ajustes de rendimiento + analítica + QA final.

---

## 11) Conclusión

El nuevo enfoque es completamente factible en Flutter y se alinea con el producto existente **UTB Virtual**.  
La estrategia más efectiva para el MVP es: **mapa aéreo + recorrido 360 por escenas + 5 hotspots multimedia interactivos**, validando adopción y experiencia antes de escalar a navegación inmersiva más avanzada.
