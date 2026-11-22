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
  String get categoriaCultura => 'Cultura';

  @override
  String get categoriaAdministrativo => 'Administrativo';

  @override
  String get categoriaSostenibilidad => 'Sustentabilidade';

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
      'Mapa do campus. Cada parada tem um marcador numerado e os demais lugares, um ponto.';

  @override
  String visitadosDeTotal(int hechos, int total) {
    return '$hechos de $total visitados';
  }

  @override
  String get sinUbicacionMapa => 'Sem localização no mapa';

  @override
  String get masLugares => 'Mais lugares do campus';

  @override
  String get creditoOsm => '© colaboradores do OpenStreetMap';

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
  String get orientarNorte => 'Orientar para o norte';

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

  @override
  String get privacidad => 'Privacidade';

  @override
  String get analiticaTitulo => 'Quer nos ajudar a melhorar o percurso?';

  @override
  String analiticaTexto(String ajustes) {
    return 'Se você aceitar, o app conta quais cenas, lugares e narrações são usados, sem seu nome, sua localização nem nada que identifique você. Você pode mudar isso quando quiser em “$ajustes”.';
  }

  @override
  String get analiticaAceptar => 'Sim, compartilhar';

  @override
  String get analiticaRechazar => 'Não, obrigado';

  @override
  String analiticaGuardada(String ajustes) {
    return 'Salvo. Você pode mudar isso em “$ajustes”.';
  }

  @override
  String get analiticaAjuste => 'Compartilhar estatísticas de uso';

  @override
  String get analiticaAjusteDetalle =>
      'Anônimas: quais cenas, lugares e narrações são usados. Nunca seu nome nem sua localização.';

  @override
  String get guiaTitulo => 'Oi, eu sou o Max';

  @override
  String get guiaTexto => 'Vou te acompanhar pelo campus da UTB.';

  @override
  String get guia360 => 'Entre em cada lugar em 360° e olhe ao redor.';

  @override
  String get guiaMapa => 'Encontre cada parada no mapa do campus.';

  @override
  String get guiaAudio => 'Ouça a história de cada lugar no seu idioma.';

  @override
  String get guiaEmpezar => 'Começar o percurso';

  @override
  String get guiaExplorar => 'Explorar por conta própria';

  @override
  String get verGuia => 'Ver as boas-vindas';

  @override
  String get verGuiaDetalle => 'O Max conta de novo como o percurso funciona.';

  @override
  String get ayuda => 'Ajuda';

  @override
  String get comoLlegar => 'Como chegar';

  @override
  String navTitulo(String lugar) {
    return 'Como chegar a $lugar';
  }

  @override
  String navPermisoTitulo(String lugar) {
    return 'Eu te guio até $lugar';
  }

  @override
  String get navPermisoTexto =>
      'Uso o GPS do celular enquanto o guia está aberto. Sua localização não sai do celular nem é salva.';

  @override
  String get navPermitir => 'Permitir localização';

  @override
  String get navSinPermiso =>
      'Sem permissão de localização não consigo te guiar. Você pode encontrar o lugar no mapa ou vê-lo em 360°.';

  @override
  String get navAbrirAjustes => 'Abrir configurações';

  @override
  String get navGpsApagado =>
      'A localização do celular está desligada. Ative e tente de novo.';

  @override
  String get navSimulada => 'Localização simulada';

  @override
  String get navBuscando => 'Procurando sinal de GPS…';

  @override
  String navSenalDebil(int metros) {
    return 'Sinal fraco (±$metros m). Procure um espaço aberto.';
  }

  @override
  String navRecto(int metros) {
    return 'Siga em frente por $metros m';
  }

  @override
  String navDerecha(int metros) {
    return 'Em $metros m, vire à direita';
  }

  @override
  String navIzquierda(int metros) {
    return 'Em $metros m, vire à esquerda';
  }

  @override
  String navLigeraDerecha(int metros) {
    return 'Em $metros m, siga pela direita';
  }

  @override
  String navLigeraIzquierda(int metros) {
    return 'Em $metros m, siga pela esquerda';
  }

  @override
  String get navVuelta => 'Dê meia-volta';

  @override
  String navLlegando(String lugar, int metros) {
    return '$lugar está a $metros m';
  }

  @override
  String navFaltan(int metros, int minutos) {
    return 'Faltam $metros m · cerca de $minutos min';
  }

  @override
  String get navRecalculando => 'Você saiu da rota. Calculando outra…';

  @override
  String get navSinEscaleras => 'Sem escadas';

  @override
  String get navPlano => 'Mapa';

  @override
  String get navCamara => 'Câmera';

  @override
  String get navTerminar => 'Encerrar';

  @override
  String navLlegaste(String lugar) {
    return 'Você chegou a $lugar';
  }

  @override
  String get navVerFicha => 'Ver os detalhes';

  @override
  String get navCamaraAviso => 'Olhe o caminho, não a tela.';

  @override
  String get navCamaraNoDisponible =>
      'Não foi possível abrir a câmera. Siga a rota no mapa.';

  @override
  String get navCalibrar =>
      'A bússola está imprecisa: mova o celular desenhando um oito.';

  @override
  String navSinRuta(String lugar) {
    return 'Não encontrei um caminho até $lugar.';
  }

  @override
  String get navAproximada => 'A entrada deste lugar ainda é aproximada.';

  @override
  String navPlanoSemantica(String lugar) {
    return 'Mapa com a rota até $lugar';
  }

  @override
  String get verMapa3d => 'Ver mapa em 3D';

  @override
  String get verMapa2d => 'Voltar ao mapa 2D';

  @override
  String get mapa3dDescripcion =>
      'Maquete 3D do campus. Toque em uma parada para ver os detalhes.';

  @override
  String get mapa3dNoDisponible =>
      'Não foi possível abrir o mapa 3D. Você pode usar o mapa 2D ou tentar novamente.';

  @override
  String get creditoModelo3d => 'Modelo 3D: ElMapita UTB';

  @override
  String get mapa3dCargando => 'Carregando o mapa 3D';
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
      'Mapa do campus. Cada paragem tem um marcador numerado e os restantes locais, um ponto.';

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

  @override
  String get analiticaTitulo => 'Quer ajudar-nos a melhorar o percurso?';

  @override
  String analiticaTexto(String ajustes) {
    return 'Se aceitar, a aplicação contabiliza que cenas, lugares e narrações são utilizados, sem o seu nome, a sua localização nem nada que o identifique. Pode alterar isto quando quiser em «$ajustes».';
  }

  @override
  String get analiticaAceptar => 'Sim, partilhar';

  @override
  String analiticaGuardada(String ajustes) {
    return 'Guardado. Pode alterar isto em «$ajustes».';
  }

  @override
  String get analiticaAjuste => 'Partilhar estatísticas de utilização';

  @override
  String get analiticaAjusteDetalle =>
      'Anónimas: que cenas, lugares e narrações são utilizados. Nunca o seu nome nem a sua localização.';

  @override
  String get guiaTitulo => 'Olá, sou o Max';

  @override
  String get guiaTexto => 'Acompanho-o pelo campus da UTB.';

  @override
  String get guiaMapa => 'Encontre cada paragem no mapa do campus.';

  @override
  String get guiaAudio => 'Ouça a história de cada lugar no seu idioma.';

  @override
  String get guiaExplorar => 'Explorar por conta própria';

  @override
  String get verGuiaDetalle =>
      'O Max volta a explicar como funciona o percurso.';

  @override
  String navPermisoTitulo(String lugar) {
    return 'Guio-o até $lugar';
  }

  @override
  String get navPermisoTexto =>
      'Uso o GPS do telemóvel enquanto o guia está aberto. A sua localização não sai do telemóvel nem é guardada.';

  @override
  String get navSinPermiso =>
      'Sem permissão de localização não o consigo guiar. Pode encontrar o lugar no mapa ou vê-lo em 360°.';

  @override
  String get navAbrirAjustes => 'Abrir definições';

  @override
  String get navGpsApagado =>
      'A localização do telemóvel está desligada. Ative-a e tente novamente.';

  @override
  String get navBuscando => 'À procura de sinal GPS…';

  @override
  String get navRecalculando => 'Saiu do percurso. A calcular outro…';

  @override
  String get navCamara => 'Câmara';

  @override
  String get navTerminar => 'Terminar';

  @override
  String navLlegaste(String lugar) {
    return 'Chegou a $lugar';
  }

  @override
  String get navCamaraAviso => 'Olhe para o caminho, não para o ecrã.';

  @override
  String get navCamaraNoDisponible =>
      'Não foi possível abrir a câmara. Siga o percurso no mapa.';

  @override
  String get navCalibrar =>
      'A bússola está imprecisa: mova o telemóvel desenhando um oito.';

  @override
  String navPlanoSemantica(String lugar) {
    return 'Mapa com o percurso até $lugar';
  }
}
