import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:ui';
import 'api_config.dart';
import 'ollama_service.dart';
import 'tflite_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _hostController = TextEditingController();
  final _modelController = TextEditingController();
  bool _isTesting = false;
  bool? _isConnected;
  InferenceMode _inferenceMode = InferenceMode.ollama;
  bool _tfliteModelLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _hostController.text = await ApiConfig.getHost();
    _modelController.text = await ApiConfig.getModel();
    _inferenceMode = await ApiConfig.getInferenceMode();
    _tfliteModelLoaded = TfliteService.isModelLoaded;
    if (!_tfliteModelLoaded) {
      _tfliteModelLoaded = await TfliteService.loadModel();
    }
    setState(() {});
  }

  Future<void> _saveSettings() async {
    await ApiConfig.setHost(_hostController.text.trim());
    await ApiConfig.setModel(_modelController.text.trim());
    await ApiConfig.setInferenceMode(_inferenceMode);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Settings saved!'),
          backgroundColor: const Color(0xFF00E676),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _isConnected = null;
    });
    final connected = await OllamaService.testConnection();
    if (mounted) {
      setState(() {
        _isTesting = false;
        _isConnected = connected;
      });
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E21), Color(0xFF131736)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Inference Mode Section
                FadeInDown(
                  duration: const Duration(milliseconds: 500),
                  child: _buildSectionHeader(
                    icon: FontAwesomeIcons.brain,
                    title: 'Inference Mode',
                    color: const Color(0xFF00D2FF),
                  ),
                ),
                const SizedBox(height: 16),

                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  child: _buildGlassCard(
                    child: Column(
                      children: [
                        _buildModeOption(
                          title: 'Ollama (Cloud)',
                          subtitle: 'Full AI analysis with detailed results',
                          icon: FontAwesomeIcons.cloud,
                          color: const Color(0xFF6C63FF),
                          isSelected: _inferenceMode == InferenceMode.ollama,
                          onTap: () {
                            setState(
                              () => _inferenceMode = InferenceMode.ollama,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildModeOption(
                          title: 'On-Device (TFLite)',
                          subtitle: _tfliteModelLoaded
                              ? 'Fast offline analysis • Model loaded'
                              : 'Model not available',
                          icon: FontAwesomeIcons.microchip,
                          color: const Color(0xFF00E676),
                          isSelected: _inferenceMode == InferenceMode.tflite,
                          isEnabled: _tfliteModelLoaded,
                          onTap: () {
                            if (_tfliteModelLoaded) {
                              setState(
                                () => _inferenceMode = InferenceMode.tflite,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Server Configuration Section
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  child: _buildSectionHeader(
                    icon: FontAwesomeIcons.server,
                    title: 'Server Configuration',
                    color: const Color(0xFF6C63FF),
                  ),
                ),
                const SizedBox(height: 16),

                FadeInUp(
                  duration: const Duration(milliseconds: 700),
                  child: _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputField(
                          label: 'Ollama Server URL',
                          controller: _hostController,
                          hint: 'http://localhost:11434',
                          icon: FontAwesomeIcons.globe,
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          label: 'Model Name',
                          controller: _modelController,
                          hint: 'jayasimma/gennai',
                          icon: FontAwesomeIcons.brain,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Connection Test Section
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  duration: const Duration(milliseconds: 700),
                  child: _buildGlassCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  FontAwesomeIcons.wifi,
                                  color: Color(0xFF00D2FF),
                                  size: 16,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Connection Status',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            if (_isConnected != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (_isConnected!
                                              ? const Color(0xFF00E676)
                                              : const Color(0xFFFF6B6B))
                                          .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _isConnected! ? 'Connected' : 'Failed',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _isConnected!
                                        ? const Color(0xFF00E676)
                                        : const Color(0xFFFF6B6B),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isTesting ? null : _testConnection,
                            icon: _isTesting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF00D2FF),
                                    ),
                                  )
                                : const Icon(FontAwesomeIcons.bolt, size: 14),
                            label: Text(
                              _isTesting ? 'Testing...' : 'Test Connection',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF00D2FF),
                              side: const BorderSide(
                                color: Color(0xFF00D2FF),
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text(
                        'Save Settings',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Help Section
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: _buildSectionHeader(
                    icon: FontAwesomeIcons.circleQuestion,
                    title: 'Setup Guide',
                    color: const Color(0xFFFFB347),
                  ),
                ),
                const SizedBox(height: 16),
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStep(1, 'Install Ollama from ollama.com'),
                        _buildStep(2, 'Run: ollama serve'),
                        _buildStep(
                          3,
                          'Pull the model: ollama pull jayasimma/gennai',
                        ),
                        _buildStep(
                          4,
                          'Set the server URL above and test the connection',
                        ),
                        _buildStep(
                          5,
                          'Or switch to On-Device mode for offline use',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    bool isEnabled = true,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.1)
              : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color.withOpacity(0.4)
                : Colors.white.withOpacity(0.06),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(isEnabled ? 0.15 : 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isEnabled ? color : Colors.grey,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isEnabled ? Colors.white : Colors.white38,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isEnabled ? Colors.white54 : Colors.white24,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              )
            else
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isEnabled ? Colors.white24 : Colors.white10,
                    width: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5)),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
            prefixIcon: Icon(
              icon,
              color: Colors.white.withOpacity(0.3),
              size: 16,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF6C63FF),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF00D2FF)],
              ),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: child,
        ),
      ),
    );
  }
}
