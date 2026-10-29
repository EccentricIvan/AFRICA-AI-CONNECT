import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'voice_service.dart';

final voiceServiceProvider = Provider<VoiceService>((ref) {
  final service = VoiceService();
  service.onSpeakingChanged = (text) {
    ref.read(voiceSpeakingProvider.notifier).state = text;
  };
  ref.onDispose(service.dispose);
  return service;
});

final voiceListeningProvider = StateProvider<bool>((ref) => false);

final voiceSpeakingProvider = StateProvider<String?>((ref) => null);
