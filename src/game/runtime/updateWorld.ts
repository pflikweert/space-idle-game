import { applyPlayerInput, updatePlayerMovement } from '../systems/playerSystem';
import { updateEnemyMovement } from '../systems/enemyMovementSystem';
import { updateEnemySpawning } from '../systems/enemySpawnSystem';
import { updateEffects } from '../systems/effectsSystem';
import { resolveCombatCollisions } from '../systems/collisionSystem';
import { updateProjectiles } from '../systems/projectileSystem';
import { updateWeapons } from '../systems/weaponSystem';
import type { WorldInput, WorldState } from '../core/types';

export function updateWorld(world: WorldState, input: WorldInput, deltaMs: number) {
  const deltaSeconds = deltaMs / 1000;
  world.backgroundTime += deltaSeconds;

  if (world.status !== 'running') {
    return;
  }

  applyPlayerInput(world, input);
  world.elapsed += deltaSeconds;
  updatePlayerMovement(world, deltaSeconds);
  updateEnemySpawning(world, deltaMs);
  updateWeapons(world, deltaMs);
  updateEnemyMovement(world, deltaSeconds);
  updateProjectiles(world, deltaSeconds);
  updateEffects(world, deltaSeconds);
  resolveCombatCollisions(world);
}
