import type { WorldState } from '../core/types';

export function updateProjectiles(world: WorldState, deltaSeconds: number) {
  for (const bullet of world.bullets) {
    bullet.x += bullet.vx * deltaSeconds;
    bullet.y += bullet.vy * deltaSeconds;
    bullet.life -= deltaSeconds;
  }
}

export function removeExpiredProjectiles(world: WorldState, removedBulletIds: Set<number>) {
  const { width, height } = world.playfieldSize;
  world.bullets = world.bullets.filter((bullet) => {
    const inBounds = bullet.x > -24 && bullet.x < width + 24 && bullet.y > -24 && bullet.y < height + 24;
    return !removedBulletIds.has(bullet.id) && bullet.life > 0 && inBounds;
  });
}
