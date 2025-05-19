import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'enemy.dart';

// This component represent a bullet in game world.
class Bullet extends SpriteComponent with CollisionCallbacks {
  // Speed of the bullet.
  final double _speed = 450;

  // Controls the direction in which bullet travels.
  Vector2 direction = Vector2(0, -1);

  // Level of this bullet. Essentially represents the
  // level of spaceship that fired this bullet.
  int level;
  int damageMultiplier;
  Paint? customPaint;

  Bullet({
    required super.sprite,
    required super.position,
    required super.size,
    this.level = 1,
    this.damageMultiplier = 1,
    this.customPaint,
  });

  @override
  void onMount() {
    super.onMount();

    // Adding a circular hitbox with radius as 0.4 times
    //  the smallest dimension of this components size.
    final shape = CircleHitbox.relative(
      0.4,
      parentSize: size,
      position: size / 2,
      anchor: Anchor.center,
    );
    add(shape);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    // If the other Collidable is Enemy, remove this bullet.
    if (other is Enemy) {
      removeFromParent();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Moves the bullet to a new position with _speed and direction.
    position += direction * _speed * dt;

    // If bullet crosses the upper boundary of screen
    // mark it to be removed it from the game world.
    if (position.y < 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // Usa el paint personalizado si está activo, si no, el normal
    if (customPaint != null) {
      canvas.save();
      canvas.drawImageRect(
        sprite!.image,
        sprite!.srcPosition & sprite!.srcSize,
        size.toRect(),
        customPaint!,
      );
      canvas.restore();
    } else {
      super.render(canvas);
    }
  }
}
