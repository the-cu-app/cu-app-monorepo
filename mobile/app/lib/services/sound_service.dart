import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _soundEnabled = true;

  // Initialize sound service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('sound_enabled') ?? true;
  }

  // Toggle sound on/off
  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', _soundEnabled);
  }

  bool get isSoundEnabled => _soundEnabled;

  // Button tap sound
  void playButtonTap() {
    if (!_soundEnabled) return;
    HapticFeedback.lightImpact();
    _playSystemSound();
  }

  // Success sound (for completed transactions, login, etc.)
  void playSuccess() {
    if (!_soundEnabled) return;
    HapticFeedback.mediumImpact();
    _playSystemSound();
  }

  // Error sound
  void playError() {
    if (!_soundEnabled) return;
    HapticFeedback.heavyImpact();
    _playSystemSound();
  }

  // Navigation sound
  void playNavigation() {
    if (!_soundEnabled) return;
    HapticFeedback.selectionClick();
  }

  // Money transfer sound
  void playTransfer() {
    if (!_soundEnabled) return;
    HapticFeedback.mediumImpact();
    _playSystemSound();
  }

  // Notification sound
  void playNotification() {
    if (!_soundEnabled) return;
    HapticFeedback.lightImpact();
    _playSystemSound();
  }

  // Card swipe sound
  void playCardSwipe() {
    if (!_soundEnabled) return;
    HapticFeedback.selectionClick();
  }

  // Account selection sound
  void playAccountSelect() {
    if (!_soundEnabled) return;
    HapticFeedback.selectionClick();
  }

  // Balance reveal sound
  void playBalanceReveal() {
    if (!_soundEnabled) return;
    HapticFeedback.lightImpact();
  }

  // QR code scan sound
  void playQRScan() {
    if (!_soundEnabled) return;
    HapticFeedback.mediumImpact();
    _playSystemSound();
  }

  // Biometric auth sound
  void playBiometric() {
    if (!_soundEnabled) return;
    HapticFeedback.lightImpact();
  }

  // Pull to refresh sound
  void playRefresh() {
    if (!_soundEnabled) return;
    HapticFeedback.lightImpact();
  }

  // Achievement/milestone sound
  void playAchievement() {
    if (!_soundEnabled) return;
    HapticFeedback.mediumImpact();
    _playSystemSound();
  }

  // Private method to play system sounds
  void _playSystemSound() {
    // Use system sounds for now - can be replaced with custom sounds later
    SystemSound.play(SystemSoundType.click);
  }

  // Method to play custom sound files (for future enhancement)
  Future<void> _playCustomSound(String soundPath) async {
    try {
      await _audioPlayer.play(AssetSource(soundPath));
    } catch (e) {
      // Fallback to system sound if custom sound fails
      _playSystemSound();
    }
  }

  // Dispose resources
  void dispose() {
    _audioPlayer.dispose();
  }
}