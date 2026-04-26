import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'recorder_interface.dart';

AudioRecorderInterface createRecorder() => NativeRecorder();

class NativeRecorder implements AudioRecorderInterface {
  final AudioRecorder _recorder = AudioRecorder();

  @override
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  @override
  Future<void> startRecording() async {
    final dir = await getTemporaryDirectory();
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
      path: '${dir.path}/voice_input.m4a',
    );
  }

  @override
  Future<String?> stopRecording() => _recorder.stop();

  @override
  void dispose() => _recorder.dispose();
}