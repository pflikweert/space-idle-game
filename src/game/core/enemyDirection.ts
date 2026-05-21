export type EnemyDirection = 'down' | 'up' | 'left' | 'right';

export function getDirectionFromVelocity(vx: number, vy: number): EnemyDirection {
  if (Math.abs(vx) > Math.abs(vy)) {
    return vx < 0 ? 'left' : 'right';
  }

  return vy < 0 ? 'up' : 'down';
}
