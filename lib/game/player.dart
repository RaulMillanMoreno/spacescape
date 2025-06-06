import 'dart:math';

import 'package:flame/collisions.dart';
// import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flame/components.dart';
// import 'package:flame_noise/flame_noise.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spacescape/models/upgrade_system.dart';

import '../models/player_data.dart';
import '../models/spaceship_details.dart';

import 'game.dart';
import 'enemy.dart';
import 'bullet.dart';
import 'command.dart';
import 'audio_player_component.dart';

// This component class represents the player character in game.
class Player extends SpriteComponent
    with CollisionCallbacks, HasGameReference<SpacescapeGame>, KeyboardHandler {
  // Player joystick
  JoystickComponent joystick;

  // Player health.
  int _health = 100;
  int get health => _health;

  // Details of current spaceship.
  Spaceship _spaceship;

  // Type of current spaceship.
  SpaceshipType spaceshipType;

  PlayerData? _playerData;
  int get score => _playerData!.currentScore;
  bool get isReady => isMounted && _playerData != null;

  // If true, player will shoot 3 bullets at a time.
  bool _shootMultipleBullets = false;

  // Controls for how long multi-bullet power up is active.
  late Timer _powerUpTimer;

  // If true, shield is active.
  bool _shieldActive = false;

  // Controls for how long shield is active.
  late Timer _shieldTimer;

  // If true, speed power-up is active.
  bool _speedActive = false;

  // Controls for how long speed power-up is active.
  late Timer _speedTimer;

  // If true, damage boost is active.
  bool _damageBoostActive = false;

  // Controls for how long damage boost is active.
  late Timer _damageBoostTimer;

  // Timer for auto-firing bullets
  late Timer _autoFireTimer;

  // Timer for thruster particles
  late Timer _thrusterTimer;

  // Holds an object of Random class to generate random numbers.
  final _random = Random();

  // Multiplicadores de mejoras
  double _damageMultiplier = 1.0;
  double _healthMultiplier = 1.0;
  double _speedMultiplier = 1.0;
  double _powerUpDurationMultiplier = 1.0;
  double _moneyMultiplier = 1.0;

  // This method generates a random vector such that
  // its x component lies between [-100 to 100] and
  // y component lies between [200, 400]
  Vector2 getRandomVector() {
    return (Vector2.random(_random) - Vector2(0.5, -1)) * 200;
  }

  Player({
    required this.joystick,
    required this.spaceshipType,
    super.sprite,
    super.position,
    super.size,
  }) : _spaceship = Spaceship.getSpaceshipByType(spaceshipType) {
    // Sets power up timer to 4 seconds. After 4 seconds,
    // multiple bullet will get deactivated.
    _powerUpTimer = Timer(
      4,
      onTick: () {
        _shootMultipleBullets = false;
      },
    );

    // Sets shield timer to 10 seconds. After 10 seconds,
    // shield will get deactivated.
    _shieldTimer = Timer(
      10,
      onTick: () {
        _shieldActive = false;
      },
    );

    // Sets speed timer to 5 seconds. After 5 seconds,
    // speed power-up will get deactivated.
    _speedTimer = Timer(
      5,
      onTick: () {
        _speedActive = false;
      },
    );

    // Sets damage boost timer to 10 seconds. After 10 seconds,
    // damage boost will get deactivated.
    _damageBoostTimer = Timer(
      10,
      onTick: () {
        _damageBoostActive = false;
      },
    );

    _autoFireTimer = Timer(
      0.6, // Antes era 0.2, ahora es más lento
      repeat: true,
      onTick: () {
        joystickAction();
      },
    );

    _thrusterTimer = Timer(
      0.1, // cada 0.1 segundos
      repeat: true,
      onTick: () {
        final particleComponent = ParticleSystemComponent(
          particle: Particle.generate(
            count: 3,
            lifespan: 0.07,
            generator: (i) => AcceleratedParticle(
              acceleration: getRandomVector(),
              speed: getRandomVector(),
              position: (position.clone() + Vector2(0, size.y / 3)),
              child: CircleParticle(
                radius: 1,
                paint: Paint()
                  ..color =
                      _speedActive ? const Color(0xFF2196F3) : Colors.white,
              ),
            ),
          ),
        );
        game.world.add(particleComponent);
      },
    );
  }

  @override
  void onMount() {
    super.onMount();

    // Adding a circular hitbox with radius as 0.8 times
    // the smallest dimension of this components size.
    final shape = CircleHitbox.relative(
      0.8,
      parentSize: size,
      position: size / 2,
      anchor: Anchor.center,
    );
    add(shape);
    _autoFireTimer.start();
    _thrusterTimer.start();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Enemy) {
      if (!_shieldActive) {
        _health -= 10;
        print('Vida actual: $_health');
        if (_health <= 0) {
          die();
        }
      } else {
        print('¡Escudo activo! No se recibe daño.');
      }
      // Siempre destruye el enemigo al colisionar
      other.destroy();
    }
    // ...otros casos...
  }

  Vector2 keyboardDelta = Vector2.zero();
  static final _keysWatched = {
    LogicalKeyboardKey.keyW,
    LogicalKeyboardKey.keyA,
    LogicalKeyboardKey.keyS,
    LogicalKeyboardKey.keyD,
    LogicalKeyboardKey.space,
  };

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // Set this to zero first - if the user releases all keys pressed, then
    // the set will be empty and our vector non-zero.
    keyboardDelta.setZero();

    if (!_keysWatched.contains(event.logicalKey)) return true;

    if (event is KeyDownEvent &&
        event is! KeyRepeatEvent &&
        event.logicalKey == LogicalKeyboardKey.space) {
      // pew pew!
      joystickAction();
    }

    if (keysPressed.contains(LogicalKeyboardKey.keyW)) {
      keyboardDelta.y = -1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyA)) {
      keyboardDelta.x = -1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyS)) {
      keyboardDelta.y = 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyD)) {
      keyboardDelta.x = 1;
    }

    // Handled keyboard input
    return false;
  }

  // This method is called by game class for every frame.
  @override
  void update(double dt) {
    super.update(dt);

    _powerUpTimer.update(dt);
    _shieldTimer.update(dt);
    _speedTimer.update(dt);
    _damageBoostTimer.update(dt);
    _autoFireTimer.update(dt);
    _thrusterTimer.update(dt);

     double speedMultiplier = (_speedActive ? 2.0 : 1.0) * _speedMultiplier;

    if (!joystick.delta.isZero()) {
      position.add(
          joystick.relativeDelta * _spaceship.speed * speedMultiplier * dt);
    }

    if (!keyboardDelta.isZero()) {
      position.add(keyboardDelta * _spaceship.speed * speedMultiplier * dt);
    }

    // Clamp position of player such that the player sprite does not go outside the screen size.
    position.clamp(Vector2.zero() + size / 2, game.fixedResolution - size / 2);

    // Adds thruster particles.
    final particleComponent = ParticleSystemComponent(
      particle: Particle.generate(
        count: 3,
        lifespan: 0.07,
        generator: (i) => AcceleratedParticle(
          acceleration: getRandomVector(),
          speed: getRandomVector(),
          position: (position.clone() + Vector2(0, size.y / 3)),
          child: CircleParticle(
            radius: 1,
            paint: Paint()
              ..color = _speedActive
                  ? const Color(0xFF2196F3) // Azul
                  : Colors.white,
          ),
        ),
      ),
    );

    game.world.add(particleComponent);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_shieldActive) {
      final paint = Paint()
        ..color = const Color.fromARGB(255, 46, 176, 205)
            .withOpacity(0.5); // Azul cielo translúcido

      // Dibuja un semicírculo en la parte superior de la nave
      final rect = Rect.fromLTWH(0, 0, size.x, size.y);
      // startAngle = pi, sweepAngle = pi para la mitad superior
      canvas.drawArc(rect, pi, pi, true, paint);
    }
  }

