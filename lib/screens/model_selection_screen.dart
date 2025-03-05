import 'package:flutter/material.dart';
import '../services/chatbot_service.dart';

class ModelSelectionScreen extends StatefulWidget {
  @override
  _ModelSelectionScreenState createState() => _ModelSelectionScreenState();
}

class _ModelSelectionScreenState extends State<ModelSelectionScreen> {
  final ChatbotService _chatbotService = ChatbotService();
  List<Map<String, dynamic>> _models = [];
  Map<String, dynamic>? _systemInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final models = await _chatbotService.getAvailableModels();
      final systemInfo = await _chatbotService.getSystemInfo();

      setState(() {
        _models = models;
        _systemInfo = systemInfo;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading model information')),
      );
    }
  }

  Future<void> _toggleModel(String modelName) async {
    try {
      final model = _models.firstWhere((m) => m['name'] == modelName);
      final isActive = model['isActive'] ?? false;

      if (isActive) {
        await _chatbotService.stopModel(modelName);
      } else {
        await _chatbotService.startModel(modelName);
      }

      // Refresh the model status
      final status = await _chatbotService.getModelStatus(modelName);
      setState(() {
        final index = _models.indexWhere((m) => m['name'] == modelName);
        if (index != -1) {
          _models[index] = {..._models[index], ...status};
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error toggling model: $e')),
      );
    }
  }

  Widget _buildSystemInfo() {
    if (_systemInfo == null) return SizedBox.shrink();

    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            _buildInfoRow('OS', _systemInfo!['os']),
            _buildInfoRow('CPU',
                '${_systemInfo!['cpu_model']} (${_systemInfo!['cpu_cores']} cores)'),
            _buildInfoRow('Memory', '${_systemInfo!['memory_gb']}GB'),
            _buildInfoRow('GPU',
                '${_systemInfo!['gpu_vendor']} ${_systemInfo!['gpu_model']}'),
            _buildInfoRow('GPU Memory', '${_systemInfo!['gpu_memory']}GB'),
            _buildInfoRow('Backend', _systemInfo!['compute_backend']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildModelCard(Map<String, dynamic> model) {
    final isActive = model['isActive'] ?? false;
    final status = model['status'] ?? 'stopped';

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(
          isActive ? Icons.check_circle : Icons.cancel,
          color: isActive ? Colors.green : Colors.red,
        ),
        title: Text(model['name']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Source: ${model['source']}'),
            Text('Backend: ${model['backend']}'),
            if (isActive) ...[
              Text('Port: ${model['port']}'),
              Text('Memory Usage: ${model['memory_usage']}'),
              Text('Inference Speed: ${model['inference_speed']}'),
            ],
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _toggleModel(model['name']),
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive ? Colors.red : Colors.green,
            foregroundColor: Colors.white,
          ),
          child: Text(isActive ? 'Stop' : 'Start'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Model Management'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSystemInfo(),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Available Models',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ..._models.map((model) => _buildModelCard(model)),
                ],
              ),
            ),
    );
  }
}
