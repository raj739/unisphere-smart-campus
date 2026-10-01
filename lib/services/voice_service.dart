import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  final stt.SpeechToText speech = stt.SpeechToText();
  final FlutterTts tts = FlutterTts();

  bool isInitialized = false;
  bool isListening = false;
  bool isSpeaking = false;

  // ===========================================================================
  // INITIALIZE
  // ===========================================================================

  Future<bool> initialize() async {
    if (isInitialized) {
      return true;
    }

    try {
      isInitialized = await speech.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');

          if (status == 'done' || status == 'notListening') {
            isListening = false;
          }
        },
        onError: (error) {
          debugPrint('Speech error: $error');
          isListening = false;
        },
      );

      // -----------------------------------------------------------------------
      // TEXT TO SPEECH SETTINGS
      // -----------------------------------------------------------------------

      await tts.setLanguage('en-IN');
      await tts.setSpeechRate(0.48);
      await tts.setVolume(1.0);
      await tts.setPitch(1.0);

      // Track TTS state.
      tts.setStartHandler(() {
        isSpeaking = true;
      });

      tts.setCompletionHandler(() {
        isSpeaking = false;
      });

      tts.setCancelHandler(() {
        isSpeaking = false;
      });

      tts.setErrorHandler((message) {
        debugPrint('TTS error: $message');
        isSpeaking = false;
      });

      return isInitialized;
    } catch (e) {
      debugPrint('Voice initialization error: $e');

      isInitialized = false;

      return false;
    }
  }

  // ===========================================================================
  // START LISTENING
  // ===========================================================================

  Future<bool> startListening({
    required Function(String text) onResult,
    String localeId = 'en_IN',
  }) async {
    try {
      // Stop TTS before listening.
      if (isSpeaking) {
        await stopSpeaking();
      }

      final available = await initialize();

      if (!available) {
        return false;
      }

      // Stop any existing recognition session.
      if (isListening) {
        await stopListening();
      }

      final resolvedLocale = await _resolveLocale(localeId);
      isListening = true;

      await speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords);

          if (result.finalResult) {
            isListening = false;
          }
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
          localeId: resolvedLocale,
        ),
      );

      return true;
    } catch (e) {
      debugPrint('Start listening error: $e');

      isListening = false;

      return false;
    }
  }

  Future<String?> _resolveLocale(String requestedLocale) async {
    final requested = requestedLocale.replaceAll('-', '_').toLowerCase();
    final requestedLanguage = requested.split('_').first;
    final locales = await speech.locales();

    for (final locale in locales) {
      if (locale.localeId.replaceAll('-', '_').toLowerCase() == requested) {
        return locale.localeId;
      }
    }
    for (final locale in locales) {
      if (locale.localeId.toLowerCase().startsWith(requestedLanguage)) {
        return locale.localeId;
      }
    }
    return null;
  }

  // ===========================================================================
  // STOP LISTENING
  // ===========================================================================

  Future<void> stopListening() async {
    try {
      await speech.stop();
    } catch (e) {
      debugPrint('Stop listening error: $e');
    } finally {
      isListening = false;
    }
  }

  // ===========================================================================
  // CANCEL LISTENING
  // ===========================================================================

  Future<void> cancelListening() async {
    try {
      await speech.cancel();
    } catch (e) {
      debugPrint('Cancel listening error: $e');
    } finally {
      isListening = false;
    }
  }

  // ===========================================================================
  // TEXT TO SPEECH
  // ===========================================================================

  Future<void> speak(String text, {String? languageCode}) async {
    if (text.trim().isEmpty) {
      return;
    }

    try {
      // Stop speech recognition before speaking.
      if (isListening) {
        await stopListening();
      }

      // Stop previous speech.
      if (isSpeaking) {
        await stopSpeaking();
      }

      await initialize();

      if (languageCode != null) {
        await tts.setLanguage(languageCode);
      }

      isSpeaking = true;

      await tts.speak(text);
    } catch (e) {
      debugPrint('Speak error: $e');

      isSpeaking = false;
    }
  }

  // ===========================================================================
  // STOP SPEAKING
  // ===========================================================================

  Future<void> stopSpeaking() async {
    try {
      await tts.stop();
    } catch (e) {
      debugPrint('Stop speaking error: $e');
    } finally {
      isSpeaking = false;
    }
  }

  // ===========================================================================
  // PAUSE SPEAKING
  // ===========================================================================

  Future<void> pauseSpeaking() async {
    try {
      await tts.pause();
    } catch (e) {
      debugPrint('Pause speaking error: $e');
    }
  }

  // ===========================================================================
  // RESUME SPEAKING
  // ===========================================================================

  Future<void> resumeSpeaking() async {
    try {
      await tts.speak('');
    } catch (e) {
      debugPrint('Resume speaking error: $e');
    }
  }

  // ===========================================================================
  // CHANGE LANGUAGE
  // ===========================================================================

  Future<void> setLanguage(String languageCode) async {
    try {
      await tts.setLanguage(languageCode);
    } catch (e) {
      debugPrint('TTS language error: $e');
    }
  }

  // ===========================================================================
  // CLEANUP
  // ===========================================================================

  Future<void> dispose() async {
    try {
      await stopListening();
      await stopSpeaking();
    } catch (e) {
      debugPrint('Voice service dispose error: $e');
    }
  }
}
