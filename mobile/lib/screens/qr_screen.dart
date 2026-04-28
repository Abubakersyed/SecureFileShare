import '../config.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;


class QrScreen extends StatefulWidget {
  final Map<String, dynamic> uploadResponse;
  const QrScreen({super.key, required this.uploadResponse});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  late final String _sessionId;
  late final String _filename;
  late final int    _ttlMinutes;
  late final DateTime _expiresAt;
  late final String _qrData;
  bool _isDelivered = false;
  int _secondsLeft = 0;
  late final Stream<int> _ticker;
  Timer? _pollTimer;

  @override
  @override
void initState() {
  super.initState();
  _sessionId  = widget.uploadResponse["session_id"] as String;
  _filename   = widget.uploadResponse["filename"]   as String;
  _ttlMinutes = widget.uploadResponse["ttl_minutes"] as int;
  final rawExpiry = widget.uploadResponse["expires_at"] as String;
  _expiresAt = DateTime.parse(rawExpiry.endsWith('Z') ? rawExpiry : rawExpiry + 'Z').toLocal();
  _qrData = "http://192.168.0.3:8000/access/$_sessionId";
  final now = DateTime.now();
  _secondsLeft = _expiresAt.difference(now).inSeconds.clamp(0, 9999);
  _ticker = Stream.periodic(const Duration(seconds: 1), (i) => i);
  _startPolling();
  _loadQrData();
}

Future<void> _loadQrData() async {
  final baseUrl = await AppConfig.getBaseUrl();
  setState(() {
    _qrData = "$baseUrl/access/$_sessionId";
  });
}

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final res = await http.get(
          Uri.parse("${await AppConfig.getBaseUrl()}/files/info/$_sessionId"),
        );
        if (res.statusCode == 410 || res.statusCode == 404) {
          timer.cancel();
          if (mounted) {
            setState(() { _isDelivered = true; });
          }
        }
      } catch (e) {}
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  String _formatCountdown(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds  % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  void _copyToken() {
    Clipboard.setData(ClipboardData(text: _sessionId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Session token copied to clipboard")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D27),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("File Sent", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isDelivered ? const Color(0xFF1A2D1A) : const Color(0xFF1A1D27),
                  border: Border.all(color: _isDelivered ? const Color(0xFF14532D) : const Color(0xFF2A2D3E)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isDelivered ? Icons.check_circle : Icons.check_circle,
                      color: const Color(0xFF86EFAC), size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isDelivered ? "File delivered & deleted!" : "File uploaded securely",
                            style: const TextStyle(color: Color(0xFF86EFAC), fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          Text(_filename, style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 12), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text("Show this QR to the recipient", style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: _qrData,
                  version: QrVersions.auto,
                  size: 220,
                ),
              ),
              const SizedBox(height: 20),
              _isDelivered
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2D1A),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      "✅ File delivered & deleted!",
                      style: TextStyle(color: Color(0xFF86EFAC), fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  )
                : StreamBuilder<int>(
                    stream: _ticker,
                    builder: (context, snapshot) {
                      final elapsed = snapshot.data ?? 0;
                      final remaining = (_secondsLeft - elapsed).clamp(0, 9999);
                      final expired = remaining == 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: expired ? const Color(0xFF2D1A1A) : const Color(0xFF1A1A2D),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          expired ? "⏱ Session expired" : "⏱ Auto-deletes in ${_formatCountdown(remaining)}",
                          style: TextStyle(
                            color: expired ? const Color(0xFFF87171) : const Color(0xFFA5B4FC),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Or share the session token manually", style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D27),
                  border: Border.all(color: const Color(0xFF2A2D3E)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _sessionId,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: "monospace"),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: _copyToken,
                      child: const Icon(Icons.copy, color: Color(0xFF6C63FF), size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D27),
                  border: Border.all(color: const Color(0xFF2A2D3E)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _infoRow("File", _filename),
                    _infoRow("TTL", "$_ttlMinutes minutes"),
                    _infoRow("Expires", "${_expiresAt.hour}:${_expiresAt.minute.toString().padLeft(2,'0')}"),
                    _infoRow("Encryption", "AES-256"),
                    _infoRow("Storage", "RAM only"),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "⚠️  File is permanently deleted after download or when timer expires.",
                style: TextStyle(color: Color(0xFF555555), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 13)),
          Text(value,  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}