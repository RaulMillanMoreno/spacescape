import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:spacescape/widgets/overlays/game_over_menu.dart';

import '../game/game.dart';
import '../widgets/overlays/game_navBar_menu.dart'; // Importa el widget de barra de navegación
import '../widgets/overlays/pause_button.dart';
import '../widgets/overlays/pause_menu.dart';

class GamePlay extends StatefulWidget {
  const GamePlay({super.key});

  @override
  State<GamePlay> createState() => _GamePlayState();
}

class _GamePlayState extends State<GamePlay> {
  int _currentIndex = 0;
  late final SpacescapeGame _game;

  @override
  void initState() {
    super.initState();
    _game = SpacescapeGame();
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
    
    // Gestión de overlays según la tab seleccionada
    if (index == 0) {
      // Modo juego - Solo muestra los controles del juego
      _game.resumeEngine();
      _game.overlays.remove('ShopMenu');
      _game.overlays.remove('StatsMenu');
      _game.overlays.remove('InventoryMenu');
    } else {
      // Pausa el juego cuando se navega a otras pestañas
      _game.pauseEngine();
      
      // Limpia overlays anteriores
      _game.overlays.remove('ShopMenu');
      _game.overlays.remove('StatsMenu');
      _game.overlays.remove('InventoryMenu');
      
      // Activa el overlay correspondiente
      switch (index) {
        case 1:
          _game.overlays.add('ShopMenu');
          break;
        case 2:
          _game.overlays.add('StatsMenu');
          break;
        case 3:
          _game.overlays.add('InventoryMenu');
          break;
      }
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
            'ShopMenu': (BuildContext context, SpacescapeGame game) => 
                _buildMenuOverlay('Tienda'),
            'StatsMenu': (BuildContext context, SpacescapeGame game) => 
                _buildMenuOverlay('Estadísticas'),
            'InventoryMenu': (BuildContext context, SpacescapeGame game) => 
                _buildMenuOverlay('Inventario'),
          },
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
  
  // Widget auxiliar para crear overlays de menú
  Widget _buildMenuOverlay(String title) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Contenido de $title',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}