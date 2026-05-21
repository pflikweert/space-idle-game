import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  GestureResponderEvent,
  LayoutChangeEvent,
  Pressable,
  SafeAreaView,
  StyleSheet,
  Text,
  useWindowDimensions,
  View,
} from 'react-native';

const PLAYER_HP = 100;
const ENEMY_SPAWN_INTERVAL = 850;
const PLAYER_FIRE_INTERVAL = 320;
const BULLET_SPEED = 430;
const ENEMY_SPEED = 58;
const ENEMY_HP = 2;
const PLAYER_MOVE_SPEED = 360;
const PLAYER_BOUNDS_PADDING = 10;
const DAMAGE_VALUES = {
  bullet: 1,
  enemyContact: 18,
} as const;

const PLAYER_RADIUS = 18;
const MAX_DELTA_SECONDS = 0.033;
const PARTICLE_LIFETIME = 0.34;

type Vector = {
  x: number;
  y: number;
};

type Enemy = Vector & {
  id: number;
  radius: number;
  hp: number;
  speed: number;
  color: string;
};

type Bullet = Vector & {
  id: number;
  radius: number;
  vx: number;
  vy: number;
  life: number;
};

type Particle = Vector & {
  id: number;
  radius: number;
  vx: number;
  vy: number;
  life: number;
  color: string;
};

type RunStatus = 'running' | 'dead';

type GameState = {
  player: Vector & {
    hp: number;
    radius: number;
  };
  playerTarget: Vector;
  playerVelocityX: number;
  enemies: Enemy[];
  bullets: Bullet[];
  particles: Particle[];
  kills: number;
  elapsed: number;
  status: RunStatus;
  spawnTimer: number;
  fireTimer: number;
  lastFrameTime: number | null;
  nextId: number;
};

type Snapshot = Pick<
  GameState,
  | 'player'
  | 'playerTarget'
  | 'playerVelocityX'
  | 'enemies'
  | 'bullets'
  | 'particles'
  | 'kills'
  | 'elapsed'
  | 'status'
>;

type PlayfieldSize = {
  width: number;
  height: number;
};

const ENEMY_VARIANTS = [
  { radius: 12, color: '#fb7185', speedMultiplier: 1.08, hp: ENEMY_HP },
  { radius: 16, color: '#a78bfa', speedMultiplier: 0.92, hp: ENEMY_HP + 1 },
  { radius: 10, color: '#facc15', speedMultiplier: 1.24, hp: ENEMY_HP },
] as const;

const STAR_DOTS = Array.from({ length: 86 }, (_, index) => ({
  id: index,
  xRatio: ((index * 37 + 11) % 100) / 100,
  yRatio: ((index * 53 + 17) % 100) / 100,
  size: 1 + (index % 3),
  opacity: 0.22 + (index % 5) * 0.09,
}));

function createInitialGameState(size: PlayfieldSize): GameState {
  const playerStart = {
    x: size.width / 2,
    y: size.height * 0.68,
  };

  return {
    player: {
      ...playerStart,
      radius: PLAYER_RADIUS,
      hp: PLAYER_HP,
    },
    playerTarget: playerStart,
    playerVelocityX: 0,
    enemies: [],
    bullets: [],
    particles: [],
    kills: 0,
    elapsed: 0,
    status: 'running',
    spawnTimer: ENEMY_SPAWN_INTERVAL * 0.45,
    fireTimer: PLAYER_FIRE_INTERVAL * 0.6,
    lastFrameTime: null,
    nextId: 1,
  };
}

function cloneSnapshot(state: GameState): Snapshot {
  return {
    player: { ...state.player },
    playerTarget: { ...state.playerTarget },
    playerVelocityX: state.playerVelocityX,
    enemies: state.enemies.map((enemy) => ({ ...enemy })),
    bullets: state.bullets.map((bullet) => ({ ...bullet })),
    particles: state.particles.map((particle) => ({ ...particle })),
    kills: state.kills,
    elapsed: state.elapsed,
    status: state.status,
  };
}

