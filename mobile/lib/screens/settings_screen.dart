import 'package:flutter/material.dart';
import '../config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _ipCtrl = TextEditingController();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUrl();
  }

  Future<void> _loadCurrentUrl() async {
    final url = await AppConfig.getBaseUrl();
    setState(() {
      _ipCtrl.text = url;
    });
  }

  Future<void> _save() async {
    String url = _ipCtrl.text.trim();
    if (!url.startsWith("http")) {
      url = "http://$url";
    }
    if (!url.contains(":8000")) {
      url = "$url:8000";
    }
    await AppConfig.setBaseUrl(url);
    setState(() { _saved = true; });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() { _saved = false; });
    });
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
        title: const Text("Server Settings", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Server IP Address", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              "Enter the IP address of the PC running the backend.\nRun 'ipconfig' on the PC and use the IPv4 address.",
              style: TextStyle(color: Color(0xFF888888), fontSize: 13),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _ipCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "e.g. 192.168.0.4 or 192.168.43.1",
                hintStyle: const TextStyle(color: Color(0xFF555555)),
                prefixIcon: const Icon(Icons.wifi, color: Color(0xFF555555), size: 20),
                filled: true,
                fillColor: const Color(0xFF1A1D27),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A2D3E))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A2D3E))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6C63FF))),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: _saved ? const Color(0xFF22c55e) : const Color(0xFF6C63FF),
                ),
                child: Text(
                  _saved ? "✓ Saved!" : "Save Server Address",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D27),
                border: Border.all(color: const Color(0xFF2A2D3E)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("How to find your PC's IP:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  SizedBox(height: 8),
                  Text("1. Open PowerShell on your PC", style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
                  Text("2. Type: ipconfig", style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
                  Text("3. Look for IPv4 Address", style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
                  Text("4. Enter it here (e.g. 192.168.1.5)", style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}