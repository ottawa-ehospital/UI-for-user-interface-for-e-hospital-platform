// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'dart:typed_data';
import 'recorder_interface.dart';

AudioRecorderInterface createRecorder() => WebRecorder();

class WebRecorder implements AudioRecorderInterface {
  html.MediaRecorder? _mediaRecorder;
  html.MediaStream? _stream;
  final List<html.Blob> _chunks = [];

  @override
  Future<bool> requestPermission() async {
    try {
      _stream = await html.window.navigator.mediaDevices!
          .getUserMedia({'audio': true, 'video': false});
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> startRecording() async {
    _chunks.clear();
    _stream ??= await html.window.navigator.mediaDevices!
        .getUserMedia({'audio': true, 'video': false});

    _mediaRecorder = html.MediaRecorder(_stream!, {'mimeType': 'audio/webm'});
    _mediaRecorder!.addEventListener('dataavailable', (event) {
      final blob = (event as html.BlobEvent).data;
      if (blob != null && blob.size > 0) _chunks.add(blob);
    });
    _mediaRecorder!.start();
  }

  @override
  Future<Uint8List> stopRecording() async {
    final completer = Completer<Uint8List>();
    _mediaRecorder!.addEventListener('stop', (_) {
      final blob = html.Blob(_chunks, 'audio/webm');
      final reader = html.FileReader();
      reader.readAsArrayBuffer(blob);
      reader.onLoadEnd.listen((_) {
        _stream?.getTracks().forEach((t) => t.stop());
        _stream = null;
        completer.complete(reader.result as Uint8List);
      });
    });
    _mediaRecorder!.stop();
    return completer.future;
  }

  @override
  void dispose() => _stream?.getTracks().forEach((t) => t.stop());
}