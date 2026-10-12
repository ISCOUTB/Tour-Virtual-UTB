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
  String get verTodoCampus => 'Tüm kampüsü gör';

  @override
  String get acercar => 'Yakınlaştır';

  @override
  String get alejar => 'Uzaklaştır';

  @override
  String get mapaNoCargo => 'Kampüs haritası yüklenemedi.';

  @override
  String get mapaDescripcion =>
      'Kampüsün resimli haritası. Her durağın numaralı bir işareti var.';

  @override
  String visitadosDeTotal(int hechos, int total) {
    return '$total yerden $hechos tanesi gezildi';
  }

  @override
  String get sinUbicacionMapa => 'Haritada konumu yok';

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
  String get escucharEn => 'Dinleme dili';

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
}
