import 'dart:typed_data';

abstract class AudioRecorderInterface {
  Future<bool> requestPermission();
  Future<void> startRecording();
  Future<dynamic> stopRecording(); // String (native) | Uint8List (web)
  void dispose();
}