import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  String _currentLocaleId = '';
  final _textController = StreamController<String>.broadcast();
  final _statusController = StreamController<String>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _listeningController = StreamController<bool>.broadcast();

  Stream<String> get textStream => _textController.stream;
  Stream<String> get statusStream => _statusController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<bool> get listeningStream => _listeningController.stream;

  bool get isListening => _speechToText.isListening;
  bool get isEnabled => _speechEnabled;
  String get lastWords => _lastWords;

  Future<bool> initialize() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onStatus: _statusListener,
        onError: _errorListener,
      );

      if (_speechEnabled) {
        final systemLocale = await _speechToText.systemLocale();
        _currentLocaleId = systemLocale?.localeId ?? '';
      }

      return _speechEnabled;
    } catch (e) {
      _errorController.add('Error initializing speech: $e');
      return false;
    }
  }

  void startListening() {
    if (!_speechEnabled) return;

    _lastWords = '';
    _listeningController.add(true);

    _speechToText.listen(
      onResult: _resultListener,
      localeId: _currentLocaleId,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.confirmation,
      ),
    );
  }

  void stopListening() {
    _speechToText.stop();
    _listeningController.add(false);
  }

  void _resultListener(dynamic result) {
    _lastWords = result.recognizedWords;
    _textController.add(_lastWords);
  }

  void _statusListener(String status) {
    _statusController.add(status);
    if (status == 'notListening') {
      _listeningController.add(false);
    }
  }

  void _errorListener(dynamic error) {
    _errorController.add('Error: ${error.errorMsg}');
  }

  void dispose() {
    _textController.close();
    _statusController.close();
    _errorController.close();
    _listeningController.close();
  }
}
