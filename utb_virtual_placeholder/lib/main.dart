import 'package:flutter/material.dart';

void main() {
  runApp(const UtbVirtualApp());
}

class UtbVirtualApp extends StatelessWidget {
  const UtbVirtualApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UTB Virtual (Placeholder)',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class Poi {
  final String nombre;
  final String categoria;
  final String descripcion;

  const Poi({
    required this.nombre,
    required this.categoria,
    required this.descripcion,
  });
}

const List<Poi> kMvpPois = [
  Poi(
    nombre: 'Zona de comidas',
    categoria: 'Servicios',
    descripcion:
        'Punto de encuentro de estudiantes y docentes. Incluye oferta gastronómica y horarios.',
  ),
  Poi(
    nombre: 'Murales UTB',
    categoria: 'Cultura',
    descripcion:
        'Espacio artístico con identidad institucional. Contenido sugerido: historia y autores.',
  ),
  Poi(
    nombre: 'Salones representativos',
    categoria: 'Académico',
    descripcion:
        'Aulas destacadas para mostrar infraestructura, dotación tecnológica y metodología.',
  ),
  Poi(
    nombre: 'Biblioteca',
    categoria: 'Recursos',
    descripcion:
        'Servicios bibliográficos, salas de estudio y apoyo a investigación.',
  ),
  Poi(
    nombre: 'Bienestar universitario',
    categoria: 'Comunidad',
    descripcion:
        'Acompañamiento integral, actividades físicas, culturales y orientación estudiantil.',
  ),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const MapaAereoTab(),
      StreetViewLikeTab(onOpenPoi: _openPoiDetail),
      PoisTab(onOpenPoi: _openPoiDetail),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('UTB Virtual · MVP Placeholder')),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.streetview_outlined),
            selectedIcon: Icon(Icons.streetview),
            label: 'Recorrido',
          ),
          NavigationDestination(
            icon: Icon(Icons.place_outlined),
            selectedIcon: Icon(Icons.place),
            label: 'POI',
          ),
        ],
      ),
    );
  }

  void _openPoiDetail(Poi poi) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => PoiDetailSheet(poi: poi),
    );
  }
}

class MapaAereoTab extends StatelessWidget {
  const MapaAereoTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mapa aéreo del campus',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Placeholder para integrar flutter_map o Mapbox con puntos destacados.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.indigo.shade50,
                border: Border.all(color: Colors.indigo.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('POI del MVP (5)'),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: kMvpPois.length,
                      itemBuilder: (context, index) {
                        final poi = kMvpPois[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo.shade200,
                            child: Text('${index + 1}'),
                          ),
                          title: Text(poi.nombre),
                          subtitle: Text(poi.categoria),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StreetViewLikeTab extends StatelessWidget {
  final void Function(Poi poi) onOpenPoi;

  const StreetViewLikeTab({super.key, required this.onOpenPoi});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vista streetview like (simulada)',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aquí se integra el visor 360 real para caminar virtualmente por UTB.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const Spacer(),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      Chip(label: Text('Escena 1: Entrada principal')),
                      Chip(label: Text('Escena 2: Zona académica')),
                      Chip(label: Text('Escena 3: Biblioteca')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 90,
            left: 18,
            child: FloatingActionButton.small(
              heroTag: 'poi1',
              onPressed: () => onOpenPoi(kMvpPois[0]),
              child: const Icon(Icons.place),
            ),
          ),
          Positioned(
            top: 180,
            right: 22,
            child: FloatingActionButton.small(
              heroTag: 'poi2',
              onPressed: () => onOpenPoi(kMvpPois[1]),
              child: const Icon(Icons.place),
            ),
          ),
          Positioned(
            bottom: 150,
            left: 110,
            child: FloatingActionButton.small(
              heroTag: 'poi3',
              onPressed: () => onOpenPoi(kMvpPois[2]),
              child: const Icon(Icons.place),
            ),
          ),
        ],
      ),
    );
  }
}

class PoisTab extends StatelessWidget {
  final void Function(Poi poi) onOpenPoi;

  const PoisTab({super.key, required this.onOpenPoi});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final poi = kMvpPois[index];
        return ListTile(
          leading: const Icon(Icons.location_on_outlined),
          title: Text(poi.nombre),
          subtitle: Text(poi.descripcion),
          trailing: FilledButton(
            onPressed: () => onOpenPoi(poi),
            child: const Text('Ver'),
          ),
        );
      },
      separatorBuilder: (context, index) => const Divider(),
      itemCount: kMvpPois.length,
    );
  }
}

class PoiDetailSheet extends StatelessWidget {
  final Poi poi;

  const PoiDetailSheet({super.key, required this.poi});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(poi.nombre, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(poi.categoria, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            Text(poi.descripcion),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Imágenes'),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Video'),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.volume_up_outlined),
                  label: const Text('Audio historia'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
