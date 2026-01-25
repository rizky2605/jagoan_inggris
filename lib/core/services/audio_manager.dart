// lib/core/services/audio_manager.dart

import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  // Singleton Pattern (Agar hanya ada 1 pengelola audio di seluruh aplikasi)
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  // Status Settingan (Default: Nyala)
  bool isMusicOn = true;
  bool isSfxOn = true;

  // --- FUNGSI BGM (Musik Latar) ---
  Future<void> initBgm() async {
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop); // Loop terus
    if (isMusicOn) {
      await playBgm();
    }
  }

  Future<void> playBgm() async {
    if (!isMusicOn) return;
    if (_bgmPlayer.state == PlayerState.playing) return; // Jangan play kalau sudah nyala

    await _bgmPlayer.setVolume(0.5); // Volume 50%
    await _bgmPlayer.play(AssetSource('audio/bgm.mp3'));
  }

  Future<void> stopBgm() async {
    await _bgmPlayer.stop();
  }

  Future<void> toggleMusic(bool value) async {
    isMusicOn = value;
    if (isMusicOn) {
      await playBgm();
    } else {
      await stopBgm();
    }
  }

  // --- FUNGSI SFX (Efek Suara) ---
  Future<void> playClick() async {
    if (!isSfxOn) return; // Kalau dimatikan, jangan bunyi
    
    if (_sfxPlayer.state == PlayerState.playing) {
      await _sfxPlayer.stop(); // Reset biar responsif kalau diklik cepat
    }
    await _sfxPlayer.play(AssetSource('audio/click.mp3'));
  }

  void toggleSfx(bool value) {
    isSfxOn = value;
  }
  
  // Membersihkan player saat aplikasi ditutup total
  void dispose() {
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
  }
}