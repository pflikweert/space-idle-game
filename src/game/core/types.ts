import type { EnemyMovementFrame, EnemySpawnEdge, EnemyTypeId } from './enemies';

export type Vector = {
  x: number;
  y: number;
};

export type PlayfieldSize = {
  width: number;
  height: number;
};

export type Enemy = Vector & {
  id: number;
  typeId: EnemyTypeId;
  radius: number;
  hp: number;
  maxHp: number;
  speed: number;
  contactDamage: number;
  xpReward: number;
  scoreReward: number;
  spawnEdge: EnemySpawnEdge;
  movementFrame: EnemyMovementFrame;
};

export type Bullet = Vector & {
  id: number;
  radius: number;
  vx: number;
  vy: number;
  life: number;
};

export type Particle = Vector & {
  id: number;
  radius: number;
  vx: number;
  vy: number;
  life: number;
  color: string;
};

export type Player = Vector & {
  hp: number;
  radius: number;
};

export type RunStatus = 'ready' | 'running' | 'dead';

export type WorldState = {
  playfieldSize: PlayfieldSize;
  player: Player;
  playerTarget: Vector;
  playerVelocityX: number;
  enemies: Enemy[];
  bullets: Bullet[];
  particles: Particle[];
  kills: number;
  score: number;
  elapsed: number;
  backgroundTime: number;
  status: RunStatus;
  spawnTimer: number;
  fireTimer: number;
  nextId: number;
};

export type WorldSnapshot = Pick<
  WorldState,
  | 'playfieldSize'
  | 'player'
  | 'playerTarget'
  | 'playerVelocityX'
  | 'enemies'
  | 'bullets'
  | 'particles'
  | 'kills'
  | 'score'
  | 'elapsed'
  | 'backgroundTime'
  | 'status'
>;

export type WorldInput = {
  playerTarget: Vector | null;
};
