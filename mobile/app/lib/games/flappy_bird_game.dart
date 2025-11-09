import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class FlappyBirdGame extends FlameGame {
  @override
  Color backgroundColor() => const Color(0xFF4EC0CA);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Add game components here when implementing the actual game
  }
}
