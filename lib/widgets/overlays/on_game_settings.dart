import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spacescape/models/settings.dart';

class SettingsBottomSheet extends StatelessWidget {
  const SettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: const BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag indicator
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 32,
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  blurRadius: 20.0,
                  color: Colors.white24,
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Sound Effects Switch
          Selector<Settings, bool>(
            selector: (context, settings) => settings.soundEffects,
            builder: (context, value, child) {
              return SwitchListTile(
                title: const Text(
                  'Sound Effects',
                  style: TextStyle(color: Colors.white),
                ),
                activeColor: Colors.amber,
                value: value,
                onChanged: (newValue) {
                  Provider.of<Settings>(context, listen: false).soundEffects = newValue;
                },
              );
            },
          ),

          // Background Music Switch
          Selector<Settings, bool>(
            selector: (context, settings) => settings.backgroundMusic,
            builder: (context, value, child) {
              return SwitchListTile(
                title: const Text(
                  'Background Music',
                  style: TextStyle(color: Colors.white),
                ),
                activeColor: Colors.amber,
                value: value,
                onChanged: (newValue) {
                  Provider.of<Settings>(context, listen: false).backgroundMusic = newValue;
                },
              );
            },
          ),

          const SizedBox(height: 12),

          // Botón "Cerrar" amarillo con letras negras y sin icono
          SizedBox(
            width: MediaQuery.of(context).size.width / 3,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cerrar',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}