import 'package:flutter/material.dart';

/// Colores de la app UTB anfitriona.
///
/// El tour es un módulo de esa aplicación, así que no tiene paleta propia: cada
/// valor se midió sobre las capturas de `docs/capturas_utbapp/`, promediando
/// un parche interior de cada superficie. Si la app anfitriona cambia, se
/// vuelve a medir allí; no se inventan tonos nuevos aquí.
abstract final class ColoresUtb {
  /// Fondo de página. Casi negro, con un punto de azul.
  static const fondo = Color(0xFF010406);

  /// Tarjetas: horario, notas, perfil.
  static const superficie = Color(0xFF1B1C1E);

  /// Tarjeta sobre la cabecera azul («Próxima clase»): grafito con azul.
  static const superficieSobreAzul = Color(0xFF1A1E29);

  /// Barra de navegación de la anfitriona; aquí, hojas y avisos.
  static const superficieElevada = Color(0xFF252C3E);

  /// Hoja inferior: un paso por encima del fondo, por debajo de la tarjeta.
  static const hoja = Color(0xFF121317);

  /// Píldora de la pestaña activa en la barra de la anfitriona.
  static const indicador = Color(0xFF2D3D5E);

  /// Recuadro informativo azul («En curso · 30 % evaluado»).
  static const fondoInfo = Color(0xFF1F3040);

  static const borde = Color(0x14FFFFFF);
  static const bordeFuerte = Color(0x33FFFFFF);
  static const contornoSegmentos = Color(0xFF8E9199);

  /// Azul de acción: segmento elegido, botones llenos.
  static const azul = Color(0xFF2047CD);

  /// Azul legible sobre negro: enlaces, horas, iconos activos.
  static const azulClaro = Color(0xFF6B9BF7);

  /// Azul de los textos dentro del recuadro informativo.
  static const azulInfo = Color(0xFF7FA6F0);

  static const texto = Color(0xFFFFFFFF);
  static const textoSecundario = Color(0xFFA0A2A8);

  /// Texto corrido de tercer nivel. 5,3:1 sobre la tarjeta, AA.
  static const textoTenue = Color(0xFF8E9096);

  /// Solo iconos decorativos y estados deshabilitados: 3,4:1 sobre la
  /// tarjeta no alcanza para texto.
  static const textoTerciario = Color(0xFF6E7076);

  /// Texto atenuado sobre la cabecera azul («Buenas noches,»).
  static const textoSobreAzul = Color(0xFFC9D5F7);

  static const verde = Color(0xFF52C46A);
  static const amarillo = Color(0xFFF2D54E);
  static const naranja = Color(0xFFDF9349);
  static const morado = Color(0xFFC046DF);
  static const rojo = Color(0xFFE5534B);

  // Cabecera: azul real arriba, marino abajo a la izquierda y un resplandor
  // violeta abajo a la derecha. Medido en Inicio, Agenda, Notas y Perfil.
  static const cabeceraArriba = Color(0xFF1E49D3);
  static const cabeceraMedio = Color(0xFF15318F);
  static const cabeceraAbajo = Color(0xFF0E2161);
  static const cabeceraBrillo = Color(0xFF4A4FE3);

  // Tarjeta destacada azul («Tu carnet digital»).
  static const destacadaInicio = Color(0xFF112881);
  static const destacadaFin = Color(0xFF376EBA);

  // Pantalla de arranque.
  static const arranqueCentro = Color(0xFF16307A);
  static const arranqueBorde = Color(0xFF081B45);
  static const arranqueBrillo = Color(0xFF214E77);
}