void setPlayerData(PlayerData playerData) {
    _playerData = playerData;
    // Update the current spaceship type of player.
    _setSpaceshipType(playerData.spaceshipType);
    
    // Aplicar las mejoras
    _applyUpgrades();
}

void _applyUpgrades() {
    if (_playerData == null) return;

    // Reiniciar multiplicadores
    _damageMultiplier = 1.0;
    _healthMultiplier = 1.0;
    _speedMultiplier = 1.0;
    _powerUpDurationMultiplier = 1.0;
    _moneyMultiplier = 1.0;

    // Aplicar mejoras de daño
    final damageLevel = _playerData!.upgrades.getUpgradeLevel(UpgradeType.damage);
    if (damageLevel > 0) {
        _damageMultiplier = 1.0 + (damageLevel * 0.5); // +50% por nivel
    }

    // Aplicar mejoras de vida
    final healthLevel = _playerData!.upgrades.getUpgradeLevel(UpgradeType.health);
    if (healthLevel > 0) {
        _healthMultiplier = 1.0 + (healthLevel * 0.5); // +50% por nivel
        _health = (100 * _healthMultiplier).round();
    }

    // Aplicar mejoras de velocidad
    final speedLevel = _playerData!.upgrades.getUpgradeLevel(UpgradeType.speed);
    if (speedLevel > 0) {
        _speedMultiplier = 1.0 + (speedLevel * 0.3); // +30% por nivel
    }

    // Aplicar mejoras de duración de power-ups
    final powerUpLevel = _playerData!.upgrades.getUpgradeLevel(UpgradeType.powerUpDuration);
    if (powerUpLevel > 0) {
        _powerUpDurationMultiplier = 1.0 + (powerUpLevel * 0.5); // +50% por nivel
    }

    // Aplicar mejoras de multiplicador de dinero
    final moneyLevel = _playerData!.upgrades.getUpgradeLevel(UpgradeType.moneyMultiplier);
    if (moneyLevel > 0) {
        _moneyMultiplier = 1.0 + (moneyLevel * 0.5); // +50% por nivel
    }
}

  double _lastShotSfx = 0;

  final List<String> _shotSounds = [
    'laserSmall_001.ogg',
    'laserSmall_002.ogg',
    'laserSmall_003.ogg',
  ];
  int _shotSoundIndex = 0;

  void joystickAction() {
    final isDamageBoost = _damageBoostActive;
    final paint = isDamageBoost
        ? (Paint()
          ..colorFilter = const ColorFilter.mode(
              Color.fromARGB(255, 154, 6, 156), BlendMode.modulate))
        : null;

    Bullet bullet = Bullet(
      sprite: game.spriteSheet.getSpriteById(28),
      size: Vector2(64, 64),
      position: position.clone(),
      level: _spaceship.level,
      damageMultiplier: isDamageBoost ? (3 * _damageMultiplier).round() : _damageMultiplier.round(),
      customPaint: paint,
    );

    bullet.anchor = Anchor.center;
    game.world.add(bullet);

    // --- CONTROL DE COOLDOWN PARA SONIDO ---
    // final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    // if (now - _lastShotSfx > 0.15) {
    //   final sound = _shotSounds[_shotSoundIndex];
    //   game.addCommand(
    //     Command<AudioPlayerComponent>(
    //       action: (audioPlayer) {
    //         audioPlayer.playSfx(sound);
    //       },
    //     ),
    //   );
    //   _shotSoundIndex = (_shotSoundIndex + 1) % _shotSounds.length;
    //   _lastShotSfx = now;
    // }
    // --- FIN CONTROL DE COOLDOWN ---

    // If multiple bullet is on, add two more
    // bullets rotated +-PI/6 radians to first bullet.
    if (_shootMultipleBullets) {
      for (int i = -1; i < 2; i += 2) {
        Bullet bullet = Bullet(
          sprite: game.spriteSheet.getSpriteById(28),
          size: Vector2(64, 64),
          position: position.clone(),
          level: _spaceship.level,
        );

        // Anchor it to center and add to game world.
        bullet.anchor = Anchor.center;
        bullet.direction.rotate(i * pi / 6);
        game.world.add(bullet);
      }
    }
  }

  // Adds given points to player score
  /// and also add it to [PlayerData.money].
