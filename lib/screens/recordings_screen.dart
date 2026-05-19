import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'player_screen.dart';

class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key});

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  List<dynamic> _recordings = [];
  bool _loading = true;
  String? _error;
  String? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadRecordings();
  }

  Future<void> _loadRecordings({String? date}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final recordings = await ApiService.getRecordings(date: date, limit: 100);
      setState(() { _recordings = recordings; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(data: ThemeData.dark(), child: child!),
    );
    if (picked != null) {
      final dateStr = DateFormat('yyyy-MM-dd').format(picked);
      setState(() => _selectedDate = dateStr);
      _loadRecordings(date: dateStr);
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatTime(String filename) {
    final name = filename.replaceAll('.mp4', '');
    final parts = name.split('.');
    if (parts.length == 2) return '${parts[0]}:${parts[1]}';
    return name;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFF111111),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _selectedDate ?? 'Semua rekaman',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
              TextButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today, size: 16),
                label: const Text('Filter tanggal'),
              ),
              if (_selectedDate != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                  onPressed: () {
                    setState(() => _selectedDate = null);
                    _loadRecordings();
                  },
                ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildError()
                  : _recordings.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          onRefresh: () => _loadRecordings(date: _selectedDate),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _recordings.length,
                            itemBuilder: (_, i) => _RecordingTile(
                              recording: _recordings[i],
                              formatSize: _formatSize,
                              formatTime: _formatTime,
                            ),
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildError() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 16),
        Text('Gagal memuat rekaman', style: TextStyle(color: Colors.grey[400])),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: () => _loadRecordings(date: _selectedDate), child: const Text('Coba lagi')),
      ],
    ),
  );

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.video_library_outlined, color: Colors.grey[600], size: 64),
        const SizedBox(height: 16),
        Text('Tidak ada rekaman', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
      ],
    ),
  );
}

class _RecordingTile extends StatelessWidget {
  final Map<String, dynamic> recording;
  final String Function(int) formatSize;
  final String Function(String) formatTime;

  const _RecordingTile({
    required this.recording,
    required this.formatSize,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    final filename = recording['filename'] as String? ?? '';
    final camera = recording['camera'] as String? ?? '';
    final date = recording['date'] as String? ?? '';
    final hour = recording['hour'] as String? ?? '';
    final size = recording['size'] as int? ?? 0;
    final key = recording['key'] as String? ?? '';

    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.play_circle_outline, color: Color(0xFF1565C0), size: 28),
        ),
        title: Text(
          '$date  $hour:${formatTime(filename)}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
        ),
        subtitle: Text(
          '$camera  •  ${formatSize(size)}',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () async {
          try {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator()),
            );
            final url = await ApiService.getRecordingUrl(key);
            if (context.mounted) {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlayerScreen(
                    url: url,
                    title: '$date $hour:${formatTime(filename)}',
                  ),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gagal membuka rekaman')),
              );
            }
          }
        },
      ),
    );
  }
}