/// Colores del plano del campus.
///
/// No son de la app UTB sino de la cartografía estándar de OpenStreetMap
/// (OSM Carto): el plano tiene que leerse como un mapa de OSM, que es lo que
/// cualquiera reconoce. La tarjeta del mapa es clara por la misma razón, como
/// ya lo era con la ilustración.
abstract final class ColoresPlano {
  static const tierra = Color(0xFFF2EFE9);
  static const zona = Color(0xFFE0DFDF);
  static const campus = Color(0xFFFFFFE5);
  static const bordeCampus = Color(0xFFD4C59C);
  static const verde = Color(0xFFCDEBB0);
  static const arboles = Color(0xFFADD19E);
  static const agua = Color(0xFFAAD3DF);
  static const parqueadero = Color(0xFFEEEEEE);
  static const bordeParqueadero = Color(0xFFCCCCCC);
  static const cancha = Color(0xFFAAE0CB);
  static const bordeCancha = Color(0xFF88C9AE);
  static const plazoleta = Color(0xFFDDDDE8);
  static const edificio = Color(0xFFD9D0C9);
  static const bordeEdificio = Color(0xFFC4B6AB);
  static const via = Color(0xFFFFFFFF);
  static const bordeVia = Color(0xFFBBBBBB);
  static const viaPrincipal = Color(0xFFFCD6A4);
  static const bordeViaPrincipal = Color(0xFFC99E64);
  static const sendero = Color(0xFFFA8072);

  // Alto contraste: bordes y senderos oscurecidos hasta 3:1 contra el fondo
  // del campus (WCAG 1.4.11), sin cambiar los rellenos que dan el aspecto.
  static const bordeEdificioFuerte = Color(0xFF6B5B4E);
  static const bordeViaFuerte = Color(0xFF6E6E6E);
  static const senderoFuerte = Color(0xFFC0392B);
  static const bordeCampusFuerte = Color(0xFF8A7A4A);
}

/// Medidas compartidas. Las capturas están a 1,4 px por dp.
abstract final class MedidasUtb {
  /// Margen lateral de página.
  static const margen = 18.0;

  static const radioTarjeta = 26.0;
  static const radioCabecera = 32.0;
  static const radioCabeceraCompacta = 24.0;
  static const radioHoja = 28.0;

  /// Objetivo táctil mínimo de Material.
  static const toque = 48.0;
}

/// Colores que cambian con el alto contraste.
///
/// La paleta normal es la medida en la anfitriona y ya cumple AA. La de alto
/// contraste sube todo el texto secundario a 7:1 o más sobre la tarjeta
/// (AAA) y hace visibles los bordes de tarjetas y controles (3:1, WCAG
/// 1.4.11). Se activa con «aumentar contraste» del sistema o desde los
/// ajustes del módulo.
@immutable
class PaletaUtb extends ThemeExtension<PaletaUtb> {
  const PaletaUtb({
    required this.altoContraste,
    required this.textoSecundario,
    required this.textoTenue,
    required this.textoTerciario,
    required this.textoSobreAzul,
    required this.borde,
    required this.bordeFuerte,
    required this.veloOscuro,
  });

  static const normal = PaletaUtb(
    altoContraste: false,
    textoSecundario: ColoresUtb.textoSecundario,
    textoTenue: ColoresUtb.textoTenue,
    textoTerciario: ColoresUtb.textoTerciario,
    textoSobreAzul: ColoresUtb.textoSobreAzul,
    borde: ColoresUtb.borde,
    bordeFuerte: ColoresUtb.bordeFuerte,
    veloOscuro: Color(0x9E000000),
  );

  static const contraste = PaletaUtb(
    altoContraste: true,
    // 12,3:1, 10,6:1 y 8,4:1 sobre la tarjeta #1B1C1E; los bordes, 4,4:1.
    textoSecundario: Color(0xFFD9DBDF),
    textoTenue: Color(0xFFCACCD1),
    textoTerciario: Color(0xFFB4B6BC),
    textoSobreAzul: Color(0xFFF2F5FF),
    borde: Color(0x73FFFFFF),
    bordeFuerte: Color(0xB3FFFFFF),
    veloOscuro: Color(0xE0000000),
  );

  final bool altoContraste;
  final Color textoSecundario;
  final Color textoTenue;

  /// Iconos decorativos. En alto contraste también alcanza para texto.
  final Color textoTerciario;
  final Color textoSobreAzul;
  final Color borde;
  final Color bordeFuerte;

