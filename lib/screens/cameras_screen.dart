import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CamerasScreen extends StatefulWidget {
  const CamerasScreen({super.key});

  @override
  State<CamerasScreen> createState() => _CamerasScreenState();
}

class _CamerasScreenState extends State<CamerasScreen> {
  List<dynamic> _cameras = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCameras();
  }

  Future<void> _loadCameras() async {
    setState(() { _loading = true; _error = null; });
    try {
      final cameras = await ApiService.getCameras();
      setState(() { _cameras = cameras; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _buildError();
    if (_cameras.isEmpty) return _buildEmpty();

    return RefreshIndicator(
      onRefresh: _loadCameras,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _cameras.length,
        itemBuilder: (_, i) => _CameraCard(camera: _cameras[i]),
      ),
    );
  }

  Widget _buildError() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 16),
        Text('Gagal memuat kamera', style: TextStyle(color: Colors.grey[400])),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _loadCameras, child: const Text('Coba lagi')),
      ],
    ),
  );

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.videocam_off, color: Colors.grey[600], size: 64),
        const SizedBox(height: 16),
        Text('Tidak ada kamera', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
      ],
    ),
  );
}

class _CameraCard extends StatefulWidget {
  final Map<String, dynamic> camera;
  const _CameraCard({required this.camera});

  @override
  State<_CameraCard> createState() => _CameraCardState();
}

class _CameraCardState extends State<_CameraCard> {
  int _refreshKey = 0;

  @override
  Widget build(BuildContext context) {
    final snapshotUrl = widget.camera['snapshotUrl'] as String;
    final name = widget.camera['name'] as String;

    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                '$snapshotUrl&t=$_refreshKey',
                key: ValueKey(_refreshKey),
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: const Color(0xFF111111),
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF111111),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, color: Colors.grey, size: 40),
                        SizedBox(height: 8),
                        Text('Snapshot tidak tersedia', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.grey, size: 20),
                  tooltip: 'Refresh snapshot',
                  onPressed: () => setState(() => _refreshKey++),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
