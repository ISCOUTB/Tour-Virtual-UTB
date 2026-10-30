/// Módulo Tour Virtual de la Universidad Tecnológica de Bolívar.
///
/// Lo que una app anfitriona, como la UTB APP, necesita para abrirlo:
///
/// ```dart
/// import 'package:tour_virtual/tour_virtual.dart';
///
/// Navigator.of(context).push(MaterialPageRoute<void>(
///   builder: (context) => TourVirtual(
///     configuracion: ConfiguracionTour(
///       fuente: const ContenidoRemoto(urlApi: 'https://api.ejemplo.edu.co'),
///       audiencia: Audiencia.estudiante,
///       alSalir: () => Navigator.of(context).pop(),
///     ),
///   ),
/// ));
/// ```
///
/// La guía completa, con las opciones de integración y lo que queda del lado
/// de la UTB, está en docs/integracion-utb-app.md.
library;

export 'app_tour.dart' show TourVirtual;
export 'configuracion_tour.dart'
    show ConfiguracionTour, ContenidoLocal, ContenidoRemoto, FuenteContenido;
export 'datos/fuente_medio.dart' show FuenteMedio;
export 'datos/modelos/modelos.dart' show Audiencia;
