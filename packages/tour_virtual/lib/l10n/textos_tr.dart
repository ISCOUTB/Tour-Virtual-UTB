// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'textos.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class TextosTr extends Textos {
  TextosTr([String locale = 'tr']) : super(locale);

  @override
  String get tituloApp => 'UTB Sanal Tur';

  @override
  String get tourVirtual => 'Sanal tur';

  @override
  String get volver => 'Geri';

  @override
  String get reintentar => 'Tekrar dene';

  @override
  String get listo => 'Tamam';

  @override
  String get falloConexion =>
      'Bağlantı kurulamadı. İnternet bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get falloTiempo => 'Sunucu çok geç yanıt verdi. Tekrar deneyin.';

  @override
  String get falloSesion =>
      'Oturumunuzun süresi doldu. Devam etmek için tekrar giriş yapın.';

  @override
  String get falloSinContenido => 'Burada henüz içerik yok.';

  @override
  String get falloInesperado => 'Bir sorun oluştu. Biraz sonra tekrar deneyin.';

  @override
  String get falloPanoramasSoloConApi =>
      'Panoramalar yalnızca uygulama API’ye bağlıyken görünür.';

  @override
  String get enlaceInvalido => 'Bu bağlantı geçerli değil.';

  @override
  String get rutaPorDefecto => 'Kampüs turu';

  @override
  String cantidadLugares(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total yer',
      one: '1 yer',
    );
    return '$_temp0';
  }

  @override
  String get titularSinLugares => 'Henüz yer yok';

  @override
  String get titularEmpieza => 'Turunuza başlayın';

  @override
  String get recorridoCompleto => 'Tur tamamlandı';

  @override
  String titularAvance(int hechos, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total yerden $hechos tanesini gezdiniz',
      one: '1 yerden $hechos tanesini gezdiniz',
    );
    return '$_temp0';
  }

  @override
  String get detalleEmpieza =>
      'Kampüsü her seferinde bir yer olmak üzere keşfedin.';

  @override
  String get detalleCompleto =>
      'İstediğiniz zaman herhangi bir yere geri dönün.';

  @override
  String detalleSiguiente(String nombre) {
    return 'Sıradaki: $nombre';
  }

  @override
  String lugaresVisitados(int hechos, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total yerden $hechos tanesi gezildi',
      one: '1 yerden $hechos tanesi gezildi',
    );
    return '$_temp0';
  }

  @override
  String get modoRecorrido => 'Tur';

  @override
  String get modoMapa => 'Harita';

  @override
  String get idiomaYAccesibilidad => 'Dil ve erişilebilirlik';

  @override
  String get sinLugaresPublicados => 'Bu turda henüz yayımlanmış yer yok.';

  @override
  String get paradas => 'Duraklar';

  @override
  String avanceLugares(int hechos, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total yerden $hechos',
      one: '1 yerden $hechos',
    );
    return '$_temp0';
  }

  @override
  String conocisteLosLugares(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total yerin hepsini gördünüz',
      one: 'Yeri gördünüz',
    );
    return '$_temp0';
  }

  @override
  String get vuelveACualquiera => 'İstediğiniz zaman herhangi birine dönün.';

  @override
  String get volverAEmpezar => 'Baştan başla';

  @override
  String get primeraParada => 'İlk durak';

  @override
  String get empezarRecorrido => 'Tura başla';

  @override
  String get siguienteParada => 'Sonraki durak';

  @override
  String get continuarRecorrido => 'Tura devam et';

  @override
  String paradaNDeTotal(int numero, int total) {
    return 'Durak $numero/$total';
  }

  @override
  String get visitado => 'Gezildi';

  @override
  String get lugarDelCampus => 'Kampüsten bir yer';

  @override
  String get campus => 'Kampüs';

  @override
  String yaVisitado(String nombre) {
    return '$nombre, gezildi';
  }

  @override
  String paradaSemantica(int numero, String nombre) {
    return 'Durak $numero, $nombre';
  }

  @override
  String get sugerencia => 'Öneri';

  @override
  String get sugerenciaTitulo => 'Her durağı kampüste bulun';

  @override
  String get sugerenciaTexto =>
      'Harita her yerin nerede olduğunu ve hangilerini gezdiğinizi gösterir.';

  @override
  String get abrirMapa => 'Haritayı aç';

  @override
  String get pieOficial => 'Universidad Tecnológica de Bolívar resmî turu';

  @override
  String get datosDemostracion => 'Deneme verileri';

  @override
  String get categoriaRecursos => 'Kaynaklar';

  @override
  String get categoriaAcademico => 'Akademik';

  @override
  String get categoriaBienestar => 'Sağlık ve destek';

  @override
  String get categoriaServicios => 'Hizmetler';

  @override
  String get categoriaDeporte => 'Spor';

  @override
  String get categoriaCultura => 'Kültür';

  @override
  String get categoriaAdministrativo => 'İdari';

  @override
  String get categoriaSostenibilidad => 'Sürdürülebilirlik';

  @override
  String get verTodoCampus => 'Tüm kampüsü gör';

  @override
  String get acercar => 'Yakınlaştır';

  @override
  String get alejar => 'Uzaklaştır';

  @override
  String get mapaNoCargo => 'Kampüs haritası yüklenemedi.';

  @override
  String get mapaDescripcion =>
      'Kampüs planı. Her durağın numaralı bir işareti, diğer yerlerin bir noktası var.';

  @override
  String visitadosDeTotal(int hechos, int total) {
    return '$total yerden $hechos tanesi gezildi';
  }

  @override
  String get sinUbicacionMapa => 'Haritada konumu yok';

  @override
  String get masLugares => 'Kampüsteki diğer yerler';

  @override
  String get creditoOsm => '© OpenStreetMap katkıda bulunanlar';

  @override
  String get sinDescripcion => 'Bu yerin henüz açıklaması yok.';

  @override
  String get verEn360 => '360° görüntüle';

  @override
  String get sin360 => 'Bu yerin henüz 360° turu yok.';

  @override
  String get audioNarrado => 'Sesli anlatım';

  @override
  String get galeria => 'Galeri';

  @override
  String get video => 'Video';

  @override
  String get lenguaDeSenas => 'İşaret dili';

  @override
  String get contenidoEnPreparacion => 'İçerik hazırlanıyor';

  @override
  String todaviaNoHay(String lista) {
    return 'Henüz yok: $lista';
  }

  @override
  String get fotos => 'Fotoğraflar';

  @override
  String textoEnIdioma(String idioma) {
    return 'Bilgilerin dili: $idioma';
  }

  @override
  String get deslizaParaMirar => 'Bakmak için kaydırın';

  @override
  String get fotoDelLugar => 'Yerin fotoğrafı';

  @override
  String fotoNDeTotal(int numero, int total) {
    return '$numero/$total';
  }

  @override
  String get fotoNoCargo => 'Bu fotoğraf yüklenemedi.';

  @override
  String get videoNoCargo => 'Video yüklenemedi.';

  @override
  String get pausarVideo => 'Videoyu duraklat';

  @override
  String get reproducirVideo => 'Videoyu oynat';

  @override
  String get audioSinSoporte => 'Ses bu platformda çalınamıyor.';

  @override
  String get audioNoCargo => 'Ses yüklenemedi.';

  @override
  String get pausarAudio => 'Sesli anlatımı duraklat';

  @override
  String get escucharHistoria => 'Hikâyeyi dinle';

  @override
  String get escuchando => 'Dinleniyor';

  @override
  String get transcripcionEnPreparacion => 'Metin dökümü hazırlanıyor';

  @override
  String get leerTranscripcion => 'Metin dökümünü oku';

  @override
  String get transcripcion => 'Metin dökümü';

  @override
  String get subtitulos => 'Altyazılar';

  @override
  String narracionEn(String idioma) {
    return 'Anlatım dili: $idioma';
  }

  @override
  String posicionDeTotal(String posicion, String total) {
    return '$posicion / $total';
  }

  @override
  String vistaPanoramicaDe(String nombre) {
    return 'Panoramik görünüm: $nombre';
  }

  @override
  String get esteLugar => 'bu yer';

  @override
  String get deslizaParaGirar => 'Döndürmek için yana kaydırın';

  @override
  String get girarIzquierda => 'Sola döndür';

  @override
  String get girarDerecha => 'Sağa döndür';

  @override
  String get orientarNorte => 'Kuzeye çevir';

  @override
  String get sinEscenas => 'Bu turda henüz yayımlanmış sahne yok.';

  @override
  String get siguienteEscena => 'Sonraki sahne';

  @override
  String get puntoDeInteres => 'İlgi noktası';

  @override
  String get caminandoHacia => 'Gidilen yer';

  @override
  String escenaNDeTotal(int numero, int total) {
    return 'Sahne $numero/$total';
  }

  @override
  String get pistaGiroscopio =>
      'Etrafa bakmak için telefonu hareket ettirin veya sürükleyin';

  @override
  String get pistaArrastre =>
      'Etrafa bakmak için sürükleyin veya okları kullanın';

  @override
  String get preparando360 => '360° tur hazırlanıyor';

  @override
  String get panoramaNoCargo => 'Bu panorama yüklenemedi.';

  @override
  String get avanzarSiguienteEscena => 'Sonraki sahneye geç';

  @override
  String get verInformacion => 'Bilgileri gör';

  @override
  String irA(String destino) {
    return 'Git: $destino';
  }

  @override
  String get desdeAquiPuedesIr => 'Buradan gidebileceğiniz yerler';

  @override
  String get movimientoTelefono => 'Görünümü telefonla hareket ettir';

  @override
  String estasEn(String escena) {
    return 'Bulunduğunuz yer: $escena';
  }

  @override
  String vista360De(String escena) {
    return '360° görünüm: $escena';
  }

  @override
  String get conocisteTodo => 'Turun tamamını gördünüz';

  @override
  String get cierreTexto =>
      'UTB’deki günlük yaşamı oluşturan yerleri gördünüz. İstediğiniz zaman herhangi birine geri dönebilirsiniz.';

  @override
  String get seguirExplorando => 'Keşfetmeye devam et';

  @override
  String get idioma => 'Dil';

  @override
  String get idiomaDelTelefono => 'Telefonun dili';

  @override
  String get accesibilidad => 'Erişilebilirlik';

  @override
  String get tamanoTexto => 'Yazı boyutu';

  @override
  String get tamanoNormal => 'Normal';

  @override
  String get tamanoGrande => 'Büyük';

  @override
  String get tamanoMuyGrande => 'Çok büyük';

  @override
  String get muestraTexto => 'Bu boyutta metin böyle görünür.';

  @override
  String get altoContraste => 'Yüksek kontrast';

  @override
  String get altoContrasteDetalle => 'Daha belirgin metinler ve kenarlıklar.';

  @override
  String get reducirMovimiento => 'Hareketi azalt';

  @override
  String get reducirMovimientoDetalle =>
      'Animasyonları, dönüşleri ve 3B efektleri kapatır.';

  @override
  String get movimientoTelefonoDetalle =>
      '360° turda görünüm telefonun hareketini takip eder.';

  @override
  String get subtitulosDetalle => 'Anlatım çalarken metnini gösterir.';

  @override
  String get ajustesSistema =>
      'Bu ayarlar telefonunuzun erişilebilirlik ayarlarına eklenir.';

  @override
  String get privacidad => 'Gizlilik';

  @override
  String get analiticaTitulo => 'Turu geliştirmemize yardım eder misiniz?';

  @override
  String analiticaTexto(String ajustes) {
    return 'Kabul ederseniz uygulama hangi sahnelerin, yerlerin ve anlatımların kullanıldığını sayar; adınızı, konumunuzu veya sizi tanımlayan hiçbir bilgiyi göndermez. Bunu istediğiniz zaman “$ajustes” bölümünden değiştirebilirsiniz.';
  }

  @override
  String get analiticaAceptar => 'Evet, paylaş';

  @override
  String get analiticaRechazar => 'Hayır, teşekkürler';

  @override
  String analiticaGuardada(String ajustes) {
    return 'Kaydedildi. Bunu “$ajustes” bölümünden değiştirebilirsiniz.';
  }

  @override
  String get analiticaAjuste => 'Kullanım istatistiklerini paylaş';

  @override
  String get analiticaAjusteDetalle =>
      'Anonim: yalnızca hangi sahnelerin, yerlerin ve anlatımların kullanıldığı. Adınız veya konumunuz asla gönderilmez.';

  @override
  String get guiaTitulo => 'Merhaba, ben Max';

  @override
  String get guiaTexto => 'Size UTB kampüsünü gezdireceğim.';

  @override
  String get guia360 => 'Her yere 360° girin ve etrafınıza bakın.';

  @override
  String get guiaMapa => 'Her durağı kampüs haritasında bulun.';

  @override
  String get guiaAudio => 'Her yerin hikâyesini kendi dilinizde dinleyin.';

  @override
  String get guiaEmpezar => 'Tura başla';

  @override
  String get guiaExplorar => 'Kendim keşfedeyim';

  @override
  String get verGuia => 'Karşılamayı tekrar gör';

  @override
  String get verGuiaDetalle => 'Max turun nasıl işlediğini yeniden anlatır.';

  @override
  String get ayuda => 'Yardım';

  @override
  String get comoLlegar => 'Yol tarifi';

  @override
  String navTitulo(String lugar) {
    return '$lugar için yol tarifi';
  }

  @override
  String navPermisoTitulo(String lugar) {
    return 'Sizi $lugar konumuna götüreyim';
  }

  @override
  String get navPermisoTexto =>
      'Rehber açıkken telefonunuzun GPS’ini kullanırım. Konumunuz telefondan çıkmaz ve kaydedilmez.';

  @override
  String get navPermitir => 'Konuma izin ver';

  @override
  String get navSinPermiso =>
      'Konum izni olmadan size yol gösteremem. Yeri haritada bulabilir veya 360° görebilirsiniz.';

  @override
  String get navAbrirAjustes => 'Ayarları aç';

  @override
  String get navGpsApagado =>
      'Telefonunuzun konumu kapalı. Açıp tekrar deneyin.';

  @override
  String get navSimulada => 'Benzetilmiş konum';

  @override
  String get navBuscando => 'GPS sinyali aranıyor…';

  @override
  String navSenalDebil(int metros) {
    return 'Zayıf sinyal (±$metros m). Açık bir alana geçin.';
  }

  @override
  String navRecto(int metros) {
    return '$metros m düz devam edin';
  }

  @override
  String navDerecha(int metros) {
    return '$metros m sonra sağa dönün';
  }

  @override
  String navIzquierda(int metros) {
    return '$metros m sonra sola dönün';
  }

  @override
  String navLigeraDerecha(int metros) {
    return '$metros m sonra hafif sağa gidin';
  }

  @override
  String navLigeraIzquierda(int metros) {
    return '$metros m sonra hafif sola gidin';
  }

  @override
  String get navVuelta => 'Geri dönün';

  @override
  String navLlegando(String lugar, int metros) {
    return '$lugar $metros m uzakta';
  }

  @override
  String navFaltan(int metros, int minutos) {
    return '$metros m kaldı · yaklaşık $minutos dk';
  }

  @override
  String get navRecalculando => 'Rotadan çıktınız. Yeni rota hesaplanıyor…';

  @override
  String get navSinEscaleras => 'Merdivensiz';

  @override
  String get navPlano => 'Harita';

  @override
  String get navCamara => 'Kamera';

  @override
  String get navTerminar => 'Bitir';

  @override
  String navLlegaste(String lugar) {
    return '$lugar konumuna vardınız';
  }

  @override
  String get navVerFicha => 'Ayrıntıları gör';

  @override
  String get navCamaraAviso => 'Ekrana değil, yola bakın.';

  @override
  String get navCamaraNoDisponible =>
      'Kamera açılamadı. Rotayı haritadan izleyin.';

  @override
  String get navCalibrar =>
      'Pusula hassas değil: telefonu sekiz çizerek hareket ettirin.';

  @override
  String navSinRuta(String lugar) {
    return '$lugar için bir yol bulamadım.';
  }

  @override
  String get navFueraDelCampus =>
      'Kampüsün dışındasın. Rehber UTB içinde çalışır: vardığında aç.';

  @override
  String get navCaminandoHacia => 'Gidilen yer';

  @override
  String get navLlegada => 'Vardın';

  @override
  String get navIdeaRuta =>
      'Seni kampüs yollarından götürür, her dönüşten önce haber veririm.';

  @override
  String get navIdeaCamara =>
      'Telefonu kaldır: kameranın üzerindeki ok yolu gösterir.';

  @override
  String get navSinEscalerasDetalle => 'Rotadaki basamaklardan kaçınır.';

  @override
  String get navAproximada => 'Bu yerin girişi henüz yaklaşık.';

  @override
  String navPlanoSemantica(String lugar) {
    return '$lugar rotasını gösteren harita';
  }

  @override
  String get verMapa3d => '3B haritayı göster';

  @override
  String get verMapa2d => '2B haritaya dön';

  @override
  String get mapa3dDescripcion =>
      'Kampüsün 3B modeli. Ayrıntılar için bir durağa dokunun.';

  @override
  String get mapa3dNoDisponible =>
      '3B harita açılamadı. 2B haritayı kullanabilir veya tekrar deneyebilirsiniz.';

  @override
  String get creditoModelo3d => '3B model: ElMapita UTB';

  @override
  String get mapa3dCargando => '3B harita yükleniyor';
}