function distanceSquared(a: Vector, b: Vector) {
  const dx = a.x - b.x;
  const dy = a.y - b.y;
  return dx * dx + dy * dy;
}

function normalize(dx: number, dy: number) {
  const length = Math.hypot(dx, dy) || 1;
  return {
    x: dx / length,
    y: dy / length,
  };
}

function clamp(value: number, min: number, max: number) {
  return Math.max(min, Math.min(max, value));
}

function clampPointToPlayfield(point: Vector, size: PlayfieldSize) {
  const inset = PLAYER_RADIUS + PLAYER_BOUNDS_PADDING;
  return {
    x: clamp(point.x, inset, Math.max(inset, size.width - inset)),
    y: clamp(point.y, inset, Math.max(inset, size.height - inset)),
  };
}

function movePlayerTowardTarget(state: GameState, deltaSeconds: number, size: PlayfieldSize) {
  const target = clampPointToPlayfield(state.playerTarget, size);
  state.playerTarget = target;

  const dx = target.x - state.player.x;
  const dy = target.y - state.player.y;
  const distance = Math.hypot(dx, dy);
  if (distance < 1) {
    state.player.x = target.x;
    state.player.y = target.y;
    state.playerVelocityX = 0;
    return;
  }

  const step = Math.min(distance, PLAYER_MOVE_SPEED * deltaSeconds);
  state.player.x += (dx / distance) * step;
  state.player.y += (dy / distance) * step;
  state.playerVelocityX = (dx / distance) * step;
}

function spawnEnemy(state: GameState, size: PlayfieldSize) {
  const variant = ENEMY_VARIANTS[state.nextId % ENEMY_VARIANTS.length];
  const edge = state.nextId % 4;
  const inset = variant.radius + 8;
  const drift = ((state.nextId * 71) % 100) / 100;
  let x = size.width * drift;
  let y = size.height * drift;

  if (edge === 0) y = -inset;
  if (edge === 1) x = size.width + inset;
  if (edge === 2) y = size.height + inset;
  if (edge === 3) x = -inset;

  state.enemies.push({
    id: state.nextId++,
    x,
    y,
    radius: variant.radius,
    hp: variant.hp,
    speed: ENEMY_SPEED * variant.speedMultiplier,
    color: variant.color,
  });
}

function fireAtNearestEnemy(state: GameState) {
  if (state.enemies.length === 0) {
    return;
  }

  let nearest = state.enemies[0];
  let nearestDistance = distanceSquared(state.player, nearest);
  for (const enemy of state.enemies.slice(1)) {
    const enemyDistance = distanceSquared(state.player, enemy);
    if (enemyDistance < nearestDistance) {
      nearest = enemy;
      nearestDistance = enemyDistance;
    }
  }

  const direction = normalize(nearest.x - state.player.x, nearest.y - state.player.y);
  state.bullets.push({
    id: state.nextId++,
    x: state.player.x,
    y: state.player.y - state.player.radius,
    radius: 4,
    vx: direction.x * BULLET_SPEED,
    vy: direction.y * BULLET_SPEED,
    life: 1.65,
  });
}

function addExplosion(state: GameState, origin: Vector, color: string) {
  for (let index = 0; index < 6; index += 1) {
    const angle = (Math.PI * 2 * index) / 6 + state.nextId * 0.17;
    const speed = 52 + index * 11;
    state.particles.push({
      id: state.nextId++,
      x: origin.x,
      y: origin.y,
      radius: 2 + (index % 2),
      vx: Math.cos(angle) * speed,
      vy: Math.sin(angle) * speed,
      life: PARTICLE_LIFETIME,
      color,
    });
  }
}

