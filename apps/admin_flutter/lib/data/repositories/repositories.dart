import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../core/config.dart';
import '../api/api_client.dart';
import 'escena_repository.dart';
import 'medio_repository.dart';
import 'panel_repository.dart';
import 'poi_repository.dart';

export 'escena_repository.dart';
export 'medio_repository.dart';
export 'panel_repository.dart';
export 'poi_repository.dart';

/// Punto único de acceso a los datos. Las pantallas usan estas variables y no
/// saben si los datos son de ejemplo o vienen del backend.
///
/// Cambiar de uno a otro:
///   flutter run -d chrome                               -> datos de ejemplo
///   flutter run -d chrome --dart-define=USE_MOCK=false  -> backend real
/// Con login real, cada petición lleva el token de Supabase de la sesión
/// (supabase_flutter lo renueva solo antes de que venza).
final ApiClient apiClient = ApiClient(
  tokenProvider: AppConfig.loginReal
      ? () async => Supabase.instance.client.auth.currentSession?.accessToken
      : null,
);

final PoiRepository poiRepository = AppConfig.useMockData
    ? MockPoiRepository()
    : HttpPoiRepository(apiClient);

final MedioRepository medioRepository = AppConfig.useMockData
    ? MockMedioRepository()
    : HttpMedioRepository(apiClient);

final EscenaRepository escenaRepository = AppConfig.useMockData
    ? MockEscenaRepository()
    : HttpEscenaRepository(apiClient);

final PanelRepository panelRepository = AppConfig.useMockData
    ? MockPanelRepository()
    : HttpPanelRepository(apiClient);
