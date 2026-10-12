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
  String get verTodoCampus => '캠퍼스 전체 보기';

  @override
  String get acercar => '확대';

  @override
  String get alejar => '축소';

  @override
  String get mapaNoCargo => '캠퍼스 지도를 불러올 수 없습니다.';

  @override
  String get mapaDescripcion => '캠퍼스 일러스트 지도입니다. 각 방문지에 번호 표시가 있습니다.';

  @override
  String visitadosDeTotal(int hechos, int total) {
    return '$total곳 중 $hechos곳 방문';
  }

  @override
  String get sinUbicacionMapa => '지도에 위치 없음';

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
  String get escucharEn => '듣기 언어';

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
}
