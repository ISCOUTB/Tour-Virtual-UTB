import 'package:flutter/material.dart';

import 'levantamiento.dart';

/// App secundaria del equipo para medir el campus (ver levantamiento.dart y
/// docs/pendientes-realidad-aumentada.md). Solo Android:
///
/// ```bash
/// flutter run              # con el teléfono conectado
/// flutter build apk        # para pasarla a los teléfonos del equipo
/// ```
void main() => runApp(const HerramientaLevantamiento());
