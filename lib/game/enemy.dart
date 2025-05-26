import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/particles.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'game.dart';
import 'bullet.dart';
import 'player.dart';
import 'command.dart';
import 'audio_player_component.dart';

import '../models/enemy_data.dart';

// Esta clase representa un componente enemigo.
class Enemy extends SpriteComponent
    with CollisionCallbacks, HasGameReference<SpacescapeGame> {
  // La velocidad de este enemigo.
  double _speed = 250;

  // La dirección en la que este enemigo se moverá.
  // Por defecto, hacia abajo verticalmente.
  Vector2 moveDirection = Vector2(0, 1);

  // Controla cuánto tiempo debe estar congelado el enemigo.
  late Timer _freezeTimer;

  // Contiene un objeto de la clase Random para generar números aleatorios.
  final _random = Random();

  // Los datos necesarios para crear este enemigo.
  final EnemyData enemyData;

  // Representa la salud de este enemigo.
  int _hitPoints = 10;

  // Para mostrar la salud en el mundo del juego.
  final _hpText = TextComponent(
    text: '10 HP',
    textRenderer: TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontFamily: 'BungeeInline',
      ),
    ),
  );

  ColorFilter? _colorFilter;

  // Este método genera un vector aleatorio con su ángulo
  // entre 0 y 360 grados.
  Vector2 getRandomVector() {
    return (Vector2.random(_random) - Vector2.random(_random)) * 500;
  }

  // Devuelve un vector de dirección aleatorio con un ligero ángulo hacia el eje y positivo.
  Vector2 getRandomDirection() {
    return (Vector2.random(_random) - Vector2(0.5, -1)).normalized();
  }

  Enemy({
    required super.sprite,
    required this.enemyData,
    required super.position,
    required super.size,
  }) {
    // Rota el componente enemigo 180 grados. Esto es necesario porque
    // todos los sprites inicialmente miran en la misma dirección, pero queremos que los enemigos
    // se muevan en la dirección opuesta.
    angle = pi;

    // Establece la velocidad actual desde enemyData.
    _speed = enemyData.speed;

    // Establece los puntos de vida al valor correcto desde enemyData.
    _hitPoints = enemyData.level * 10;
    _hpText.text = '$_hitPoints HP';

    // Establece el tiempo de congelación en 2 segundos. Después de 2 segundos, la velocidad se restablecerá.
    _freezeTimer = Timer(
      2,
      onTick: () {
        _speed = enemyData.speed;
      },
    );

    // Si este enemigo puede moverse horizontalmente, aleatoriza la dirección de movimiento.
    if (enemyData.hMove) {
      moveDirection = getRandomDirection();
    }

    if (_hitPoints >= 30) {
      _colorFilter = const ColorFilter.mode(Colors.red, BlendMode.modulate);
    } else if (_hitPoints >= 20) {
      _colorFilter = const ColorFilter.mode(Colors.yellow, BlendMode.modulate);
    } else {
      _colorFilter = const ColorFilter.mode(Colors.green, BlendMode.modulate);
    }
  }

  @override
  void onMount() {
    super.onMount();

    // Agrega una caja de colisión circular con un radio de 0.8 veces
    // la dimensión más pequeña del tamaño de este componente.
    final shape = CircleHitbox.relative(
      0.8,
      parentSize: size,
      position: size / 2,
      anchor: Anchor.center,
    );
    add(shape);

    // Como el componente actual ya está rotado por pi radianes,
    // el componente de texto necesita ser rotado nuevamente por pi radianes
    // para que se muestre correctamente.
    _hpText.angle = pi;

    // Para colocar el texto justo detrás del enemigo.
    _hpText.position = Vector2(50, 80);

    // Agregar como hijo del componente actual.
    add(_hpText);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Bullet) {
      // Si el otro colisionador es una bala,
      // reduce la salud por el nivel de la bala multiplicado por 10 y multiplicado por el damageMultiplier.
      _hitPoints -= other.level * 10 * other.damageMultiplier;
    }
    // El enemigo ya no se destruye aquí al colisionar con el jugador.
  }

  static final List<String> _deathSounds = [
    'laser1a.ogg',
    'laser1b.ogg',
    'laser1c.ogg',
  ];
  static int _deathSoundIndex = 0;
  static double _lastDeathSfx = 0;
  static double _lastSoundFrame = -1;

  // Este método destruirá este enemigo.
  void destroy() {
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final currentFrame = game
        .currentTime(); // Usa el tiempo del juego si lo tienes, si no, usa now
    if (_lastSoundFrame != currentFrame && now - _lastDeathSfx > 0.7) {
      final sound = _deathSounds[_deathSoundIndex];
      game.addCommand(
        Command<AudioPlayerComponent>(
          action: (audioPlayer) {
            audioPlayer.playSfx(sound);
          },
        ),
      );
      _deathSoundIndex = (_deathSoundIndex + 1) % _deathSounds.length;
      _lastDeathSfx = now;
      _lastSoundFrame = currentFrame;
    }

    removeFromParent();

    // Antes de morir, registra un comando para aumentar
    // la puntuación del jugador en 1.
    final command = Command<Player>(
      action: (player) {
        // Usa el valor correcto de killPoint para aumentar la puntuación del jugador.
        player.addToScore(enemyData.killPoint);
      },
    );
    game.addCommand(command);

    // Genera 20 partículas de círculo blanco con velocidad y aceleración aleatorias,
    // en la posición actual de este enemigo. Cada partícula vive exactamente
    // 0.1 segundos y será eliminada del mundo del juego después de eso.
    final particleComponent = ParticleSystemComponent(
      particle: Particle.generate(
        count: 3, // Antes 20, ahora menos
        lifespan: 0.07,
        generator: (i) => AcceleratedParticle(
          acceleration: getRandomVector(),
          speed: getRandomVector(),
          position: position.clone(),
          child: CircleParticle(
            radius: 2,
            paint: Paint()..color = Colors.white,
          ),
        ),
      ),
    );

    game.world.add(particleComponent);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Sincroniza el componente de texto y el valor de los puntos de vida.
    _hpText.text = '$_hitPoints HP';

    // Si los puntos de vida se han reducido a cero,
    // destruye este enemigo.
    if (_hitPoints <= 0) {
      destroy();
    }

    _freezeTimer.update(dt);

    // Actualiza la posición de este enemigo usando su velocidad y el tiempo delta.
    position += moveDirection * _speed * dt;

    // Si el enemigo sale de la pantalla, destrúyelo.
    if (position.y > game.fixedResolution.y) {
      removeFromParent();
    } else if ((position.x < size.x / 2) ||
        (position.x > (game.fixedResolution.x - size.x / 2))) {
      // El enemigo está saliendo de los límites verticales de la pantalla, invierte su dirección x.
      moveDirection.x *= -1;
    }
  }

  // Pausa al enemigo durante 2 segundos cuando se llama.
  void freeze() {
    _speed = 0;
    _freezeTimer.stop();
    _freezeTimer.start();
  }

  @override
  void render(Canvas canvas) {
    if (_colorFilter != null) {
      Paint paint = Paint()..colorFilter = _colorFilter!;
      canvas.save();
      canvas.drawImageRect(
        sprite!.image,
        sprite!.srcPosition & sprite!.srcSize,
        size.toRect(),
        paint,
      );
      canvas.restore();
    } else {
      super.render(canvas);
    }
  }
}
