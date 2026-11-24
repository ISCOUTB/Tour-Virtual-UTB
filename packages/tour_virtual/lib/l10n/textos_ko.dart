// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'textos.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class TextosKo extends Textos {
  TextosKo([String locale = 'ko']) : super(locale);

  @override
  String get tituloApp => 'UTB 가상 투어';

  @override
  String get tourVirtual => '가상 투어';

  @override
  String get volver => '뒤로';

  @override
  String get reintentar => '다시 시도';

  @override
  String get listo => '완료';

  @override
  String get falloConexion => '연결할 수 없습니다. 인터넷 연결을 확인한 후 다시 시도하세요.';

  @override
  String get falloTiempo => '서버 응답이 너무 늦습니다. 다시 시도하세요.';

  @override
  String get falloSesion => '세션이 만료되었습니다. 계속하려면 다시 로그인하세요.';

  @override
  String get falloSinContenido => '아직 이곳에는 콘텐츠가 없습니다.';

  @override
  String get falloInesperado => '문제가 발생했습니다. 잠시 후 다시 시도하세요.';

  @override
  String get falloPanoramasSoloConApi => '파노라마는 앱이 API에 연결되어 있을 때만 볼 수 있습니다.';

  @override
  String get enlaceInvalido => '유효하지 않은 링크입니다.';

  @override
  String get rutaPorDefecto => '캠퍼스 투어';

  @override
  String cantidadLugares(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '장소 $total곳',
    );
    return '$_temp0';
  }

  @override
  String get titularSinLugares => '아직 장소가 없습니다';

  @override
  String get titularEmpieza => '투어를 시작해 보세요';

  @override
  String get recorridoCompleto => '투어 완료';

  @override
  String titularAvance(int hechos, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total곳 중 $hechos곳 방문',
    );
    return '$_temp0';
  }

  @override
  String get detalleEmpieza => '한 곳씩 캠퍼스를 둘러보세요.';

  @override
  String get detalleCompleto => '언제든지 원하는 장소로 다시 가 보세요.';

  @override
  String detalleSiguiente(String nombre) {
    return '다음: $nombre';
  }

  @override
  String lugaresVisitados(int hechos, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total곳 중 $hechos곳 방문함',
    );
    return '$_temp0';
  }

  @override
  String get modoRecorrido => '투어';

  @override
  String get modoMapa => '지도';

  @override
  String get idiomaYAccesibilidad => '언어 및 접근성';

  @override
  String get sinLugaresPublicados => '이 투어에는 아직 게시된 장소가 없습니다.';

  @override
  String get paradas => '방문지';

  @override
  String avanceLugares(int hechos, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total곳 중 $hechos곳',
    );
    return '$_temp0';
  }

  @override
  String conocisteLosLugares(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total곳을 모두 둘러봤습니다',
    );
    return '$_temp0';
  }

  @override
  String get vuelveACualquiera => '언제든지 다시 방문해 보세요.';

  @override
  String get volverAEmpezar => '처음부터 다시';

  @override
  String get primeraParada => '첫 번째 방문지';

  @override
  String get empezarRecorrido => '투어 시작';

  @override
  String get siguienteParada => '다음 방문지';

  @override
  String get continuarRecorrido => '투어 계속하기';

  @override
  String paradaNDeTotal(int numero, int total) {
    return '방문지 $numero/$total';
  }

  @override
  String get visitado => '방문함';

  @override
  String get lugarDelCampus => '캠퍼스 장소';

  @override
  String get campus => '캠퍼스';

  @override
  String yaVisitado(String nombre) {
    return '$nombre, 방문함';
  }

  @override
  String paradaSemantica(int numero, String nombre) {
    return '방문지 $numero, $nombre';
  }

  @override
  String get sugerencia => '추천';

  @override
  String get sugerenciaTitulo => '캠퍼스에서 각 방문지를 찾아보세요';

  @override
  String get sugerenciaTexto => '지도에서 각 장소의 위치와 이미 방문한 곳을 확인할 수 있습니다.';

  @override
  String get abrirMapa => '지도 열기';

  @override
  String get pieOficial => 'Universidad Tecnológica de Bolívar 공식 투어';

  @override
  String get datosDemostracion => '데모 데이터';

  @override
  String get categoriaRecursos => '학습 자원';

  @override
  String get categoriaAcademico => '학업';

  @override
  String get categoriaBienestar => '건강·복지';

  @override
  String get categoriaServicios => '편의 시설';

  @override
  String get categoriaDeporte => '스포츠';

  @override
  String get categoriaCultura => '문화';

  @override
  String get categoriaAdministrativo => '행정';

  @override
  String get categoriaSostenibilidad => '지속 가능성';

  @override
  String get verTodoCampus => '캠퍼스 전체 보기';

  @override
  String get acercar => '확대';

  @override
  String get alejar => '축소';

  @override
  String get mapaNoCargo => '캠퍼스 지도를 불러올 수 없습니다.';

  @override
  String get mapaDescripcion =>
      '캠퍼스 지도입니다. 각 방문지에 번호 표시가 있고, 다른 장소는 점으로 표시됩니다.';

  @override
  String visitadosDeTotal(int hechos, int total) {
    return '$total곳 중 $hechos곳 방문';
  }

  @override
  String get sinUbicacionMapa => '지도에 위치 없음';

  @override
  String get masLugares => '캠퍼스의 다른 장소';

  @override
  String get creditoOsm => '© OpenStreetMap 기여자';

  @override
  String get sinDescripcion => '아직 이 장소에 대한 설명이 없습니다.';

  @override
  String get verEn360 => '360°로 보기';

  @override
  String get sin360 => '이 장소는 아직 360° 투어가 없습니다.';

  @override
  String get audioNarrado => '오디오 해설';

  @override
  String get galeria => '갤러리';

  @override
  String get video => '동영상';

  @override
  String get lenguaDeSenas => '수어';

  @override
  String get contenidoEnPreparacion => '콘텐츠 준비 중';

  @override
  String todaviaNoHay(String lista) {
    return '아직 없음: $lista';
  }

  @override
  String get fotos => '사진';

  @override
  String textoEnIdioma(String idioma) {
    return '정보 제공 언어: $idioma';
  }

  @override
  String get deslizaParaMirar => '밀어서 둘러보기';

  @override
  String get fotoDelLugar => '장소 사진';

  @override
  String fotoNDeTotal(int numero, int total) {
    return '$numero/$total';
  }

  @override
  String get fotoNoCargo => '이 사진을 불러올 수 없습니다.';

  @override
  String get videoNoCargo => '동영상을 불러올 수 없습니다.';

  @override
  String get pausarVideo => '동영상 일시정지';

  @override
  String get reproducirVideo => '동영상 재생';

  @override
  String get audioSinSoporte => '이 플랫폼에서는 오디오를 재생할 수 없습니다.';

  @override
  String get audioNoCargo => '오디오를 불러올 수 없습니다.';

  @override
  String get pausarAudio => '오디오 해설 일시정지';

  @override
  String get escucharHistoria => '이야기 듣기';

  @override
  String get escuchando => '재생 중';

  @override
  String get transcripcionEnPreparacion => '대본 준비 중';

  @override
  String get leerTranscripcion => '대본 읽기';

  @override
  String get transcripcion => '대본';

  @override
  String get subtitulos => '자막';

  @override
  String narracionEn(String idioma) {
    return '해설 언어: $idioma';
  }

  @override
  String posicionDeTotal(String posicion, String total) {
    return '$total 중 $posicion';
  }

  @override
  String vistaPanoramicaDe(String nombre) {
    return '$nombre 파노라마';
  }

  @override
  String get esteLugar => '이 장소';

  @override
  String get deslizaParaGirar => '좌우로 밀어서 회전';

  @override
  String get girarIzquierda => '왼쪽으로 회전';

  @override
  String get girarDerecha => '오른쪽으로 회전';

  @override
  String get orientarNorte => '북쪽이 위로 오게 맞추기';

  @override
  String get sinEscenas => '이 투어에는 아직 게시된 장면이 없습니다.';

  @override
  String get siguienteEscena => '다음 장면';

  @override
  String get puntoDeInteres => '관심 장소';

  @override
  String get caminandoHacia => '이동 중';

  @override
  String escenaNDeTotal(int numero, int total) {
    return '장면 $numero/$total';
  }

  @override
  String get pistaGiroscopio => '휴대폰을 움직이거나 드래그해서 둘러보세요';

  @override
  String get pistaArrastre => '드래그하거나 화살표를 눌러 둘러보세요';

  @override
  String get preparando360 => '360° 투어 준비 중';

  @override
  String get panoramaNoCargo => '이 파노라마를 불러올 수 없습니다.';

  @override
  String get avanzarSiguienteEscena => '다음 장면으로 이동';

  @override
  String get verInformacion => '정보 보기';

  @override
  String irA(String destino) {
    return '이동: $destino';
  }

  @override
  String get desdeAquiPuedesIr => '여기서 갈 수 있는 곳';

  @override
  String get movimientoTelefono => '휴대폰 움직임으로 시점 이동';

  @override
  String estasEn(String escena) {
    return '현재 위치: $escena';
  }

  @override
  String vista360De(String escena) {
    return '$escena 360° 보기';
  }

  @override
  String get conocisteTodo => '투어를 모두 마쳤습니다';

  @override
  String get cierreTexto =>
      'UTB의 일상을 이루는 장소들을 모두 둘러보셨습니다. 언제든지 원하는 곳으로 다시 가 보세요.';

  @override
  String get seguirExplorando => '계속 둘러보기';

  @override
  String get idioma => '언어';

  @override
  String get idiomaDelTelefono => '휴대폰 언어';

  @override
  String get accesibilidad => '접근성';

  @override
  String get tamanoTexto => '글자 크기';

  @override
  String get tamanoNormal => '보통';

  @override
  String get tamanoGrande => '크게';

  @override
  String get tamanoMuyGrande => '아주 크게';

  @override
  String get muestraTexto => '이 크기에서는 글자가 이렇게 보입니다.';

  @override
  String get altoContraste => '고대비';

  @override
  String get altoContrasteDetalle => '글자와 테두리를 더 뚜렷하게 표시합니다.';

  @override
  String get reducirMovimiento => '동작 줄이기';

  @override
  String get reducirMovimientoDetalle => '애니메이션, 회전, 3D 효과를 끕니다.';

  @override
  String get movimientoTelefonoDetalle => '360° 투어에서 시점이 휴대폰 움직임을 따라갑니다.';

  @override
  String get subtitulosDetalle => '해설이 재생되는 동안 텍스트를 보여 줍니다.';

  @override
  String get ajustesSistema => '이 설정은 휴대폰의 접근성 설정에 더해 적용됩니다.';

  @override
  String get privacidad => '개인정보 보호';

  @override
  String get analiticaTitulo => '투어 개선에 도움을 주시겠어요?';

  @override
  String analiticaTexto(String ajustes) {
    return '동의하시면 앱이 어떤 장면, 장소, 해설이 이용되는지 집계합니다. 이름, 위치 등 본인을 식별할 수 있는 정보는 보내지 않습니다. 언제든지 ‘$ajustes’에서 변경할 수 있습니다.';
  }

  @override
  String get analiticaAceptar => '네, 공유할게요';

  @override
  String get analiticaRechazar => '괜찮습니다';

  @override
  String analiticaGuardada(String ajustes) {
    return '저장되었습니다. ‘$ajustes’에서 변경할 수 있습니다.';
  }

  @override
  String get analiticaAjuste => '이용 통계 공유';

  @override
  String get analiticaAjusteDetalle =>
      '익명: 어떤 장면, 장소, 해설이 이용되는지만 보냅니다. 이름이나 위치는 보내지 않습니다.';

  @override
  String get guiaTitulo => '안녕하세요, 저는 맥스예요';

  @override
  String get guiaTexto => 'UTB 캠퍼스를 함께 둘러볼게요.';

  @override
  String get guia360 => '각 장소에 360°로 들어가 주위를 둘러보세요.';

  @override
  String get guiaMapa => '캠퍼스 지도에서 각 정류장을 찾아보세요.';

  @override
  String get guiaAudio => '각 장소의 이야기를 내 언어로 들어 보세요.';

  @override
  String get guiaEmpezar => '투어 시작하기';

  @override
  String get guiaExplorar => '혼자 둘러보기';

  @override
  String get verGuia => '환영 화면 다시 보기';

  @override
  String get verGuiaDetalle => '맥스가 투어 이용 방법을 다시 알려 드려요.';

  @override
  String get ayuda => '도움말';

  @override
  String get comoLlegar => '길 안내';

  @override
  String navTitulo(String lugar) {
    return '$lugar까지 길 안내';
  }

  @override
  String navPermisoTitulo(String lugar) {
    return '$lugar까지 안내해 드릴게요';
  }

  @override
  String get navPermisoTexto =>
      '안내가 켜져 있는 동안 휴대폰 GPS를 사용합니다. 위치 정보는 휴대폰 밖으로 나가지 않으며 저장되지 않습니다.';

  @override
  String get navPermitir => '위치 허용';

  @override
  String get navSinPermiso =>
      '위치 권한이 없으면 안내할 수 없어요. 지도에서 장소를 찾거나 360°로 볼 수 있습니다.';

  @override
  String get navAbrirAjustes => '설정 열기';

  @override
  String get navGpsApagado => '휴대폰 위치가 꺼져 있어요. 켜고 다시 시도해 주세요.';

  @override
  String get navSimulada => '시뮬레이션 위치';

  @override
  String get navBuscando => 'GPS 신호를 찾는 중…';

  @override
  String navSenalDebil(int metros) {
    return '신호가 약해요(±$metros m). 탁 트인 곳으로 이동해 주세요.';
  }

  @override
  String navRecto(int metros) {
    return '$metros m 직진하세요';
  }

  @override
  String navDerecha(int metros) {
    return '$metros m 후 오른쪽으로 도세요';
  }

  @override
  String navIzquierda(int metros) {
    return '$metros m 후 왼쪽으로 도세요';
  }

  @override
  String navLigeraDerecha(int metros) {
    return '$metros m 후 오른쪽 방향으로 가세요';
  }

  @override
  String navLigeraIzquierda(int metros) {
    return '$metros m 후 왼쪽 방향으로 가세요';
  }

  @override
  String get navVuelta => '되돌아가세요';

  @override
  String navLlegando(String lugar, int metros) {
    return '$lugar까지 $metros m 남았어요';
  }

  @override
  String navFaltan(int metros, int minutos) {
    return '$metros m 남음 · 약 $minutos분';
  }

  @override
  String get navRecalculando => '경로를 벗어났어요. 새 경로를 찾는 중…';

  @override
  String get navSinEscaleras => '계단 없이';

  @override
  String get navPlano => '지도';

  @override
  String get navCamara => '카메라';

  @override
  String get navTerminar => '종료';

  @override
  String navLlegaste(String lugar) {
    return '$lugar에 도착했어요';
  }

  @override
  String get navVerFicha => '상세 정보 보기';

  @override
  String get navCamaraAviso => '화면 말고 길을 보세요.';

  @override
  String get navCamaraNoDisponible => '카메라를 열 수 없어요. 지도에서 경로를 따라가세요.';

  @override
  String get navCalibrar => '나침반이 부정확해요. 휴대폰을 8자 모양으로 움직여 주세요.';

  @override
  String navSinRuta(String lugar) {
    return '$lugar까지 가는 길을 찾지 못했어요.';
  }

  @override
  String get navFueraDelCampus =>
      '캠퍼스 밖에 있습니다. UTB에 도착하면 안내가 자동으로 시작됩니다. 그동안 GPS 없이 경로를 볼 수 있습니다.';

  @override
  String get navCaminandoHacia => '가는 곳';

  @override
  String get navLlegada => '도착';

  @override
  String get navIdeaRuta => '캠퍼스 길을 따라 안내하고, 방향을 바꾸기 전에 알려 줄게요.';

  @override
  String get navIdeaCamara => '휴대폰을 들면 카메라 화면 위 화살표가 길을 알려 줘요.';

  @override
  String get navSinEscalerasDetalle => '경로의 계단을 피해요.';

  @override
  String get navAproximada => '이 장소의 입구 위치는 아직 대략적이에요.';

  @override
  String navPlanoSemantica(String lugar) {
    return '$lugar까지의 경로가 표시된 지도';
  }

  @override
  String get verMapa3d => '3D 지도 보기';

  @override
  String get verMapa2d => '2D 지도로 돌아가기';

  @override
  String get mapa3dDescripcion => '캠퍼스 3D 모형입니다. 방문 지점을 누르면 상세 정보를 볼 수 있습니다.';

  @override
  String get mapa3dNoDisponible => '3D 지도를 열 수 없습니다. 2D 지도를 사용하거나 다시 시도하세요.';

  @override
  String get creditoModelo3d => '3D 모델: ElMapita UTB';

  @override
  String get mapa3dCargando => '3D 지도 불러오는 중';

  @override
  String get navSinSenal =>
      'GPS 신호가 없습니다. 탁 트인 곳으로 가세요. 신호가 잡히면 안내가 자동으로 이어집니다.';

  @override
  String get navVerRutaSinGps => 'GPS 없이 경로 보기';

  @override
  String get navEntradaPrincipal => '정문';

  @override
  String get navDesde => '출발';

  @override
  String navResumenRuta(int minutos, int metros) {
    return '$minutos분 · ${metros}m';
  }

  @override
  String get navConEscaleras => '계단 있음';

  @override
  String get navPasoAPaso => '단계별 안내';

  @override
  String get navPreviaNota => '이 경로는 현재 위치가 아니라 선택한 지점에서 출발합니다.';

  @override
  String get navGuiarmeConGps => 'GPS로 안내받기';

  @override
  String navEspacioPiso(String espacio, String piso) {
    return '$espacio은(는) 여기 있습니다: $piso.';
  }

  @override
  String navEspacioAqui(String espacio) {
    return '$espacio은(는) 이곳에 있습니다.';
  }

  @override
  String get buscarTitulo => '어디로 가세요?';

  @override
  String get buscarPista => '장소, 강의실 또는 사무실 검색';

  @override
  String buscarSinResultados(String consulta) {
    return '“$consulta”에 대한 결과가 없습니다. 강의실 번호나 건물 이름으로 검색해 보세요.';
  }

  @override
  String get buscarBorrar => '검색어 지우기';

  @override
  String get buscarCredito => '강의실 및 사무실: MAPSUTB';

  @override
  String get buscarComoLlegar => '길 안내';

  @override
  String buscarVerTodos(int cantidad) {
    return '결과 $cantidad개 모두 보기';
  }
}
