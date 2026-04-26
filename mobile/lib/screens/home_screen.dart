import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import 'qr_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Uint8List? _selectedBytes;
  String? _selectedFileName;
  int     _ttlMinutes = 15;
  bool    _isUploading = false;
  String? _error;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _selectedBytes    = result.files.single.bytes!;
        _selectedFileName = result.files.single.name;
        _error = null;
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedBytes == null) {
      setState(() { _error = "Please select a file first."; });
      return;
    }

    setState(() { _isUploading = true; _error = null; });

    final response = await ApiService.uploadFile(
      bytes: _selectedBytes!,
      filename: _selectedFileName!,
      ttlMinutes: _ttlMinutes,
    );

    setState(() { _isUploading = false; });

    if (response != null) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => QrScreen(uploadResponse: response)),
      );
    } else {
      setState(() { _error = "Upload failed. Please check your connection."; });
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D27),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.lock, color: Color(0xFF6C63FF), size: 20),
            SizedBox(width: 8),
            Text("SecureFileShare", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Color(0xFF888888)), onPressed: _logout),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Send a File", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text("File is encrypted before leaving your device.", style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1D27),
                    border: Border.all(color: const Color(0xFF2A2D3E)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedBytes != null ? Icons.insert_drive_file : Icons.upload_file,
                        color: _selectedBytes != null ? const Color(0xFF6C63FF) : const Color(0xFF444444),
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedFileName ?? "Tap to select a file",
                        style: TextStyle(
                          color: _selectedBytes != null ? Colors.white : const Color(0xFF555555),
                          fontSize: 14,
                          fontWeight: _selectedBytes != null ? FontWeight.w600 : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_selectedBytes != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          "${(_selectedBytes!.length / 1024).toStringAsFixed(1)} KB",
                          style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text("Auto-delete after:", style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13)),
              const SizedBox(height: 10),
              Row(
                children: [5, 15, 30].map((mins) => _ttlChip(mins)).toList(),
              ),
              const SizedBox(height: 28),
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D1A1A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 13)),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isUploading || _selectedBytes == null) ? null : _uploadFile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: const Color(0xFF6C63FF),
                    disabledBackgroundColor: const Color(0xFF2A2D3E),
                  ),
                  child: _isUploading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                            SizedBox(width: 10),
                            Text("Encrypting & Uploading...", style: TextStyle(color: Colors.white)),
                          ],
                        )
                      : const Text("🔒  Encrypt & Send", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ttlChip(int mins) {
    final selected = _ttlMinutes == mins;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => setState(() { _ttlMinutes = mins; }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF6C63FF) : const Color(0xFF1A1D27),
            border: Border.all(color: selected ? const Color(0xFF6C63FF) : const Color(0xFF2A2D3E)),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            "$mins min",
            style: TextStyle(color: selected ? Colors.white : const Color(0xFF888888), fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}