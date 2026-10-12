// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'textos.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class TextosPt extends Textos {
  TextosPt([String locale = 'pt']) : super(locale);

  @override
  String get tituloApp => 'UTB Tour Virtual';

  @override
  String get tourVirtual => 'Tour virtual';

  @override
  String get volver => 'Voltar';

  @override
  String get reintentar => 'Tentar novamente';

  @override
  String get listo => 'Pronto';

  @override
  String get falloConexion =>
      'Não conseguimos conectar. Verifique sua conexão com a internet e tente novamente.';

  @override
  String get falloTiempo =>
      'O servidor demorou demais para responder. Tente novamente.';

  @override
  String get falloSesion =>
      'Sua sessão expirou. Entre novamente para continuar.';

  @override
  String get falloSinContenido => 'Ainda não há conteúdo disponível aqui.';

  @override
  String get falloInesperado =>
      'Algo deu errado. Tente novamente em instantes.';

  @override
  String get falloPanoramasSoloConApi =>
      'As imagens panorâmicas só aparecem com o app conectado à API.';

  @override
  String get enlaceInvalido => 'Esse link não é válido.';

  @override
  String get rutaPorDefecto => 'Percurso do campus';

  @override
  String cantidadLugares(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total lugares',
      one: '1 lugar',
    );
    return '$_temp0';
  }

  @override
  String get titularSinLugares => 'Ainda não há lugares';

  @override
  String get titularEmpieza => 'Comece seu percurso';

  @override
  String get recorridoCompleto => 'Percurso concluído';

  @override
  String titularAvance(int hechos, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Você visitou $hechos de $total lugares',
      one: 'Você visitou $hechos de 1 lugar',
    );
    return '$_temp0';
  }

  @override
  String get detalleEmpieza => 'Conheça o campus, um lugar de cada vez.';

  @override
  String get detalleCompleto => 'Volte a qualquer lugar quando quiser.';

  @override
  String detalleSiguiente(String nombre) {
    return 'Próximo: $nombre';
  }

  @override
  String lugaresVisitados(int hechos, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$hechos de $total lugares visitados',
      one: '$hechos de 1 lugar visitado',
    );
    return '$_temp0';
  }

  @override
  String get modoRecorrido => 'Percurso';

  @override
  String get modoMapa => 'Mapa';

  @override
  String get idiomaYAccesibilidad => 'Idioma e acessibilidade';

  @override
  String get sinLugaresPublicados =>
      'Ainda não há lugares publicados neste percurso.';

  @override
  String get paradas => 'Paradas';

  @override
  String avanceLugares(int hechos, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$hechos de $total lugares',
      one: '$hechos de 1 lugar',
    );
    return '$_temp0';
  }

  @override
  String conocisteLosLugares(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Você conheceu os $total lugares',
      one: 'Você conheceu o lugar',
    );
    return '$_temp0';
  }

  @override
  String get vuelveACualquiera => 'Volte a qualquer um quando quiser.';

  @override
  String get volverAEmpezar => 'Começar de novo';

  @override
  String get primeraParada => 'Primeira parada';

  @override
  String get empezarRecorrido => 'Começar percurso';

  @override
  String get siguienteParada => 'Próxima parada';

  @override
  String get continuarRecorrido => 'Continuar percurso';

  @override
  String paradaNDeTotal(int numero, int total) {
    return 'Parada $numero de $total';
  }

  @override
  String get visitado => 'Visitado';

  @override
  String get lugarDelCampus => 'Lugar do campus';

  @override
  String get campus => 'Campus';

  @override
  String yaVisitado(String nombre) {
    return '$nombre, já visitado';
  }

  @override
  String paradaSemantica(int numero, String nombre) {
    return 'Parada $numero, $nombre';
  }

  @override
  String get sugerencia => 'Sugestão';

  @override
  String get sugerenciaTitulo => 'Encontre cada parada no campus';

  @override
  String get sugerenciaTexto =>
      'O mapa mostra onde fica cada lugar e quais você já visitou.';

  @override
  String get abrirMapa => 'Abrir o mapa';

  @override
  String get pieOficial =>
      'Percurso oficial da Universidad Tecnológica de Bolívar';

  @override
  String get datosDemostracion => 'Dados de demonstração';

  @override
  String get categoriaRecursos => 'Recursos';

  @override
  String get categoriaAcademico => 'Acadêmico';

  @override
  String get categoriaBienestar => 'Bem-estar';

  @override
  String get categoriaServicios => 'Serviços';

  @override
  String get categoriaDeporte => 'Esporte';

  @override
  String get verTodoCampus => 'Ver todo o campus';

  @override
  String get acercar => 'Aproximar';

  @override
  String get alejar => 'Afastar';

  @override
  String get mapaNoCargo => 'Não conseguimos carregar o mapa do campus.';

  @override
  String get mapaDescripcion =>
      'Mapa ilustrado do campus. Cada parada tem um marcador numerado.';

  @override
  String visitadosDeTotal(int hechos, int total) {
    return '$hechos de $total visitados';
  }

  @override
  String get sinUbicacionMapa => 'Sem localização no mapa';

  @override
  String get sinDescripcion => 'Ainda não há descrição deste lugar.';

  @override
  String get verEn360 => 'Ver em 360°';

  @override
  String get sin360 => 'Este lugar ainda não tem visita em 360°.';

  @override
  String get audioNarrado => 'Áudio narrado';

  @override
  String get galeria => 'Galeria';

  @override
  String get video => 'Vídeo';

  @override
  String get lenguaDeSenas => 'Língua de sinais';

  @override
  String get contenidoEnPreparacion => 'Conteúdo em preparação';

  @override
  String todaviaNoHay(String lista) {
    return 'Ainda não há: $lista';
  }

  @override
  String get fotos => 'Fotos';

  @override
  String textoEnIdioma(String idioma) {
    return 'Informação disponível em $idioma';
  }

  @override
  String get deslizaParaMirar => 'Deslize para olhar';

  @override
  String get fotoDelLugar => 'Foto do lugar';

  @override
  String fotoNDeTotal(int numero, int total) {
    return '$numero de $total';
  }

  @override
  String get fotoNoCargo => 'Não conseguimos carregar esta foto.';

  @override
  String get videoNoCargo => 'Não conseguimos carregar o vídeo.';

  @override
  String get pausarVideo => 'Pausar vídeo';

  @override
  String get reproducirVideo => 'Reproduzir vídeo';

  @override
  String get audioSinSoporte =>
      'O áudio não pode ser reproduzido nesta plataforma.';

  @override
  String get audioNoCargo => 'Não conseguimos carregar o áudio.';

  @override
  String get pausarAudio => 'Pausar áudio narrado';

  @override
  String get escucharHistoria => 'Ouvir a história';

  @override
  String get escuchando => 'Ouvindo';

  @override
  String get transcripcionEnPreparacion => 'Transcrição em preparação';

  @override
  String get leerTranscripcion => 'Ler a transcrição';

  @override
  String get transcripcion => 'Transcrição';

  @override
  String get subtitulos => 'Legendas';

  @override
  String narracionEn(String idioma) {
    return 'Narração em $idioma';
  }

  @override
  String get escucharEn => 'Ouvir em';

  @override
  String posicionDeTotal(String posicion, String total) {
    return '$posicion de $total';
  }

  @override
  String vistaPanoramicaDe(String nombre) {
    return 'Vista panorâmica de $nombre';
  }

  @override
  String get esteLugar => 'este lugar';

  @override
  String get deslizaParaGirar => 'Deslize para os lados para girar';

  @override
  String get girarIzquierda => 'Girar para a esquerda';

  @override
  String get girarDerecha => 'Girar para a direita';

  @override
  String get sinEscenas => 'Este percurso ainda não tem cenas publicadas.';

  @override
  String get siguienteEscena => 'Próxima cena';

  @override
  String get puntoDeInteres => 'Ponto de interesse';

  @override
  String get caminandoHacia => 'Caminhando até';

  @override
  String escenaNDeTotal(int numero, int total) {
    return 'Cena $numero de $total';
  }

  @override
  String get pistaGiroscopio => 'Mova o celular ou arraste para olhar ao redor';

  @override
  String get pistaArrastre => 'Arraste ou use as setas para olhar ao redor';

  @override
  String get preparando360 => 'Preparando o percurso em 360°';

  @override
  String get panoramaNoCargo =>
      'Não conseguimos carregar esta imagem panorâmica.';

  @override
  String get avanzarSiguienteEscena => 'Avançar para a próxima cena';

  @override
  String get verInformacion => 'Ver informações';

  @override
  String irA(String destino) {
    return 'Ir para $destino';
  }

  @override
  String get desdeAquiPuedesIr => 'Daqui você pode ir para';

  @override
  String get movimientoTelefono => 'Mover a vista com o celular';

  @override
  String estasEn(String escena) {
    return 'Você está em $escena';
  }

  @override
  String vista360De(String escena) {
    return 'Vista 360° de $escena';
  }

  @override
  String get conocisteTodo => 'Você conheceu todo o percurso';

  @override
  String get cierreTexto =>
      'Você já viu os lugares que fazem o dia a dia da UTB. Quando quiser, volte a qualquer um deles.';

  @override
  String get seguirExplorando => 'Continuar explorando';

  @override
  String get idioma => 'Idioma';

  @override
  String get idiomaDelTelefono => 'Idioma do celular';

  @override
  String get accesibilidad => 'Acessibilidade';

  @override
  String get tamanoTexto => 'Tamanho do texto';

  @override
  String get tamanoNormal => 'Normal';

  @override
  String get tamanoGrande => 'Grande';

  @override
  String get tamanoMuyGrande => 'Muito grande';

  @override
  String get muestraTexto => 'Assim fica o texto com este tamanho.';

  @override
  String get altoContraste => 'Alto contraste';

  @override
  String get altoContrasteDetalle => 'Textos e bordas mais marcados.';

  @override
  String get reducirMovimiento => 'Reduzir movimento';

  @override
  String get reducirMovimientoDetalle =>
      'Remove animações, giros e efeitos 3D.';

  @override
  String get movimientoTelefonoDetalle =>
      'No percurso em 360°, a vista acompanha o movimento do celular.';

  @override
  String get subtitulosDetalle =>
      'Mostra o texto da narração enquanto ela toca.';

  @override
  String get ajustesSistema =>
      'Estes ajustes se somam aos de acessibilidade do seu celular.';
}

