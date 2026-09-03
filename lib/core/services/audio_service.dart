import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Trigger haptic feedback (light click)
  Future<void> clickFeedback() async {
    await HapticFeedback.lightImpact();
  }

  /// Trigger haptic feedback for completion (vibrate / medium / selection)
  Future<void> completionFeedback() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }

  /// Play local audio asset
  Future<void> playAsset(String assetPath) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (_) {}
  }

  /// Stop any audio playing
  Future<void> stopAudio() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
