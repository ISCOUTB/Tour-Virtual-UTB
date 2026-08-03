import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import 'package:http/http.dart' as http;

class RecorridoScreen extends StatefulWidget {
  final int lugarId;
  // Cambia este puerto por el que te arroja tu terminal de C# (ej: 5209)
  final String apiBaseUrl = 'http://localhost:5209/api';

  const RecorridoScreen({super.key, required this.lugarId});

  @override
  State<RecorridoScreen> createState() => _RecorridoScreenState();
}

class _RecorridoScreenState extends State<RecorridoScreen> {
  bool _isLoading = true;
  List<dynamic> _escenas = [];
  List<dynamic> _hotspotsActuales = [];
  Map<String, dynamic>? _escenaActual;

  @override
  void initState() {
    super.initState();
    _cargarEscenas();
  }

  Future<void> _cargarEscenas() async {
    try {
      // 1. Traer todas las escenas del lugar
      final response = await http.get(
        Uri.parse('${widget.apiBaseUrl}/Escenas/lugar/${widget.lugarId}'),
      );
      if (response.statusCode == 200) {
        _escenas = json.decode(response.body);

        // 2. Buscar la escena principal para iniciar allí
        _escenaActual = _escenas.firstWhere(
          (e) => e['esEscenaPrincipal'] == true,
          orElse: () => _escenas.isNotEmpty ? _escenas[0] : null,
        );

        if (_escenaActual != null) {
          await _cargarHotspots(_escenaActual!['id']);
        }
      }
    } catch (e) {
      debugPrint("Error cargando escenas: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cargarHotspots(int escenaId) async {
    try {
      final response = await http.get(
        Uri.parse('${widget.apiBaseUrl}/Hotspots/escena/$escenaId'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _hotspotsActuales = json.decode(response.body);
        });
      }
    } catch (e) {
      debugPrint("Error cargando hotspots: $e");
    }
  }

  void _navegarAEscena(int escenaDestinoId) {
    setState(() => _isLoading = true);
    final nuevaEscena = _escenas.firstWhere((e) => e['id'] == escenaDestinoId);

    setState(() {
      _escenaActual = nuevaEscena;
    });

    _cargarHotspots(escenaDestinoId).then((_) {
      setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_escenaActual == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child: Text('No hay escenas disponibles para este lugar'),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PanoramaViewer(
        animSpeed: 1.0,
        sensorControl: SensorControl.orientation,
        hotspots: _hotspotsActuales.map((h) {
          return Hotspot(
            latitude: h['pitch'],
            longitude: h['yaw'],
            width: 60,
            height: 60,
            widget: GestureDetector(
              onTap: () => _navegarAEscena(h['escenaDestinoId']),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xAA000000),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.keyboard_double_arrow_up,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          );
        }).toList(),
        child: Image.network(_escenaActual!['imagenUrl']),
      ),
    );
  }
}
