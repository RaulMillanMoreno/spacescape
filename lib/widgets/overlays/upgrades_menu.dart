import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/player_data.dart';
import '../../models/upgrade_system.dart';

class UpgradesMenu extends StatelessWidget {
  const UpgradesMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerData>(
      builder: (context, playerData, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: const BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicador de arrastre
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              
              const Text(
                'Mejoras',
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Dinero: ${playerData.money}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: ListView(
                  children: Upgrade.upgrades.entries.map((entry) {
                    final type = entry.key;
                    final upgrade = entry.value;
                    final currentLevel = playerData.upgrades.getUpgradeLevel(type);
                    final nextCost = upgrade.getCostForLevel(currentLevel + 1);
                    final canBuy = playerData.upgrades.canUpgrade(type, playerData.money);

                    String getStatValue() {
                      switch (type) {
                        case UpgradeType.damage:
                          return '+${(currentLevel * 20)}% daño';
                        case UpgradeType.health:
                          return '+${(currentLevel * 25)}% vida';
                        case UpgradeType.speed:
                          return '+${(currentLevel * 15)}% velocidad';
                        case UpgradeType.powerUpDuration:
                          return '+${(currentLevel * 30)}% duración';
                        case UpgradeType.moneyMultiplier:
                          return '+${(currentLevel * 20)}% dinero';
                        default:
                          return '';
                      }
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white24,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  upgrade.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                'Nivel ${currentLevel}/${upgrade.maxLevel}',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            upgrade.description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            getStatValue(),
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          ),
                          if (currentLevel < upgrade.maxLevel) ...[
                            const SizedBox(height: 6),
                            SizedBox(
                              width: double.infinity,
                              height: 28, // Altura fija para el botón
                              child: ElevatedButton(
                                onPressed: canBuy 
                                  ? () => playerData.upgrades.purchaseUpgrade(type, playerData)
                                  : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.black,
                                  disabledBackgroundColor: Colors.amber.withOpacity(0.3),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                child: Text(
                                  'Mejorar: $nextCost',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ] else
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text(
                                'NIVEL MÁXIMO',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}