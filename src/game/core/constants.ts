export const PLAYER_HP = 140;
export const ENEMY_SPAWN_INTERVAL = 1500;
export const MIN_ENEMY_SPAWN_INTERVAL = 620;
export const FIRST_ENEMY_SPAWN_DELAY = 1350;
export const PLAYER_FIRE_INTERVAL = 260;
export const BULLET_SPEED = 540;
export const ENEMY_SPEED = 42;
export const ENEMY_HP = 2;
export const PLAYER_MOVE_SPEED = 470;
export const PLAYER_BOUNDS_PADDING = 10;
export const PLAYER_RADIUS = 18;
export const PLAYER_SPRITE_SIZE = 76;
export const PLAYER_DAMAGED_HP_THRESHOLD = 0.3;
export const PLAYER_BANKING_THRESHOLD = 1.2;
export const PARALLAX_LAYER_HEIGHT = 2048;
export const MAX_DELTA_SECONDS = 0.033;
export const PARTICLE_LIFETIME = 0.42;

export const DAMAGE_VALUES = {
  bullet: 1,
  enemyContact: 12,
} as const;

export const DIFFICULTY_SCALING = {
  maxEnemiesStart: 3,
  maxEnemiesCap: 13,
  maxEnemiesRampSeconds: 11,
  spawnRampMsPerSecond: 24,
  enemySpeedRampPerSecond: 0.012,
  enemySpeedCapMultiplier: 1.48,
} as const;

export const ENEMY_VARIANTS = [
  { radius: 12, color: '#fb7185', speedMultiplier: 1.08, hp: ENEMY_HP },
  { radius: 16, color: '#a78bfa', speedMultiplier: 0.92, hp: ENEMY_HP + 1 },
  { radius: 10, color: '#facc15', speedMultiplier: 1.24, hp: ENEMY_HP },
] as const;
