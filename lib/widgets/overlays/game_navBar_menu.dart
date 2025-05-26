import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';

typedef NavTapCallback = void Function(int index);

class BottomNavBar extends StatelessWidget {
  final int? currentIndex;
  final NavTapCallback onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, const ImageIcon(AssetImage('assets/images/espadas.png')), 'Tienda'),
          _buildNavItem(1, ImageIcon(AssetImage('assets/images/upgrade_logo.png')), 'Mejoras'),
          _buildNavItem(2, ImageIcon(AssetImage('assets/images/recruit.png')), 'Recruit'),
          _buildNavItem(3, const ImageIcon(AssetImage('assets/images/settings.png')), 'Settings'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, Widget icon, String label) {
    final isSelected = currentIndex == index;
    return InkWell(
      onTap: () => onTap(index),
      child: Container(
        width: 70,
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.black.withOpacity(0.5) : Colors.transparent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconTheme(
              data: IconThemeData(
                color: isSelected ? Colors.amber : Colors.white70,
                size: 24,
              ),
              child: icon,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.amber : Colors.white70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
