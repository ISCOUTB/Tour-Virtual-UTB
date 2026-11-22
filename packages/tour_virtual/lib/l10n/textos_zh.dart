// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'textos.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class TextosZh extends Textos {
  TextosZh([String locale = 'zh']) : super(locale);

  @override
  String get tituloApp => 'UTB 虚拟导览';

  @override
  String get tourVirtual => '虚拟导览';

  @override
  String get volver => '返回';

  @override
  String get reintentar => '重试';

  @override
  String get listo => '完成';

  @override
  String get falloConexion => '无法连接。请检查网络连接后重试。';

  @override
  String get falloTiempo => '服务器响应时间过长。请重试。';

  @override
  String get falloSesion => '会话已过期。请重新登录以继续。';

  @override
  String get falloSinContenido => '这里暂时还没有内容。';

  @override
  String get falloInesperado => '出了点问题。请稍后重试。';

  @override
  String get falloPanoramasSoloConApi => '只有在应用连接到 API 时才能查看全景图。';

  @override
  String get enlaceInvalido => '此链接无效。';

  @override
  String get rutaPorDefecto => '校园导览';

  @override
  String cantidadLugares(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total 个地点',
    );
    return '$_temp0';
  }

  @override
  String get titularSinLugares => '暂无地点';

  @override
  String get titularEmpieza => '开始你的导览';

  @override
  String get recorridoCompleto => '导览完成';

  @override
  String titularAvance(int hechos, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '已参观 $hechos/$total 个地点',
    );
    return '$_temp0';
  }

  @override
  String get detalleEmpieza => '一次一个地点，慢慢了解校园。';

  @override
  String get detalleCompleto => '随时可以回到任何地点。';

  @override
  String detalleSiguiente(String nombre) {
    return '下一站：$nombre';
  }

  @override
  String lugaresVisitados(int hechos, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '已参观 $total 个地点中的 $hechos 个',
    );
    return '$_temp0';
  }

  @override
  String get modoRecorrido => '导览';

  @override
  String get modoMapa => '地图';

  @override
  String get idiomaYAccesibilidad => '语言和无障碍';

  @override
  String get sinLugaresPublicados => '此导览尚未发布任何地点。';

  @override
  String get paradas => '站点';

  @override
  String avanceLugares(int hechos, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$hechos/$total 个地点',
    );
    return '$_temp0';
  }

  @override
  String conocisteLosLugares(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '你已参观全部 $total 个地点',
    );
    return '$_temp0';
  }

  @override
  String get vuelveACualquiera => '随时可以再回来看看。';

  @override
  String get volverAEmpezar => '重新开始';

  @override
  String get primeraParada => '第一站';

  @override
  String get empezarRecorrido => '开始导览';

  @override
  String get siguienteParada => '下一站';

  @override
  String get continuarRecorrido => '继续导览';

  @override
  String paradaNDeTotal(int numero, int total) {
    return '第 $numero 站，共 $total 站';
  }

  @override
  String get visitado => '已参观';

  @override
  String get lugarDelCampus => '校园地点';

  @override
  String get campus => '校园';

  @override
  String yaVisitado(String nombre) {
    return '$nombre，已参观';
  }

  @override
  String paradaSemantica(int numero, String nombre) {
    return '第 $numero 站，$nombre';
  }

  @override
  String get sugerencia => '提示';

  @override
  String get sugerenciaTitulo => '在校园中找到每个站点';

  @override
  String get sugerenciaTexto => '地图会显示每个地点的位置，以及你已参观过哪些地点。';

  @override
  String get abrirMapa => '打开地图';

  @override
  String get pieOficial => 'Universidad Tecnológica de Bolívar 官方导览';

  @override
  String get datosDemostracion => '演示数据';

  @override
  String get categoriaRecursos => '学习资源';

  @override
  String get categoriaAcademico => '学术';

  @override
  String get categoriaBienestar => '健康与福利';

  @override
  String get categoriaServicios => '生活服务';

  @override
  String get categoriaDeporte => '体育';

  @override
  String get categoriaCultura => '文化';

  @override
  String get categoriaAdministrativo => '行政';

  @override
  String get categoriaSostenibilidad => '可持续发展';

  @override
  String get verTodoCampus => '查看整个校园';

  @override
  String get acercar => '放大';

  @override
  String get alejar => '缩小';

  @override
  String get mapaNoCargo => '无法加载校园地图。';

  @override
  String get mapaDescripcion => '校园地图。每个站点都有带编号的标记，其他地点显示为圆点。';

  @override
  String visitadosDeTotal(int hechos, int total) {
    return '已参观 $hechos/$total';
  }

  @override
  String get sinUbicacionMapa => '地图上无位置';

  @override
  String get masLugares => '校园其他地点';

  @override
  String get creditoOsm => '© OpenStreetMap 贡献者';

  @override
  String get sinDescripcion => '此地点暂无介绍。';

  @override
  String get verEn360 => '360° 查看';

  @override
  String get sin360 => '此地点暂无 360° 导览。';

  @override
  String get audioNarrado => '语音讲解';

  @override
  String get galeria => '图库';

  @override
  String get video => '视频';

  @override
  String get lenguaDeSenas => '手语';

  @override
  String get contenidoEnPreparacion => '内容准备中';

  @override
  String todaviaNoHay(String lista) {
    return '暂无：$lista';
  }

  @override
  String get fotos => '照片';

  @override
  String textoEnIdioma(String idioma) {
    return '信息语言：$idioma';
  }

  @override
  String get deslizaParaMirar => '滑动查看';

  @override
  String get fotoDelLugar => '地点照片';

  @override
  String fotoNDeTotal(int numero, int total) {
    return '$numero/$total';
  }

  @override
  String get fotoNoCargo => '无法加载此照片。';

  @override
  String get videoNoCargo => '无法加载视频。';

  @override
  String get pausarVideo => '暂停视频';

  @override
  String get reproducirVideo => '播放视频';

  @override
  String get audioSinSoporte => '此平台无法播放音频。';

  @override
  String get audioNoCargo => '无法加载音频。';

  @override
  String get pausarAudio => '暂停语音讲解';

  @override
  String get escucharHistoria => '收听介绍';

  @override
  String get escuchando => '正在播放';

  @override
  String get transcripcionEnPreparacion => '文字稿准备中';

  @override
  String get leerTranscripcion => '阅读文字稿';

  @override
  String get transcripcion => '文字稿';

  @override
  String get subtitulos => '字幕';

  @override
  String narracionEn(String idioma) {
    return '讲解语言：$idioma';
  }

  @override
  String posicionDeTotal(String posicion, String total) {
    return '$posicion / $total';
  }

  @override
  String vistaPanoramicaDe(String nombre) {
    return '$nombre全景';
  }

  @override
  String get esteLugar => '此地点';

  @override
  String get deslizaParaGirar => '左右滑动以旋转';

  @override
  String get girarIzquierda => '向左转';

  @override
  String get girarDerecha => '向右转';

  @override
  String get orientarNorte => '朝向北方';

  @override
  String get sinEscenas => '此导览尚未发布任何场景。';

  @override
  String get siguienteEscena => '下一个场景';

  @override
  String get puntoDeInteres => '兴趣点';

  @override
  String get caminandoHacia => '正在前往';

  @override
  String escenaNDeTotal(int numero, int total) {
    return '场景 $numero/$total';
  }

  @override
  String get pistaGiroscopio => '移动手机或拖动以环顾四周';

  @override
  String get pistaArrastre => '拖动或使用箭头环顾四周';

  @override
  String get preparando360 => '正在准备 360° 导览';

  @override
  String get panoramaNoCargo => '无法加载此全景图。';

  @override
  String get avanzarSiguienteEscena => '前往下一个场景';

  @override
  String get verInformacion => '查看信息';

  @override
  String irA(String destino) {
    return '前往$destino';
  }

  @override
  String get desdeAquiPuedesIr => '从这里可以前往';

  @override
  String get movimientoTelefono => '移动手机来转动视角';

  @override
  String estasEn(String escena) {
    return '你在：$escena';
  }

  @override
  String vista360De(String escena) {
    return '$escena 360° 视图';
  }

  @override
  String get conocisteTodo => '你已完成全部导览';

  @override
  String get cierreTexto => '你已看过构成 UTB 日常生活的地点。随时可以回到其中任何一个。';

  @override
  String get seguirExplorando => '继续探索';

  @override
  String get idioma => '语言';

  @override
  String get idiomaDelTelefono => '手机语言';

  @override
  String get accesibilidad => '无障碍';

  @override
  String get tamanoTexto => '文字大小';

  @override
  String get tamanoNormal => '标准';

  @override
  String get tamanoGrande => '大';

  @override
  String get tamanoMuyGrande => '特大';

  @override
  String get muestraTexto => '文字在此大小下的显示效果。';

  @override
  String get altoContraste => '高对比度';

  @override
  String get altoContrasteDetalle => '文字和边框更清晰。';

  @override
  String get reducirMovimiento => '减弱动态效果';

  @override
  String get reducirMovimientoDetalle => '关闭动画、旋转和 3D 效果。';

  @override
  String get movimientoTelefonoDetalle => '在 360° 导览中，视角会跟随手机移动。';

  @override
  String get subtitulosDetalle => '播放讲解时显示文字。';

  @override
  String get ajustesSistema => '这些设置会叠加在手机的无障碍设置之上。';

  @override
  String get privacidad => '隐私';

  @override
  String get analiticaTitulo => '愿意帮助我们改进导览吗？';

  @override
  String analiticaTexto(String ajustes) {
    return '如果你同意，应用会统计哪些场景、地点和讲解被使用，不会发送你的姓名、位置或任何能识别你身份的信息。你可以随时在“$ajustes”中更改。';
  }

  @override
  String get analiticaAceptar => '好，分享';

  @override
  String get analiticaRechazar => '不用了，谢谢';

  @override
  String analiticaGuardada(String ajustes) {
    return '已保存。你可以在“$ajustes”中更改。';
  }

  @override
  String get analiticaAjuste => '分享使用统计';

  @override
  String get analiticaAjusteDetalle => '匿名：仅统计哪些场景、地点和讲解被使用，绝不包含你的姓名或位置。';

  @override
  String get guiaTitulo => '你好，我是麦克斯';

  @override
  String get guiaTexto => '我带你参观 UTB 校园。';

  @override
  String get guia360 => '以 360° 进入每个地点，环顾四周。';

  @override
  String get guiaMapa => '在校园地图上找到每个站点。';

  @override
  String get guiaAudio => '用你的语言收听每个地点的故事。';

  @override
  String get guiaEmpezar => '开始导览';

  @override
  String get guiaExplorar => '自己随便看看';

  @override
  String get verGuia => '再看一次欢迎页';

  @override
  String get verGuiaDetalle => '麦克斯再给你讲一遍导览怎么用。';

  @override
  String get ayuda => '帮助';

  @override
  String get comoLlegar => '怎么去';

  @override
  String navTitulo(String lugar) {
    return '前往$lugar';
  }

  @override
  String navPermisoTitulo(String lugar) {
    return '我带你去$lugar';
  }

  @override
  String get navPermisoTexto => '导航开启时我会使用手机的 GPS。你的位置不会离开手机，也不会被保存。';

  @override
  String get navPermitir => '允许使用位置';

  @override
  String get navSinPermiso => '没有位置权限我就无法为你导航。你可以在地图上找到这个地点，或以 360° 查看。';

  @override
  String get navAbrirAjustes => '打开设置';

  @override
  String get navGpsApagado => '手机定位已关闭。请打开后重试。';

  @override
  String get navSimulada => '模拟位置';

  @override
  String get navBuscando => '正在搜索 GPS 信号…';

  @override
  String navSenalDebil(int metros) {
    return '信号较弱（±$metros 米）。请到开阔处。';
  }

  @override
  String navRecto(int metros) {
    return '直行 $metros 米';
  }

  @override
  String navDerecha(int metros) {
    return '$metros 米后右转';
  }

  @override
  String navIzquierda(int metros) {
    return '$metros 米后左转';
  }

  @override
  String navLigeraDerecha(int metros) {
    return '$metros 米后靠右走';
  }

  @override
  String navLigeraIzquierda(int metros) {
    return '$metros 米后靠左走';
  }

  @override
  String get navVuelta => '请掉头';

  @override
  String navLlegando(String lugar, int metros) {
    return '距离$lugar还有 $metros 米';
  }

  @override
  String navFaltan(int metros, int minutos) {
    return '还剩 $metros 米 · 约 $minutos 分钟';
  }

  @override
  String get navRecalculando => '你偏离了路线，正在重新规划…';

  @override
  String get navSinEscaleras => '避开楼梯';

  @override
  String get navPlano => '地图';

  @override
  String get navCamara => '相机';

  @override
  String get navTerminar => '结束';

  @override
  String navLlegaste(String lugar) {
    return '你已到达$lugar';
  }

  @override
  String get navVerFicha => '查看详情';

  @override
  String get navCamaraAviso => '请看路，不要看屏幕。';

  @override
  String get navCamaraNoDisponible => '无法打开相机。请在地图上跟随路线。';

  @override
  String get navCalibrar => '指南针不准：请将手机按 8 字形移动。';

  @override
  String navSinRuta(String lugar) {
    return '没有找到前往$lugar的路线。';
  }

  @override
  String get navFueraDelCampus => '你在校园外。导航只在UTB校内可用：到达后再打开。';

  @override
  String get navAproximada => '此地点的入口位置仍是大概位置。';

  @override
  String navPlanoSemantica(String lugar) {
    return '显示前往$lugar路线的地图';
  }

  @override
  String get verMapa3d => '查看3D地图';

  @override
  String get verMapa2d => '返回2D地图';

  @override
  String get mapa3dDescripcion => '校园3D模型。点按站点可查看详情。';

  @override
  String get mapa3dNoDisponible => '无法打开3D地图。您可以使用2D地图或重试。';

  @override
  String get creditoModelo3d => '3D模型：ElMapita UTB';

  @override
  String get mapa3dCargando => '正在加载3D地图';
}