  /// Fondo de las píldoras que flotan sobre fotos y panorámicas.
  final Color veloOscuro;

  static PaletaUtb de(BuildContext context) =>
      Theme.of(context).extension<PaletaUtb>() ?? normal;

  @override
  PaletaUtb copyWith({bool? altoContraste}) =>
      altoContraste == null || altoContraste == this.altoContraste
      ? this
      : (altoContraste ? contraste : normal);

  @override
  PaletaUtb lerp(PaletaUtb? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return PaletaUtb(
      altoContraste: t < 0.5 ? altoContraste : other.altoContraste,
      textoSecundario: c(textoSecundario, other.textoSecundario),
      textoTenue: c(textoTenue, other.textoTenue),
      textoTerciario: c(textoTerciario, other.textoTerciario),
      textoSobreAzul: c(textoSobreAzul, other.textoSobreAzul),
      borde: c(borde, other.borde),
      bordeFuerte: c(bordeFuerte, other.bordeFuerte),
      veloOscuro: c(veloOscuro, other.veloOscuro),
    );
  }
}

/// Estilo de las etiquetas en versalitas («PRÓXIMA CLASE», «LUNES, 5 DE…»).
///
/// La anfitriona las usa sobre cada bloque de contenido, así que aquí también.
TextStyle estiloSobretitulo({Color color = ColoresUtb.textoSecundario}) =>
    TextStyle(
      fontFamily: 'Roboto',
      fontSize: 12.5,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.6,
      height: 1.2,
      color: color,
    );

