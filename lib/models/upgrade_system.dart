import 'package:flutter/foundation.dart';
import 'player_data.dart';

enum UpgradeType {
  damage,
  health,
  speed,
  bulletSpeed,
  powerUpDuration,
  moneyMultiplier
}

class Upgrade {
  final String name;
  final String description;
  final int baseValue;
  final int baseCost;
  final double scaling;
  final int maxLevel;

  const Upgrade({
    required this.name,
    required this.description,
    required this.baseValue,
    required this.baseCost,
    required this.scaling,
    required this.maxLevel,
  });

  int getCostForLevel(int currentLevel) {
    return (baseCost * (scaling * currentLevel)).round();
  }

  int getValueForLevel(int level) {
    return baseValue * level;
  }

static const Map<UpgradeType, Upgrade> upgrades = {
    UpgradeType.damage: Upgrade(
      name: 'Daño',
      description: 'Aumenta el daño de las balas',
      baseValue: 10,
      baseCost: 1,
      scaling: 1.0,
      maxLevel: 5,
    ),
    UpgradeType.health: Upgrade(
      name: 'Vida',
      description: 'Aumenta la vida máxima',
      baseValue: 50, // Aumentado para ser más notable
      baseCost: 1,
      scaling: 1.0,
      maxLevel: 4,
    ),
    UpgradeType.speed: Upgrade(
      name: 'Velocidad',
      description: 'Aumenta la velocidad de la nave',
      baseValue: 100, // Aumentado para ser más notable
      baseCost: 1,
      scaling: 1.0,
      maxLevel: 3,
    ),
    UpgradeType.bulletSpeed: Upgrade(
      name: 'Cadencia',
      description: 'Aumenta la velocidad de disparo',
      baseValue: 30, // Aumentado para ser más notable
      baseCost: 1,
      scaling: 1.0,
      maxLevel: 4,
    ),
    UpgradeType.powerUpDuration: Upgrade(
      name: 'Duración Power-Ups',
      description: 'Aumenta la duración de los power-ups',
      baseValue: 5, // Aumentado para ser más notable
      baseCost: 1,
      scaling: 1.0,
      maxLevel: 3,
    ),
    UpgradeType.moneyMultiplier: Upgrade(
      name: 'Multiplicador de dinero',
      description: 'Aumenta el dinero ganado',
      baseValue: 20, // Aumentado para ser más notable
      baseCost: 1,
      scaling: 1.0,
      maxLevel: 3,
    ),
  };
}

class PlayerUpgrades extends ChangeNotifier {
  final Map<UpgradeType, int> upgradeLevels = {};

  

  int getUpgradeLevel(UpgradeType type) {
    return upgradeLevels[type] ?? 0;
  }

  bool canUpgrade(UpgradeType type, int playerMoney) {
    final upgrade = Upgrade.upgrades[type]!;
    final currentLevel = getUpgradeLevel(type);
    
    if (currentLevel >= upgrade.maxLevel) return false;
    
    return playerMoney >= upgrade.getCostForLevel(currentLevel + 1);
  }

  void purchaseUpgrade(UpgradeType type, PlayerData playerData) {
    final upgrade = Upgrade.upgrades[type]!;
    final currentLevel = getUpgradeLevel(type);
    final cost = upgrade.getCostForLevel(currentLevel + 1);

    if (playerData.money >= cost && currentLevel < upgrade.maxLevel) {
      playerData.money -= cost;
      upgradeLevels[type] = currentLevel + 1;
      
      // Notificar cambios
      notifyListeners();
      playerData.notifyListeners();
      
      // Guardar cambios
      playerData.save();
    }
  }
}