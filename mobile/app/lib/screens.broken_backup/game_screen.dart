import 'package:flutter/material.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'package:flame/game.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import '../games/flappy_bird_game.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'CU.APP Game Zone',
          style: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: GameWidget(game: FlappyBirdGame()),
        ),
      ),
    );
  }
}