void addToScore(int points) {
    _playerData!.currentScore += points;
    _playerData!.money += (points * _moneyMultiplier).round();

    // Saves player data to disk.
    _playerData!.save();
}
  

  // Increases health by give amount.
  void increaseHealthBy(int points) {
    _health += points;
    // Clamps health to 100.
    if (_health > 100) {
      _health = 100;
    }
  }

  // Resets player score, health and position. Should be called
  // while restarting and exiting the game.
  void reset() {
    // _playerData!.currentScore = 0;
    _health = 100;
    position = game.fixedResolution / 2;
  }

  // Changes the current spaceship type with given spaceship type.
  // This method also takes care of updating the internal spaceship details
  // as well as the spaceship sprite.
  void _setSpaceshipType(SpaceshipType spaceshipType) {
    spaceshipType = spaceshipType;
    _spaceship = Spaceship.getSpaceshipByType(spaceshipType);
    sprite = game.spriteSheet.getSpriteById(_spaceship.spriteId);
  }

  // Allows player to first multiple bullets for 4 seconds when called.
  void shootMultipleBullets() {
    _shootMultipleBullets = true;
    _powerUpTimer.stop();
    _powerUpTimer = Timer(
      4 * _powerUpDurationMultiplier,
      onTick: () {
        _shootMultipleBullets = false;
      },
    );
    _powerUpTimer.start();
}

void activateShield() {
    _shieldActive = true;
    _shieldTimer.stop();
    _shieldTimer = Timer(
      10 * _powerUpDurationMultiplier,
      onTick: () {
        _shieldActive = false;
      },
    );
    _shieldTimer.start();
}

void activateSpeed() {
    _speedActive = true;
    _speedTimer.stop();
    _speedTimer = Timer(
      5 * _powerUpDurationMultiplier,
      onTick: () {
        _speedActive = false;
      },
    );
    _speedTimer.start();
}

void activateDamageBoost() {
    _damageBoostActive = true;
    _damageBoostTimer.stop();
    _damageBoostTimer = Timer(
      10 * _powerUpDurationMultiplier,
      onTick: () {
        _damageBoostActive = false;
      },
    );
    _damageBoostTimer.start();
}

  // Llama a este método cuando el jugador muere.
  void die() {
    _health = 0;
    // Puedes añadir aquí efectos, sonidos o animaciones de muerte si lo deseas.
    // Por ejemplo, podrías pausar el juego o mostrar una pantalla de Game Over.
  }
}
