import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_model_config.dart';

class ServerManager {
  static final ServerManager _instance = ServerManager._internal();
  factory ServerManager() => _instance;
  ServerManager._internal();

  final List<AIModelConfig> _availableModels = [
    AIModelConfig(
      name: 'mistral-7b',
      source: 'hf://TheBloke/Mistral-7B-Instruct-v0.2-GGUF',
      backend: 'CPU',
      port: 8080,
    ),
    AIModelConfig(
      name: 'llama3.2',
      source: 'ollama://llama3.2',
      backend: 'CPU',
      port: 8081,
    ),
    AIModelConfig(
      name: 'granite-8b',
      source: 'hf://ibm-granite/granite-8b-code-base-4k-GGUF',
      backend: 'CPU',
      port: 8082,
    ),
  ];

  List<AIModelConfig> get availableModels => _availableModels;

  Future<Map<String, dynamic>> getSystemInfo() async {
    // This would normally get actual system info
    return {
      'os': 'Windows',
      'cpu_model': 'AMD64',
      'cpu_cores': 8,
      'memory_gb': 16,
      'gpu_vendor': 'NVIDIA',
      'gpu_model': 'GeForce GTX 1660 Ti',
      'gpu_memory': 6,
      'compute_backend': 'CUDA',
    };
  }

  Future<bool> startModel(String modelName) async {
    final model = _availableModels.firstWhere(
      (m) => m.name == modelName,
      orElse: () => throw Exception('Model not found'),
    );

    // Simulate model loading
    await Future.delayed(Duration(seconds: 2));

    // In a real implementation, this would start the actual model server
    return true;
  }

  Future<bool> stopModel(String modelName) async {
    // Simulate model stopping
    await Future.delayed(Duration(seconds: 1));
    return true;
  }

  Future<String> generateResponse(String modelName, String prompt) async {
    // This would normally call the actual model server
    // For now, we'll simulate a response
    await Future.delayed(Duration(milliseconds: 500));
    return 'This is a simulated response from $modelName for: $prompt';
  }

  Future<Map<String, dynamic>> getModelStatus(String modelName) async {
    final model = _availableModels.firstWhere(
      (m) => m.name == modelName,
      orElse: () => throw Exception('Model not found'),
    );

    return {
      'name': model.name,
      'status': 'running',
      'backend': model.backend,
      'port': model.port,
      'memory_usage': '2.5GB',
      'inference_speed': '50ms',
    };
  }
}
