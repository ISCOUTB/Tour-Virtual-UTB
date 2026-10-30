import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_virtual/l10n/textos.dart';
import 'package:tour_virtual/app_tour.dart';
import 'package:tour_virtual/nucleo/idiomas.dart';

/// Claves de un ARB sin sus metadatos.
Map<String, String> _mensajes(File arb) {
  final json = jsonDecode(arb.readAsStringSync()) as Map<String, dynamic>;
  return {
    for (final MapEntry(:key, :value) in json.entries)
      if (!key.startsWith('@')) key: value as String,
  };
}

void main() {
  final carpeta = Directory('../../packages/tour_virtual/lib/l10n');
  final plantillaArb = File(
    '../../packages/tour_virtual/lib/l10n/textos_es.arb',
  );
  final plantilla = _mensajes(plantillaArb);
  final metadatos =
      jsonDecode(plantillaArb.readAsStringSync()) as Map<String, dynamic>;
  final traducciones = carpeta
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.arb') && f != plantillaArb)
      .where((f) => !f.path.endsWith('textos_es.arb'))
      .toList();

  test('hay una traducción por cada idioma del selector', () {
    final arbs = traducciones
        .map((f) => f.uri.pathSegments.last)
        .map((n) => n.replaceAll('textos_', '').replaceAll('.arb', ''))
        .toSet();
    final selector = idiomasUi
        .map((i) => i.locale.toString())
        .where((c) => c != 'es')
        .toSet();
    expect(arbs, selector);
    for (final idioma in idiomasUi) {
      expect(Textos.supportedLocales, contains(idioma.locale));
    }
  });

  for (final arb in traducciones) {
    final nombre = arb.uri.pathSegments.last;

    test('$nombre no deja claves sin traducir', () {
      final mensajes = _mensajes(arb);
      // pt_PT solo lleva lo que cambia en Portugal: el resto lo hereda del
      // portugués de Brasil, nunca del español.
      if (nombre == 'textos_pt_PT.arb') {
        expect(plantilla.keys, containsAll(mensajes.keys));
        return;
      }
      final faltan = plantilla.keys.where((k) => !mensajes.containsKey(k));
      expect(faltan, isEmpty, reason: 'sin traducir en $nombre');
      final sobran = mensajes.keys.where((k) => !plantilla.containsKey(k));
      expect(sobran, isEmpty, reason: 'claves que la plantilla no tiene');
    });

    test('$nombre conserva los marcadores de cada mensaje', () {
      // Un {nombre} mal escrito no falla al compilar: sale tal cual en
      // pantalla, con las llaves.
      for (final MapEntry(key: clave, value: texto) in _mensajes(arb).entries) {
        final datos = metadatos['@$clave'] as Map<String, dynamic>?;
        final marcadores =
            (datos?['placeholders'] as Map<String, dynamic>?)?.keys ??
            const <String>[];
        for (final marcador in marcadores) {
          expect(
            texto,
            matches(RegExp('\\{$marcador[,}]')),
            reason: '$nombre:$clave sin {$marcador}',
          );
        }
        expect(texto.trim(), isNotEmpty, reason: '$nombre:$clave vacío');
      }
    });
  }

  group('elegir idioma', () {
    test('gana el primero de los del teléfono que esté traducido', () {
      expect(
        resolverIdioma(const [Locale('ru'), Locale('de')]),
        const Locale('de'),
      );
      expect(resolverIdioma(const [Locale('es', 'CO')]), const Locale('es'));
      expect(resolverIdioma(const [Locale('zh', 'CN')]), const Locale('zh'));
    });

    test('el portugués distingue Portugal del resto', () {
      expect(
        resolverIdioma(const [Locale('pt', 'PT')]),
        const Locale('pt', 'PT'),
      );
      expect(resolverIdioma(const [Locale('pt', 'BR')]), const Locale('pt'));
      expect(resolverIdioma(const [Locale('pt', 'AO')]), const Locale('pt'));
    });

    test('sin ninguno traducido, inglés', () {
      expect(
        resolverIdioma(const [Locale('ar'), Locale('ru')]),
        const Locale('en'),
      );
      expect(resolverIdioma(const []), const Locale('en'));
    });
  });

  test('las mayúsculas respetan el turco', () {
    expect(mayusculas('ilk durak', const Locale('tr')), 'İLK DURAK');
    expect(mayusculas('ılık', const Locale('tr')), 'ILIK');
    expect(mayusculas('ilk durak', const Locale('en')), 'ILK DURAK');
  });

  test('el nombre de cada idioma va en ese idioma', () {
    expect(nombreDeIdioma('es'), 'Español');
    expect(nombreDeIdioma('pt-PT'), 'Português (Portugal)');
    expect(nombreDeIdioma('ja'), '日本語');
    expect(nombreDeIdioma('csn'), 'Lengua de Señas Colombiana');
    expect(esLenguaDeSenas('csn'), isTrue);
    expect(esLenguaDeSenas('es'), isFalse);
    expect(
      localeDeEtiqueta('zh-Hans-CN'),
      const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hans',
        countryCode: 'CN',
      ),
    );
  });

  test('el aumento de texto se suma al del sistema sin pasar del 200 %', () {
    const sistema = TextScaler.linear(1.6);
    expect(const EscalaConAumento(TextScaler.noScaling, 1.5).scale(10), 15);
    // 1,6 × 1,5 sería 240 %: se queda en 200 %.
    expect(const EscalaConAumento(sistema, 1.5).scale(10), 20);
    // Si el sistema ya pide más del 200 %, manda el sistema.
    expect(const EscalaConAumento(TextScaler.linear(2.4), 1.25).scale(10), 24);
  });
}