ThemeData temaUtb({bool altoContraste = false}) {
  final paleta = altoContraste ? PaletaUtb.contraste : PaletaUtb.normal;
  final esquema = ColorScheme(
    brightness: Brightness.dark,
    primary: ColoresUtb.azul,
    onPrimary: ColoresUtb.texto,
    primaryContainer: ColoresUtb.indicador,
    onPrimaryContainer: ColoresUtb.texto,
    secondary: ColoresUtb.azulClaro,
    onSecondary: ColoresUtb.fondo,
    secondaryContainer: ColoresUtb.indicador,
    onSecondaryContainer: ColoresUtb.texto,
    tertiary: ColoresUtb.verde,
    onTertiary: ColoresUtb.fondo,
    error: ColoresUtb.rojo,
    onError: ColoresUtb.texto,
    surface: ColoresUtb.fondo,
    onSurface: ColoresUtb.texto,
    onSurfaceVariant: paleta.textoSecundario,
    surfaceContainerLowest: ColoresUtb.fondo,
    surfaceContainerLow: ColoresUtb.hoja,
    surfaceContainer: ColoresUtb.superficie,
    surfaceContainerHigh: ColoresUtb.superficie,
    surfaceContainerHighest: ColoresUtb.superficieElevada,
    outline: altoContraste ? ColoresUtb.texto : ColoresUtb.contornoSegmentos,
    outlineVariant: paleta.bordeFuerte,
    inverseSurface: ColoresUtb.texto,
    onInverseSurface: ColoresUtb.fondo,
    inversePrimary: ColoresUtb.azul,
    shadow: Colors.black,
    scrim: Colors.black,
  );

  // Roboto es la letra de la anfitriona: va empaquetada para que iOS y el
  // escritorio de desarrollo se vean igual que Android.
  const familia = 'Roboto';
  const textos = TextTheme(
    displaySmall: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      height: 1.1,
      letterSpacing: -0.4,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.15,
      letterSpacing: -0.3,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.2,
    ),
    titleLarge: TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.w500,
      height: 1.25,
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      height: 1.3,
    ),
    titleSmall: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      height: 1.3,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.45),
    bodyMedium: TextStyle(fontSize: 14.5, height: 1.4),
    bodySmall: TextStyle(fontSize: 13, height: 1.35),
    labelLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  );

  final textosTema = textos.apply(
    fontFamily: familia,
    bodyColor: ColoresUtb.texto,
    displayColor: ColoresUtb.texto,
  );

  final pildora = WidgetStatePropertyAll<OutlinedBorder>(const StadiumBorder());

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: esquema,
    fontFamily: familia,
    textTheme: textosTema,
    scaffoldBackgroundColor: ColoresUtb.fondo,
    extensions: [paleta],
    // El foco del teclado o del acceso con interruptores tiene que verse sobre
    // el grafito (WCAG 2.4.7); el valor por defecto de Material casi no se
    // distingue en el tema oscuro.
    focusColor: Colors.white.withValues(alpha: altoContraste ? 0.4 : 0.26),
    // Fijos para todas las plataformas: el escritorio de desarrollo usa
    // densidad compacta y encogía los controles por debajo de lo que el
    // teléfono muestra, así que las capturas mentían.
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    canvasColor: ColoresUtb.fondo,
    splashFactory: InkSparkle.splashFactory,
    dividerTheme: DividerThemeData(color: paleta.borde, thickness: 1, space: 1),
    iconTheme: const IconThemeData(color: ColoresUtb.texto),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        shape: pildora,
        minimumSize: const WidgetStatePropertyAll(Size(64, 52)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 24),
        ),
        textStyle: WidgetStatePropertyAll(textosTema.labelLarge),
        backgroundColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.disabled)
              ? ColoresUtb.superficieElevada
              : ColoresUtb.azul,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.disabled)
              ? ColoresUtb.textoTerciario
              : ColoresUtb.texto,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        shape: pildora,
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        foregroundColor: const WidgetStatePropertyAll(ColoresUtb.azulClaro),
        textStyle: WidgetStatePropertyAll(textosTema.labelLarge),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        shape: pildora,
        minimumSize: const WidgetStatePropertyAll(Size(64, 48)),
        foregroundColor: const WidgetStatePropertyAll(ColoresUtb.texto),
        side: WidgetStatePropertyAll(BorderSide(color: paleta.bordeFuerte)),
        textStyle: WidgetStatePropertyAll(textosTema.labelLarge),
      ),
    ),
    // «Horario | Eventos» de Agenda: contorno gris fino, segmento elegido en
    // azul lleno con la palomita delante.
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 46)),
        shape: pildora,
        side: WidgetStatePropertyAll(
          BorderSide(
            color: altoContraste
                ? ColoresUtb.texto
                : ColoresUtb.contornoSegmentos,
            width: altoContraste ? 1.5 : 0.8,
          ),
        ),
        textStyle: WidgetStatePropertyAll(
          textosTema.labelLarge?.copyWith(fontSize: 16.5),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.selected)
              ? ColoresUtb.azul
              : ColoresUtb.fondo,
        ),
        foregroundColor: const WidgetStatePropertyAll(ColoresUtb.texto),
        iconColor: const WidgetStatePropertyAll(ColoresUtb.texto),
        overlayColor: const WidgetStatePropertyAll(Color(0x1FFFFFFF)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: ColoresUtb.hoja,
      modalBackgroundColor: ColoresUtb.hoja,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: Color(0x55FFFFFF),
      dragHandleSize: Size(40, 4),
      showDragHandle: true,
      modalBarrierColor: Color(0xB3000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MedidasUtb.radioHoja),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ColoresUtb.superficieElevada,
      contentTextStyle: textosTema.bodyMedium,
      actionTextColor: ColoresUtb.azulClaro,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    sliderTheme: SliderThemeData(
      trackHeight: 4,
      activeTrackColor: ColoresUtb.azulClaro,
      inactiveTrackColor: altoContraste
          ? const Color(0x80FFFFFF)
          : const Color(0x24FFFFFF),
      thumbColor: ColoresUtb.texto,
      overlayColor: const Color(0x296B9BF7),
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: ColoresUtb.azulClaro,
      linearTrackColor: Color(0x24FFFFFF),
      circularTrackColor: Color(0x24FFFFFF),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: ColoresUtb.superficieElevada,
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: textosTema.bodySmall,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(
          backgroundColor: ColoresUtb.fondo,
        ),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(
          backgroundColor: ColoresUtb.fondo,
        ),
      },
    ),
  );
}
