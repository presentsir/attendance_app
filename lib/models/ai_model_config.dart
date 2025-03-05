class AIModelConfig {
  final String name;
  final String source;
  final String backend;
  final int port;
  final bool isActive;

  AIModelConfig({
    required this.name,
    required this.source,
    required this.backend,
    required this.port,
    this.isActive = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'source': source,
        'backend': backend,
        'port': port,
        'isActive': isActive,
      };

  factory AIModelConfig.fromJson(Map<String, dynamic> json) => AIModelConfig(
        name: json['name'],
        source: json['source'],
        backend: json['backend'],
        port: json['port'],
        isActive: json['isActive'] ?? false,
      );
}