function advanceGame(state: GameState, deltaSeconds: number, size: PlayfieldSize) {
  const deltaMs = deltaSeconds * 1000;
  state.elapsed += deltaSeconds;
  movePlayerTowardTarget(state, deltaSeconds, size);
  state.spawnTimer -= deltaMs;
  state.fireTimer -= deltaMs;

  if (state.spawnTimer <= 0) {
    spawnEnemy(state, size);
    state.spawnTimer = ENEMY_SPAWN_INTERVAL;
  }

  if (state.fireTimer <= 0) {
    fireAtNearestEnemy(state);
    state.fireTimer = PLAYER_FIRE_INTERVAL;
  }

  for (const enemy of state.enemies) {
    const direction = normalize(state.player.x - enemy.x, state.player.y - enemy.y);
    enemy.x += direction.x * enemy.speed * deltaSeconds;
    enemy.y += direction.y * enemy.speed * deltaSeconds;
  }

  for (const bullet of state.bullets) {
    bullet.x += bullet.vx * deltaSeconds;
    bullet.y += bullet.vy * deltaSeconds;
    bullet.life -= deltaSeconds;
  }

  for (const particle of state.particles) {
    particle.x += particle.vx * deltaSeconds;
    particle.y += particle.vy * deltaSeconds;
    particle.life -= deltaSeconds;
  }

  const removedBulletIds = new Set<number>();
  const removedEnemyIds = new Set<number>();

  for (const bullet of state.bullets) {
    for (const enemy of state.enemies) {
      if (removedEnemyIds.has(enemy.id) || removedBulletIds.has(bullet.id)) {
        continue;
      }

      const hitDistance = bullet.radius + enemy.radius;
      if (distanceSquared(bullet, enemy) <= hitDistance * hitDistance) {
        enemy.hp -= DAMAGE_VALUES.bullet;
        removedBulletIds.add(bullet.id);
        if (enemy.hp <= 0) {
          removedEnemyIds.add(enemy.id);
          state.kills += 1;
          addExplosion(state, enemy, enemy.color);
        }
      }
    }
  }

  for (const enemy of state.enemies) {
    if (removedEnemyIds.has(enemy.id)) {
      continue;
    }

    const contactDistance = state.player.radius + enemy.radius;
    if (distanceSquared(state.player, enemy) <= contactDistance * contactDistance) {
      state.player.hp = Math.max(0, state.player.hp - DAMAGE_VALUES.enemyContact);
      removedEnemyIds.add(enemy.id);
      addExplosion(state, enemy, '#67e8f9');
    }
  }

  state.enemies = state.enemies.filter((enemy) => !removedEnemyIds.has(enemy.id));
  state.bullets = state.bullets.filter((bullet) => {
    const inBounds =
      bullet.x > -24 && bullet.x < size.width + 24 && bullet.y > -24 && bullet.y < size.height + 24;
    return !removedBulletIds.has(bullet.id) && bullet.life > 0 && inBounds;
  });
  state.particles = state.particles.filter((particle) => particle.life > 0);

  if (state.player.hp <= 0) {
    state.status = 'dead';
    state.bullets = [];
    state.enemies = [];
  }
}

function formatTime(seconds: number) {
  const wholeSeconds = Math.floor(seconds);
  const minutes = Math.floor(wholeSeconds / 60);
  const remainingSeconds = wholeSeconds % 60;
  return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
}

