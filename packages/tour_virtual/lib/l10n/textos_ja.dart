// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'textos.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class TextosJa extends Textos {
  TextosJa([String locale = 'ja']) : super(locale);

  @override
  String get tituloApp => 'UTB バーチャルツアー';

  @override
  String get tourVirtual => 'バーチャルツアー';

  @override
  String get volver => '戻る';

  @override
  String get reintentar => '再試行';

  @override
  String get listo => '完了';

  @override
  String get falloConexion => '接続できませんでした。インターネット接続を確認して、もう一度お試しください。';

  @override
  String get falloTiempo => 'サーバーの応答に時間がかかりすぎています。もう一度お試しください。';

  @override
  String get falloSesion => 'セッションの有効期限が切れました。続けるには、もう一度ログインしてください。';

  @override
  String get falloSinContenido => 'ここにはまだコンテンツがありません。';

  @override
  String get falloInesperado => '問題が発生しました。しばらくしてからもう一度お試しください。';

  @override
  String get falloPanoramasSoloConApi => 'パノラマは、アプリが API に接続されているときだけ表示されます。';

  @override
  String get enlaceInvalido => 'このリンクは無効です。';

  @override
  String get rutaPorDefecto => 'キャンパスツアー';

  @override
  String cantidadLugares(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total か所',
    );
    return '$_temp0';
  }

  @override
  String get titularSinLugares => 'まだ場所がありません';

  @override
  String get titularEmpieza => 'ツアーを始めましょう';

  @override
  String get recorridoCompleto => 'ツアー完了';

  @override
  String titularAvance(int hechos, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total か所中 $hechos か所を訪問',
    );
    return '$_temp0';
  }

  @override
  String get detalleEmpieza => 'キャンパスを一か所ずつ巡りましょう。';

  @override
  String get detalleCompleto => 'いつでも好きな場所に戻れます。';

  @override
  String detalleSiguiente(String nombre) {
    return '次：$nombre';
  }

  @override
  String lugaresVisitados(int hechos, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total か所中 $hechos か所を訪問済み',
    );
    return '$_temp0';
  }

  @override
  String get modoRecorrido => 'ツアー';

  @override
  String get modoMapa => '地図';

  @override
  String get idiomaYAccesibilidad => '言語とアクセシビリティ';

  @override
  String get sinLugaresPublicados => 'このツアーにはまだ公開された場所がありません。';

  @override
  String get paradas => '立ち寄り先';

  @override
  String avanceLugares(int hechos, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total か所中 $hechos か所',
    );
    return '$_temp0';
  }

  @override
  String conocisteLosLugares(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total か所すべてを巡りました',
    );
    return '$_temp0';
  }

  @override
  String get vuelveACualquiera => 'いつでも好きな場所に戻れます。';

  @override
  String get volverAEmpezar => '最初からやり直す';

  @override
  String get primeraParada => '最初の立ち寄り先';

  @override
  String get empezarRecorrido => 'ツアーを始める';

  @override
  String get siguienteParada => '次の立ち寄り先';

  @override
  String get continuarRecorrido => 'ツアーを続ける';

  @override
  String paradaNDeTotal(int numero, int total) {
    return '立ち寄り先 $numero/$total';
  }

  @override
  String get visitado => '訪問済み';

  @override
  String get lugarDelCampus => 'キャンパス内の場所';

  @override
  String get campus => 'キャンパス';

  @override
  String yaVisitado(String nombre) {
    return '$nombre、訪問済み';
  }

  @override
  String paradaSemantica(int numero, String nombre) {
    return '立ち寄り先 $numero、$nombre';
  }

  @override
  String get sugerencia => 'ヒント';

  @override
  String get sugerenciaTitulo => 'キャンパスで各立ち寄り先を探しましょう';

  @override
  String get sugerenciaTexto => '地図では、各場所の位置と訪問済みの場所を確認できます。';

  @override
  String get abrirMapa => '地図を開く';

  @override
  String get pieOficial => 'Universidad Tecnológica de Bolívar 公式ツアー';

  @override
  String get datosDemostracion => 'デモデータ';

  @override
  String get categoriaRecursos => '学習リソース';

  @override
  String get categoriaAcademico => '学業';

  @override
  String get categoriaBienestar => '健康・福祉';

  @override
  String get categoriaServicios => 'サービス';

  @override
  String get categoriaDeporte => 'スポーツ';

  @override
  String get categoriaCultura => '文化';

  @override
  String get categoriaAdministrativo => '事務';

  @override
  String get categoriaSostenibilidad => 'サステナビリティ';

  @override
  String get verTodoCampus => 'キャンパス全体を表示';

  @override
  String get acercar => '拡大';

  @override
  String get alejar => '縮小';

  @override
  String get mapaNoCargo => 'キャンパスの地図を読み込めませんでした。';

  @override
  String get mapaDescripcion =>
      'キャンパスの地図です。各立ち寄り先に番号付きのマーカーがあり、その他の場所は点で示されます。';

  @override
  String visitadosDeTotal(int hechos, int total) {
    return '$total か所中 $hechos か所訪問済み';
  }

  @override
  String get sinUbicacionMapa => '地図上の位置なし';

  @override
  String get masLugares => 'キャンパスのその他の場所';

  @override
  String get creditoOsm => '© OpenStreetMap 貢献者';

  @override
  String get sinDescripcion => 'この場所の説明はまだありません。';

  @override
  String get verEn360 => '360° で見る';

  @override
  String get sin360 => 'この場所にはまだ 360° ツアーがありません。';

  @override
  String get audioNarrado => '音声ガイド';

  @override
  String get galeria => 'ギャラリー';

  @override
  String get video => '動画';

  @override
  String get lenguaDeSenas => '手話';

  @override
  String get contenidoEnPreparacion => 'コンテンツ準備中';

  @override
  String todaviaNoHay(String lista) {
    return 'まだありません：$lista';
  }

  @override
  String get fotos => '写真';

  @override
  String textoEnIdioma(String idioma) {
    return '情報の言語：$idioma';
  }

  @override
  String get deslizaParaMirar => 'スワイプして見る';

  @override
  String get fotoDelLugar => '場所の写真';

  @override
  String fotoNDeTotal(int numero, int total) {
    return '$numero/$total';
  }

  @override
  String get fotoNoCargo => 'この写真を読み込めませんでした。';

  @override
  String get videoNoCargo => '動画を読み込めませんでした。';

  @override
  String get pausarVideo => '動画を一時停止';

  @override
  String get reproducirVideo => '動画を再生';

  @override
  String get audioSinSoporte => 'このプラットフォームでは音声を再生できません。';

  @override
  String get audioNoCargo => '音声を読み込めませんでした。';

  @override
  String get pausarAudio => '音声ガイドを一時停止';

  @override
  String get escucharHistoria => '話を聞く';

  @override
  String get escuchando => '再生中';

  @override
  String get transcripcionEnPreparacion => '文字起こし準備中';

  @override
  String get leerTranscripcion => '文字起こしを読む';

  @override
  String get transcripcion => '文字起こし';

  @override
  String get subtitulos => '字幕';

  @override
  String narracionEn(String idioma) {
    return 'ナレーションの言語：$idioma';
  }

  @override
  String posicionDeTotal(String posicion, String total) {
    return '$total 中 $posicion';
  }

  @override
  String vistaPanoramicaDe(String nombre) {
    return '$nombreのパノラマ';
  }

  @override
  String get esteLugar => 'この場所';

  @override
  String get deslizaParaGirar => '左右にスワイプして回転';

  @override
  String get girarIzquierda => '左に回転';

  @override
  String get girarDerecha => '右に回転';

  @override
  String get orientarNorte => '北を上にする';

  @override
  String get sinEscenas => 'このツアーにはまだ公開されたシーンがありません。';

  @override
  String get siguienteEscena => '次のシーン';

  @override
  String get puntoDeInteres => '見どころ';

  @override
  String get caminandoHacia => '移動中';

  @override
  String escenaNDeTotal(int numero, int total) {
    return 'シーン $numero/$total';
  }

  @override
  String get pistaGiroscopio => 'スマホを動かすか、ドラッグして周りを見ましょう';

  @override
  String get pistaArrastre => 'ドラッグするか矢印で周りを見ましょう';

  @override
  String get preparando360 => '360° ツアーを準備中';

  @override
  String get panoramaNoCargo => 'このパノラマを読み込めませんでした。';

  @override
  String get avanzarSiguienteEscena => '次のシーンへ進む';

  @override
  String get verInformacion => '情報を見る';

  @override
  String irA(String destino) {
    return '$destinoへ行く';
  }

  @override
  String get desdeAquiPuedesIr => 'ここから行ける場所';

  @override
  String get movimientoTelefono => 'スマホの動きで視点を動かす';

  @override
  String estasEn(String escena) {
    return '現在地：$escena';
  }

  @override
  String vista360De(String escena) {
    return '$escenaの 360° ビュー';
  }

  @override
  String get conocisteTodo => 'ツアーをすべて巡りました';

  @override
  String get cierreTexto => 'UTB の日常をつくる場所をすべて見ました。いつでも好きな場所に戻ってきてください。';

  @override
  String get seguirExplorando => '引き続き探索する';

  @override
  String get idioma => '言語';

  @override
  String get idiomaDelTelefono => 'スマホの言語';

  @override
  String get accesibilidad => 'アクセシビリティ';

  @override
  String get tamanoTexto => '文字サイズ';

  @override
  String get tamanoNormal => '標準';

  @override
  String get tamanoGrande => '大';

  @override
  String get tamanoMuyGrande => '特大';

  @override
  String get muestraTexto => 'このサイズでは文字がこのように表示されます。';

  @override
  String get altoContraste => 'ハイコントラスト';

  @override
  String get altoContrasteDetalle => '文字と枠線をよりはっきり表示します。';

  @override
  String get reducirMovimiento => '動きを減らす';

  @override
  String get reducirMovimientoDetalle => 'アニメーション、回転、3D 効果をオフにします。';

  @override
  String get movimientoTelefonoDetalle => '360° ツアーで、視点がスマホの動きに合わせて動きます。';

  @override
  String get subtitulosDetalle => 'ナレーションの再生中にテキストを表示します。';

  @override
  String get ajustesSistema => 'これらの設定は、スマホのアクセシビリティ設定に加えて適用されます。';

  @override
  String get privacidad => 'プライバシー';

  @override
  String get analiticaTitulo => 'ツアーの改善にご協力いただけますか？';

  @override
  String analiticaTexto(String ajustes) {
    return '同意すると、どのシーン・場所・ナレーションが使われたかをアプリが集計します。名前や位置情報など、あなたを特定できる情報は送信しません。「$ajustes」でいつでも変更できます。';
  }

  @override
  String get analiticaAceptar => 'はい、共有します';

  @override
  String get analiticaRechazar => 'いいえ、結構です';

  @override
  String analiticaGuardada(String ajustes) {
    return '保存しました。「$ajustes」で変更できます。';
  }

  @override
  String get analiticaAjuste => '利用統計を共有';

  @override
  String get analiticaAjusteDetalle =>
      '匿名：どのシーン・場所・ナレーションが使われたかのみ。名前や位置情報は送信しません。';

  @override
  String get guiaTitulo => 'こんにちは、マックスです';

  @override
  String get guiaTexto => 'UTB のキャンパスをご案内します。';

  @override
  String get guia360 => '各スポットに 360° で入り、まわりを見渡しましょう。';

  @override
  String get guiaMapa => 'キャンパスマップで各スポットを確認しましょう。';

  @override
  String get guiaAudio => '各スポットの物語をあなたの言語で聞けます。';

  @override
  String get guiaEmpezar => 'ツアーを始める';

  @override
  String get guiaExplorar => '自分で見て回る';

  @override
  String get verGuia => 'ようこそ画面をもう一度見る';

  @override
  String get verGuiaDetalle => 'マックスがツアーの使い方をもう一度説明します。';

  @override
  String get ayuda => 'ヘルプ';

  @override
  String get comoLlegar => '行き方';

  @override
  String navTitulo(String lugar) {
    return '$lugarへの行き方';
  }

  @override
  String navPermisoTitulo(String lugar) {
    return '$lugarまでご案内します';
  }

  @override
  String get navPermisoTexto =>
      '案内中だけスマートフォンの GPS を使います。位置情報はスマートフォンの外に送られず、保存もされません。';

  @override
  String get navPermitir => '位置情報を許可';

  @override
  String get navSinPermiso => '位置情報の許可がないと案内できません。地図で場所を確認するか、360° で見ることができます。';

  @override
  String get navAbrirAjustes => '設定を開く';

  @override
  String get navGpsApagado => 'スマートフォンの位置情報がオフです。オンにしてもう一度お試しください。';

  @override
  String get navSimulada => 'シミュレーションの位置';

  @override
  String get navBuscando => 'GPS 信号を探しています…';

  @override
  String navSenalDebil(int metros) {
    return '信号が弱いです（±$metros m）。開けた場所に移動してください。';
  }

  @override
  String navRecto(int metros) {
    return '$metros m 直進してください';
  }

  @override
  String navDerecha(int metros) {
    return '$metros m 先で右に曲がってください';
  }

  @override
  String navIzquierda(int metros) {
    return '$metros m 先で左に曲がってください';
  }

  @override
  String navLigeraDerecha(int metros) {
    return '$metros m 先で右寄りに進んでください';
  }

  @override
  String navLigeraIzquierda(int metros) {
    return '$metros m 先で左寄りに進んでください';
  }

  @override
  String get navVuelta => '引き返してください';

  @override
  String navLlegando(String lugar, int metros) {
    return '$lugarまであと $metros m です';
  }

  @override
  String navFaltan(int metros, int minutos) {
    return '残り $metros m・約 $minutos 分';
  }

  @override
  String get navRecalculando => 'ルートから外れました。別のルートを探しています…';

  @override
  String get navSinEscaleras => '階段を避ける';

  @override
  String get navPlano => '地図';

  @override
  String get navCamara => 'カメラ';

  @override
  String get navTerminar => '終了';

  @override
  String navLlegaste(String lugar) {
    return '$lugarに到着しました';
  }

  @override
  String get navVerFicha => '詳細を見る';

  @override
  String get navCamaraAviso => '画面ではなく足元を見てください。';

  @override
  String get navCamaraNoDisponible => 'カメラを開けませんでした。地図でルートをたどってください。';

  @override
  String get navCalibrar => 'コンパスが不正確です。スマートフォンを 8 の字に動かしてください。';

  @override
  String navSinRuta(String lugar) {
    return '$lugarまでの道が見つかりませんでした。';
  }

  @override
  String get navFueraDelCampus => 'キャンパスの外にいます。案内はUTBの中で使えます。着いたら開いてください。';

  @override
  String get navCaminandoHacia => '目的地';

  @override
  String get navLlegada => '到着';

  @override
  String get navIdeaRuta => 'キャンパスの道を案内し、曲がる前にお知らせします。';

  @override
  String get navIdeaCamara => 'スマートフォンを持ち上げると、カメラ画面の矢印が進む方向を示します。';

  @override
  String get navSinEscalerasDetalle => 'ルート上の段差を避けます。';

  @override
  String get navAproximada => 'この場所の入口はまだおおよその位置です。';

  @override
  String navPlanoSemantica(String lugar) {
    return '$lugarまでのルートを示した地図';
  }

  @override
  String get verMapa3d => '3Dマップを表示';

  @override
  String get verMapa2d => '2Dマップに戻る';

  @override
  String get mapa3dDescripcion => 'キャンパスの3D模型です。立ち寄り地点をタップすると詳細を表示します。';

  @override
  String get mapa3dNoDisponible => '3Dマップを開けませんでした。2Dマップを使用するか、もう一度お試しください。';

  @override
  String get creditoModelo3d => '3Dモデル：ElMapita UTB';

  @override
  String get mapa3dCargando => '3Dマップを読み込み中';
}
