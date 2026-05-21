import { normalize } from '../core/math';
import type { WorldState } from '../core/types';

export function updateEnemyMovement(world: WorldState, deltaSeconds: number) {
  for (const enemy of world.enemies) {
    const direction = normalize(world.player.x - enemy.x, world.player.y - enemy.y);
    enemy.x += direction.x * enemy.speed * deltaSeconds;
    enemy.y += direction.y * enemy.speed * deltaSeconds;
  }
}
