import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'datos/modelos/modelos.dart';
import 'nucleo/configuracion.dart';

/// De dónde saca el módulo su contenido.
///
/// Todavía no está decidido si el tour vivirá con datos locales o con
/// infraestructura en la nube, y esa decisión no depende de este equipo. Las
/// dos están implementadas y se eligen al abrir el módulo, sin tocar nada más.
sealed class FuenteContenido {
  const FuenteContenido();
}

/// La API del proyecto (`services/api`), en la nube o en una máquina local.
/// Lugares, escenas y medios llegan por HTTP; los medios, con URL firmadas.
final class ContenidoRemoto extends FuenteContenido {
  const ContenidoRemoto({required this.urlApi});

  /// Por ejemplo `https://api.tour.utb.edu.co`, sin barra final.
  final String urlApi;
}

/// Contenido incluido en el módulo, sin servidor: el catálogo de lugares, las
/// escenas y los hotspots van en el código (`RepositorioDemo`).
final class ContenidoLocal extends FuenteContenido {
  const ContenidoLocal({this.medios = ''});

  /// De dónde salen las panorámicas, narraciones y subtítulos:
  /// - vacío: no hay medios y el tour muestra solo mapa y fichas;
  /// - una URL (`http://127.0.0.1:8765`): una carpeta servida por HTTP;
  /// - `FuenteMedio.empaquetados`: dentro de la propia app, sin red.
  final String medios;
}

/// Todo lo que la app anfitriona le dice al módulo al abrirlo.
///
/// La UTB APP construye una y la pasa a `TourVirtual`. La app de
/// demostración la lee de `--dart-define` con [ConfiguracionTour.desdeEntorno].
@immutable
class ConfiguracionTour {
  const ConfiguracionTour({
    required this.fuente,
    this.lugarId = 1,
    this.audiencia,
    this.alSalir,
  });

  /// La de la app de demostración: `DATOS=demo` y `MEDIOS_DEMO` eligen el
  /// contenido local; si no, la API de `API_BASE_URL`.
  factory ConfiguracionTour.desdeEntorno() => ConfiguracionTour(
    fuente: Configuracion.datosDemo
        ? const ContenidoLocal(medios: Configuracion.mediosDemo)
        : ContenidoRemoto(urlApi: Configuracion.apiBaseUrl),
    lugarId: Configuracion.lugarPorDefecto,
  );

  final FuenteContenido fuente;

  /// Sede o campus. 1 es el Campus Tecnológico de Ternera.
  final int lugarId;

  /// Quién usa el módulo, si la app anfitriona lo sabe. Elige el recorrido
  /// curado para su perfil. Nulo, la API lo trata como visitante externo.
  ///
  /// Hoy viaja en la cabecera `X-UTB-Audiencia`. En producción la API debería
  /// sacarlo de la sesión de la UTB APP y no creérselo al cliente: ver
  /// docs/integracion-utb-app.md.
  final Audiencia? audiencia;

  /// Qué hacer cuando el usuario sale del módulo desde su pantalla principal,
  /// normalmente `Navigator.pop` en la app anfitriona. Si es nulo, la flecha
  /// de volver solo aparece cuando hay algo que cerrar dentro del módulo.
  final VoidCallback? alSalir;

  bool get esLocal => fuente is ContenidoLocal;
}

/// Configuración con que se abrió el módulo. `TourVirtual` la sustituye por la
/// que recibe; las pruebas pueden sustituirla también.
final configuracionTourProvider = Provider<ConfiguracionTour>(
  (ref) => ConfiguracionTour.desdeEntorno(),
);