export function VoidDrifterPrototypeScreen() {
  const windowSize = useWindowDimensions();
  const animationFrameRef = useRef<number | null>(null);
  const [playfieldSize, setPlayfieldSize] = useState<PlayfieldSize>({
    width: Math.min(windowSize.width, 980),
    height: Math.max(420, windowSize.height),
  });
  const gameRef = useRef<GameState>(createInitialGameState(playfieldSize));
  const [snapshot, setSnapshot] = useState<Snapshot>(() => cloneSnapshot(gameRef.current));

  const resetRun = useCallback(() => {
    const freshState = createInitialGameState(playfieldSize);
    gameRef.current = freshState;
    setSnapshot(cloneSnapshot(freshState));
  }, [playfieldSize]);

  const stars = useMemo(() => STAR_DOTS, []);

  useEffect(() => {
    resetRun();
  }, [resetRun]);

  useEffect(() => {
    function tick(timestamp: number) {
      const state = gameRef.current;
      if (state.lastFrameTime === null) {
        state.lastFrameTime = timestamp;
      }

      const deltaSeconds = Math.min(
        MAX_DELTA_SECONDS,
        (timestamp - state.lastFrameTime) / 1000
      );
      state.lastFrameTime = timestamp;

      if (state.status === 'running') {
        advanceGame(state, deltaSeconds, playfieldSize);
      }

      setSnapshot(cloneSnapshot(state));
      animationFrameRef.current = requestAnimationFrame(tick);
    }

    animationFrameRef.current = requestAnimationFrame(tick);
    return () => {
      if (animationFrameRef.current !== null) {
        cancelAnimationFrame(animationFrameRef.current);
      }
    };
  }, [playfieldSize]);

  function handlePlayfieldLayout(event: LayoutChangeEvent) {
    const { width, height } = event.nativeEvent.layout;
    if (width <= 0 || height <= 0) {
      return;
    }

    setPlayfieldSize((current) => {
      const next = {
        width: Math.round(width),
        height: Math.round(height),
      };

      if (current.width === next.width && current.height === next.height) {
        return current;
      }

      return next;
    });
  }

  const hpPercent = Math.max(0, Math.min(100, (snapshot.player.hp / PLAYER_HP) * 100));
  const playerTilt = clamp(snapshot.playerVelocityX * 26, -12, 12);

  function updatePlayerTarget(event: GestureResponderEvent) {
    if (gameRef.current.status !== 'running') {
      return;
    }

    gameRef.current.playerTarget = clampPointToPlayfield(
      {
        x: event.nativeEvent.locationX,
        y: event.nativeEvent.locationY,
      },
      playfieldSize
    );
  }

  return (
    <View style={styles.screen}>
      <SafeAreaView style={styles.safeArea}>
        <View style={styles.header}>
          <View>
            <Text style={styles.kicker}>VOID DRIFTER</Text>
            <Text style={styles.title}>Core Fun Prototype</Text>
          </View>
          <Pressable style={styles.headerButton} onPress={resetRun}>
            <Text style={styles.headerButtonText}>Restart</Text>
          </Pressable>
        </View>

        <View style={styles.hud}>
          <View style={styles.hudItemWide}>
            <Text style={styles.hudLabel}>HP</Text>
            <View style={styles.hpTrack}>
              <View style={[styles.hpFill, { width: `${hpPercent}%` }]} />
            </View>
            <Text style={styles.hudValue}>{snapshot.player.hp}</Text>
          </View>
          <View style={styles.hudItem}>
            <Text style={styles.hudLabel}>Kills</Text>
            <Text style={styles.hudValue}>{snapshot.kills}</Text>
          </View>
          <View style={styles.hudItem}>
            <Text style={styles.hudLabel}>Time</Text>
            <Text style={styles.hudValue}>{formatTime(snapshot.elapsed)}</Text>
          </View>
          <View style={styles.hudItem}>
            <Text style={styles.hudLabel}>Enemies</Text>
            <Text style={styles.hudValue}>{snapshot.enemies.length}</Text>
          </View>
        </View>

        <View
          testID="void-drifter-playfield"
          style={styles.playfield}
          onLayout={handlePlayfieldLayout}
          onMoveShouldSetResponder={() => snapshot.status === 'running'}
          onResponderGrant={updatePlayerTarget}
          onResponderMove={updatePlayerTarget}
          onStartShouldSetResponder={() => snapshot.status === 'running'}>
          {stars.map((star) => (
            <View
              key={star.id}
              style={[
                styles.star,
                {
                  top: star.yRatio * playfieldSize.height,
                  left: star.xRatio * playfieldSize.width,
                  width: star.size,
                  height: star.size,
                  opacity: star.opacity,
                },
              ]}
            />
          ))}

          <View style={styles.scanLine} />

          {snapshot.particles.map((particle) => (
            <View
              key={particle.id}
              style={[
                styles.particle,
                {
                  backgroundColor: particle.color,
                  left: particle.x - particle.radius,
                  top: particle.y - particle.radius,
                  width: particle.radius * 2,
                  height: particle.radius * 2,
                  borderRadius: particle.radius,
                  opacity: Math.max(0, particle.life / PARTICLE_LIFETIME),
                },
              ]}
            />
          ))}

          {snapshot.bullets.map((bullet) => (
            <View
              key={bullet.id}
              style={[
                styles.bullet,
                {
                  left: bullet.x - bullet.radius,
                  top: bullet.y - bullet.radius,
                  width: bullet.radius * 2,
                  height: bullet.radius * 2,
                  borderRadius: bullet.radius,
                },
              ]}
            />
          ))}

          {snapshot.enemies.map((enemy) => (
            <View
              key={enemy.id}
              style={[
                styles.enemy,
                {
                  left: enemy.x - enemy.radius,
                  top: enemy.y - enemy.radius,
                  width: enemy.radius * 2,
                  height: enemy.radius * 2,
                  borderRadius: enemy.radius * 0.45,
                  backgroundColor: enemy.color,
                },
              ]}>
              <View style={styles.enemyCore} />
            </View>
          ))}

          <View
            testID="void-drifter-player"
            style={[
              styles.player,
              {
                left: snapshot.player.x - snapshot.player.radius,
                top: snapshot.player.y - snapshot.player.radius,
                width: snapshot.player.radius * 2,
                height: snapshot.player.radius * 2,
                transform: [{ rotate: `${playerTilt}deg` }],
              },
            ]}>
            <View style={styles.playerTrail} />
            <View style={styles.playerDiamond} />
            <View style={styles.playerNose} />
            <View style={styles.playerEngine} />
          </View>

          {snapshot.status === 'dead' && (
            <View style={styles.deathOverlay}>
              <Text style={styles.deathKicker}>Run ended</Text>
              <Text style={styles.deathTitle}>Drifter offline</Text>
              <Text style={styles.deathStats}>
                {snapshot.kills} kills / {formatTime(snapshot.elapsed)}
              </Text>
              <Pressable style={styles.deathButton} onPress={resetRun}>
                <Text style={styles.deathButtonText}>Restart run</Text>
              </Pressable>
            </View>
          )}
        </View>
      </SafeAreaView>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: '#030712',
  },
  safeArea: {
    flex: 1,
    paddingHorizontal: 16,
    paddingVertical: 14,
    gap: 12,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 12,
  },
  kicker: {
    color: '#22d3ee',
    fontSize: 12,
    fontWeight: '800',
    letterSpacing: 1.8,
  },
  title: {
    color: '#f8fafc',
    fontSize: 24,
    fontWeight: '800',
  },
  headerButton: {
    borderWidth: 1,
    borderColor: 'rgba(103, 232, 249, 0.46)',
    borderRadius: 8,
    paddingHorizontal: 14,
    paddingVertical: 10,
    backgroundColor: 'rgba(8, 47, 73, 0.6)',
  },
  headerButtonText: {
    color: '#cffafe',
    fontSize: 13,
    fontWeight: '800',
  },
  hud: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  hudItem: {
    minWidth: 92,
    flexGrow: 1,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: 'rgba(148, 163, 184, 0.22)',
    backgroundColor: 'rgba(15, 23, 42, 0.82)',
    paddingHorizontal: 12,
    paddingVertical: 10,
    gap: 4,
  },
  hudItemWide: {
    minWidth: 160,
    flexGrow: 2,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: 'rgba(148, 163, 184, 0.22)',
    backgroundColor: 'rgba(15, 23, 42, 0.82)',
    paddingHorizontal: 12,
    paddingVertical: 10,
    gap: 5,
  },
  hudLabel: {
    color: '#94a3b8',
    fontSize: 11,
    fontWeight: '800',
    letterSpacing: 1.2,
    textTransform: 'uppercase',
  },
  hudValue: {
    color: '#f8fafc',
    fontSize: 18,
    fontWeight: '800',
  },
  hpTrack: {
    height: 6,
    overflow: 'hidden',
    borderRadius: 6,
    backgroundColor: 'rgba(15, 23, 42, 0.94)',
  },
  hpFill: {
    height: '100%',
    borderRadius: 6,
    backgroundColor: '#22c55e',
  },
  playfield: {
    flex: 1,
    minHeight: 420,
    overflow: 'hidden',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: 'rgba(125, 211, 252, 0.28)',
    backgroundColor: '#050816',
  },
  star: {
    position: 'absolute',
    borderRadius: 99,
    backgroundColor: '#e0f2fe',
  },
  scanLine: {
    position: 'absolute',
    left: 0,
    right: 0,
    top: '68%',
    height: 1,
    backgroundColor: 'rgba(34, 211, 238, 0.18)',
  },
  bullet: {
    position: 'absolute',
    backgroundColor: '#67e8f9',
    borderWidth: 1,
    borderColor: '#ecfeff',
  },
  enemy: {
    position: 'absolute',
    alignItems: 'center',
    justifyContent: 'center',
    opacity: 0.94,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.35)',
  },
  enemyCore: {
    width: '38%',
    height: '38%',
    borderRadius: 99,
    backgroundColor: 'rgba(15, 23, 42, 0.72)',
  },
  particle: {
    position: 'absolute',
  },
  player: {
    position: 'absolute',
    alignItems: 'center',
    justifyContent: 'center',
  },
  playerTrail: {
    position: 'absolute',
    bottom: -14,
    width: 14,
    height: 28,
    borderRadius: 14,
    backgroundColor: '#22d3ee',
    opacity: 0.28,
  },
  playerDiamond: {
    width: 24,
    height: 24,
    borderRadius: 4,
    borderWidth: 2,
    borderColor: '#67e8f9',
    backgroundColor: '#0f172a',
    transform: [{ rotate: '45deg' }],
  },
  playerNose: {
    position: 'absolute',
    top: -2,
    width: 0,
    height: 0,
    borderLeftWidth: 7,
    borderRightWidth: 7,
    borderBottomWidth: 16,
    borderLeftColor: 'transparent',
    borderRightColor: 'transparent',
    borderBottomColor: '#e879f9',
  },
  playerEngine: {
    position: 'absolute',
    bottom: -3,
    width: 8,
    height: 12,
    borderRadius: 8,
    backgroundColor: '#38bdf8',
    opacity: 0.86,
  },
  deathOverlay: {
    position: 'absolute',
    left: 18,
    right: 18,
    top: '28%',
    alignItems: 'center',
    gap: 12,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: 'rgba(248, 113, 113, 0.42)',
    backgroundColor: 'rgba(2, 6, 23, 0.92)',
    paddingHorizontal: 24,
    paddingVertical: 28,
  },
  deathKicker: {
    color: '#fca5a5',
    fontSize: 12,
    fontWeight: '800',
    letterSpacing: 1.6,
    textTransform: 'uppercase',
  },
  deathTitle: {
    color: '#f8fafc',
    fontSize: 30,
    fontWeight: '900',
    textAlign: 'center',
  },
  deathStats: {
    color: '#cbd5e1',
    fontSize: 16,
    fontWeight: '700',
  },
  deathButton: {
    marginTop: 4,
    borderRadius: 8,
    backgroundColor: '#22d3ee',
    paddingHorizontal: 18,
    paddingVertical: 12,
  },
  deathButtonText: {
    color: '#082f49',
    fontSize: 15,
    fontWeight: '900',
  },
});
