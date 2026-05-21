import { normalize } from '../core/math';
import { getDirectionFromVelocity } from '../core/enemyDirection';
import type { Enemy, WorldState } from '../core/types';

const ENEMY_HIT_FEEDBACK_SECONDS = 0.13;

export function updateEnemyMovement(world: WorldState, deltaSeconds: number) {
  for (const enemy of world.enemies) {
    const direction = normalize(world.player.x - enemy.x, world.player.y - enemy.y);
    enemy.vx = direction.x * enemy.speed;
    enemy.vy = direction.y * enemy.speed;
    enemy.x += enemy.vx * deltaSeconds;
    enemy.y += enemy.vy * deltaSeconds;
    enemy.direction = getDirectionFromVelocity(enemy.vx, enemy.vy);

    if (enemy.hitTimer > 0) {
      enemy.hitTimer = Math.max(0, enemy.hitTimer - deltaSeconds);
      enemy.visualState = 'hit';
    } else {
      enemy.visualState = enemy.vx === 0 && enemy.vy === 0 ? 'idle' : 'thrust';
    }
  }
}

export function markEnemyHit(enemy: Enemy) {
  enemy.hitTimer = ENEMY_HIT_FEEDBACK_SECONDS;
  enemy.visualState = 'hit';
}
