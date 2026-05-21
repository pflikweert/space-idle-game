import { FIRST_ENEMY_SPAWN_DELAY, PLAYER_FIRE_INTERVAL, PLAYER_HP, PLAYER_RADIUS } from '../core/constants';
import type { PlayfieldSize, RunStatus, WorldSnapshot, WorldState } from '../core/types';

export function createInitialWorld(size: PlayfieldSize, status: RunStatus = 'ready'): WorldState {
  const playerStart = {
    x: size.width / 2,
    y: size.height * 0.68,
  };

  return {
    playfieldSize: size,
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
    backgroundTime: 0,
    status,
    spawnTimer: FIRST_ENEMY_SPAWN_DELAY,
    fireTimer: PLAYER_FIRE_INTERVAL * 0.6,
    nextId: 1,
  };
}

export function createWorldSnapshot(world: WorldState): WorldSnapshot {
  return {
    playfieldSize: { ...world.playfieldSize },
    player: { ...world.player },
    playerTarget: { ...world.playerTarget },
    playerVelocityX: world.playerVelocityX,
    enemies: world.enemies.map((enemy) => ({ ...enemy })),
    bullets: world.bullets.map((bullet) => ({ ...bullet })),
    particles: world.particles.map((particle) => ({ ...particle })),
    kills: world.kills,
    elapsed: world.elapsed,
    backgroundTime: world.backgroundTime,
    status: world.status,
  };
}
