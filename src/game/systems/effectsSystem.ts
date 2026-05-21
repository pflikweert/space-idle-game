import { PARTICLE_LIFETIME } from '../core/constants';
import type { Vector, WorldState } from '../core/types';

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

export function updateEffects(world: WorldState, deltaSeconds: number) {
  for (const particle of world.particles) {
    particle.x += particle.vx * deltaSeconds;
    particle.y += particle.vy * deltaSeconds;
    particle.life -= deltaSeconds;
  }

  world.particles = world.particles.filter((particle) => particle.life > 0);
}
