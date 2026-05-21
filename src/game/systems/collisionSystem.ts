import { DAMAGE_VALUES } from '../core/constants';
import { circlesOverlap } from '../core/collision';
import type { WorldState } from '../core/types';
import { addExplosion } from './effectsSystem';
import { removeExpiredProjectiles } from './projectileSystem';

export function resolveCombatCollisions(world: WorldState) {
  const removedBulletIds = new Set<number>();
  const removedEnemyIds = new Set<number>();

  for (const bullet of world.bullets) {
    for (const enemy of world.enemies) {
      if (removedEnemyIds.has(enemy.id) || removedBulletIds.has(bullet.id)) {
        continue;
      }

      if (circlesOverlap(bullet, enemy)) {
        enemy.hp -= DAMAGE_VALUES.bullet;
        removedBulletIds.add(bullet.id);
        if (enemy.hp <= 0) {
          removedEnemyIds.add(enemy.id);
          world.kills += 1;
          addExplosion(world, enemy, enemy.color);
        }
      }
    }
  }

  for (const enemy of world.enemies) {
    if (removedEnemyIds.has(enemy.id)) {
      continue;
    }

    if (circlesOverlap(world.player, enemy)) {
      world.player.hp = Math.max(0, world.player.hp - DAMAGE_VALUES.enemyContact);
      removedEnemyIds.add(enemy.id);
      addExplosion(world, enemy, '#67e8f9');
    }
  }

  world.enemies = world.enemies.filter((enemy) => !removedEnemyIds.has(enemy.id));
  removeExpiredProjectiles(world, removedBulletIds);

  if (world.player.hp <= 0) {
    world.status = 'dead';
    world.bullets = [];
    world.enemies = [];
  }
}
