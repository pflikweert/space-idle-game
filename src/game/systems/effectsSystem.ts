import { PARTICLE_LIFETIME } from '../core/constants';
import type { Enemy, Particle, Vector, WorldState } from '../core/types';

const ENEMY_DEATH_VFX_LIFETIME = 0.28;

export function addExplosion(world: WorldState, origin: Vector, color: string) {
  for (let index = 0; index < 6; index += 1) {
    const angle = (Math.PI * 2 * index) / 6 + world.nextId * 0.17;
    const speed = 52 + index * 11;
    world.particles.push({
      id: world.nextId++,
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

function getEnemyDeathVfx(enemy: Enemy): Pick<Particle, 'assetId' | 'size'> {
  if (enemy.typeId === 'red_cruiser') {
    return { assetId: 'enemy-death-large', size: 118 };
  }

  if (enemy.typeId === 'red_fighter') {
    return { assetId: 'enemy-death-medium', size: 94 };
  }

  return { assetId: 'enemy-death-small', size: 74 };
}

export function addEnemyDeathVfx(world: WorldState, enemy: Enemy) {
  const vfx = getEnemyDeathVfx(enemy);

  world.particles.push({
    id: world.nextId++,
    x: enemy.x,
    y: enemy.y,
    radius: 1,
    vx: 0,
    vy: 0,
    life: ENEMY_DEATH_VFX_LIFETIME,
    maxLife: ENEMY_DEATH_VFX_LIFETIME,
    color: '#f97316',
    ...vfx,
  });
}

export function updateEffects(world: WorldState, deltaSeconds: number) {
  for (const particle of world.particles) {
    particle.x += particle.vx * deltaSeconds;
    particle.y += particle.vy * deltaSeconds;
    particle.life -= deltaSeconds;
  }

  world.particles = world.particles.filter((particle) => particle.life > 0);
}
