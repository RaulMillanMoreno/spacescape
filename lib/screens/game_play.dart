import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:spacescape/widgets/overlays/game_over_menu.dart';
import 'package:spacescape/widgets/overlays/upgrades_menu.dart';

import '../game/game.dart';
import '../widgets/overlays/game_navBar_menu.dart'; // tu BottomNavBar
import '../widgets/overlays/pause_button.dart';
import '../widgets/overlays/pause_menu.dart';
import '../widgets/overlays/on_game_settings.dart';

class GamePlay extends StatefulWidget {
  const GamePlay({super.key});

  @override
  State<GamePlay> createState() => _GamePlayState();
}

class _GamePlayState extends State<GamePlay> {
  int? _currentIndex; // <- ahora es nullable
  late final SpacescapeGame _game;

  @override
  void initState() {
    super.initState();
    _game = SpacescapeGame();
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);

    _game.pauseEngine();

    // Mostramos el modal correspondiente según el índice
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _getPanelForIndex(index),
    ).then((_) {
      // Al cerrar el modal, se deselecciona la barra
      setState(() => _currentIndex = null);
      _game.resumeEngine();
    });
  }

  Widget _getPanelForIndex(int index) {
    switch (index) {
      case 0:
        return _buildMenuOverlay('Tienda');
      case 1:
        return const UpgradesMenu();
      case 2:
        return _buildMenuOverlay('Recruit');
      case 3:
        return const SettingsBottomSheet();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PopScope(
        canPop: false,
        child: GameWidget(
          game: _game,
          initialActiveOverlays: const [PauseButton.id],
          overlayBuilderMap: {
            PauseButton.id: (BuildContext context, SpacescapeGame game) =>
                PauseButton(game: game),
            PauseMenu.id: (BuildContext context, SpacescapeGame game) =>
                PauseMenu(game: game),
            GameOverMenu.id: (BuildContext context, SpacescapeGame game) =>
                GameOverMenu(game: game),
          },
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }

  // Panel simple para las opciones de compra/mejoras/etc
  Widget _buildMenuOverlay(String title) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aquí irá el contenido de $title...',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