/// The translations for Portuguese, as used in Portugal (`pt_PT`).
class TextosPtPt extends TextosPt {
  TextosPtPt() : super('pt_PT');

  @override
  String get listo => 'Concluído';

  @override
  String get falloConexion =>
      'Não foi possível estabelecer ligação. Verifique a sua ligação à internet e tente novamente.';

  @override
  String get falloTiempo =>
      'O servidor demorou demasiado a responder. Tente novamente.';

  @override
  String get falloSesion =>
      'A sua sessão expirou. Volte a iniciar sessão para continuar.';

  @override
  String get falloInesperado =>
      'Algo correu mal. Tente novamente dentro de momentos.';

  @override
  String get falloPanoramasSoloConApi =>
      'As imagens panorâmicas só aparecem com a aplicação ligada à API.';

  @override
  String get enlaceInvalido => 'Essa ligação não é válida.';

  @override
  String get titularEmpieza => 'Comece o seu percurso';

  @override
  String titularAvance(int hechos, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Visitou $hechos de $total lugares',
      one: 'Visitou $hechos de 1 lugar',
    );
    return '$_temp0';
  }

  @override
  String detalleSiguiente(String nombre) {
    return 'Seguinte: $nombre';
  }

  @override
  String get paradas => 'Paragens';

  @override
  String conocisteLosLugares(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Conheceu os $total lugares',
      one: 'Conheceu o lugar',
    );
    return '$_temp0';
  }

  @override
  String get primeraParada => 'Primeira paragem';

  @override
  String get siguienteParada => 'Próxima paragem';

  @override
  String paradaNDeTotal(int numero, int total) {
    return 'Paragem $numero de $total';
  }

  @override
  String paradaSemantica(int numero, String nombre) {
    return 'Paragem $numero, $nombre';
  }

  @override
  String get sugerenciaTitulo => 'Encontre cada paragem no campus';

  @override
  String get sugerenciaTexto =>
      'O mapa mostra onde fica cada lugar e quais já visitou.';

  @override
  String get categoriaAcademico => 'Académico';

  @override
  String get categoriaDeporte => 'Desporto';

  @override
  String get mapaNoCargo => 'Não foi possível carregar o mapa do campus.';

  @override
  String get mapaDescripcion =>
      'Mapa ilustrado do campus. Cada paragem tem um marcador numerado.';

  @override
  String get fotos => 'Fotografias';

  @override
  String get deslizaParaMirar => 'Deslize para ver';

  @override
  String get fotoDelLugar => 'Fotografia do lugar';

  @override
  String get fotoNoCargo => 'Não foi possível carregar esta fotografia.';

  @override
  String get videoNoCargo => 'Não foi possível carregar o vídeo.';

  @override
  String get audioNoCargo => 'Não foi possível carregar o áudio.';

  @override
  String get escuchando => 'A ouvir';

  @override
  String get siguienteEscena => 'Cena seguinte';

  @override
  String get caminandoHacia => 'A caminho de';

  @override
  String get pistaGiroscopio =>
      'Mova o telemóvel ou arraste para olhar à volta';

  @override
  String get pistaArrastre => 'Arraste ou use as setas para olhar à volta';

  @override
  String get preparando360 => 'A preparar o percurso em 360°';

  @override
  String get panoramaNoCargo =>
      'Não foi possível carregar esta imagem panorâmica.';

  @override
  String get avanzarSiguienteEscena => 'Avançar para a cena seguinte';

  @override
  String get desdeAquiPuedesIr => 'Daqui pode ir para';

  @override
  String get movimientoTelefono => 'Mover a vista com o telemóvel';

  @override
  String estasEn(String escena) {
    return 'Está em $escena';
  }

  @override
  String get conocisteTodo => 'Conheceu todo o percurso';

  @override
  String get cierreTexto =>
      'Já viu os lugares que fazem o dia a dia da UTB. Quando quiser, volte a qualquer um deles.';

  @override
  String get idiomaDelTelefono => 'Idioma do telemóvel';

  @override
  String get movimientoTelefonoDetalle =>
      'No percurso em 360°, a vista acompanha o movimento do telemóvel.';

  @override
  String get subtitulosDetalle =>
      'Mostra o texto da narração enquanto é reproduzida.';

  @override
  String get ajustesSistema =>
      'Estas definições somam-se às de acessibilidade do seu telemóvel.';
}
