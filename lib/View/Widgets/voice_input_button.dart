import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';

import '../../Service/stt_service.dart';
import '../../Service/recorder/recorder_stub.dart'
    if (dart.library.io) '../../Service/recorder/recorder_native.dart'
    if (dart.library.html) '../../Service/recorder/recorder_web.dart';

class VoiceInputButton extends StatefulWidget {
  final SttService sttService;
  final TextEditingController textController; 
  final void Function(String transcript)? onTranscribed;  

  const VoiceInputButton({
    super.key,
    required this.sttService,
    required this.textController,
    this.onTranscribed,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  final _recorder = createRecorder();
  bool _isListening = false;
  bool _isProcessing = false;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  Future<void> _start() async {
    final granted = await _recorder.requestPermission();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
      }
      return;
    }
    await _recorder.startRecording();
    setState(() => _isListening = true);
  }

  Future<void> _stop() async {
    setState(() { _isListening = false; _isProcessing = true; });

    try {
      final result = await _recorder.stopRecording();
      final transcript = kIsWeb
          ? await widget.sttService.transcribeBytes(result as Uint8List)
          : await widget.sttService.transcribeFile(result as String);

      if (transcript != null && transcript.isNotEmpty) {
        widget.textController.text = transcript;
        widget.onTranscribed?.call(transcript);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voice input failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing) {
      return const SizedBox(
        width: 44, height: 44,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return GestureDetector(
      onTapDown: kIsWeb ? null : (_) => _start(),
      onTapUp:   kIsWeb ? null : (_) => _stop(),
      onTap:     kIsWeb ? (_isListening ? _stop : _start) : null,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) => Transform.scale(
          scale: _isListening ? 1.0 + _pulse.value * 0.12 : 1.0,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isListening ? Colors.red.shade500 : const Color(0xFF1A73E8),
              boxShadow: _isListening
                  ? [BoxShadow(color: Colors.red.withOpacity(0.35), blurRadius: 10, spreadRadius: 3)]
                  : [],
            ),
            child: Icon(
              _isListening ? Icons.stop_rounded : Icons.mic_rounded,
              color: Colors.white, size: 20,
            ),
          ),
        ),
      ),
    );
  }
}