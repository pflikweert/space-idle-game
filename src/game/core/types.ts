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
  radius: number;
  hp: number;
  speed: number;
  color: string;
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
  | 'elapsed'
  | 'backgroundTime'
  | 'status'
>;

export type WorldInput = {
  playerTarget: Vector | null;
};
