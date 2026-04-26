class AppConfig {
  // Change ONLY this IP when you switch networks
  static const String serverIp = "192.168.0.4";
  static const int serverPort = 8000;
  static const String baseUrl = "http://$serverIp:$serverPort";
}