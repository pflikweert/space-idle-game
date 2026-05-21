import { PLAYER_MOVE_SPEED } from '../core/constants';
import { clampPointToPlayfield } from '../core/math';
import type { WorldInput, WorldState } from '../core/types';

export function applyPlayerInput(world: WorldState, input: WorldInput) {
  if (world.status !== 'running' || input.playerTarget === null) {
    return;
  }

  world.playerTarget = clampPointToPlayfield(input.playerTarget, world.playfieldSize);
}

export function updatePlayerMovement(world: WorldState, deltaSeconds: number) {
  const target = clampPointToPlayfield(world.playerTarget, world.playfieldSize);
  world.playerTarget = target;

  const dx = target.x - world.player.x;
  const dy = target.y - world.player.y;
  const distance = Math.hypot(dx, dy);
  if (distance < 1) {
    world.player.x = target.x;
    world.player.y = target.y;
    world.playerVelocityX = 0;
    return;
  }

  const step = Math.min(distance, PLAYER_MOVE_SPEED * deltaSeconds);
  world.player.x += (dx / distance) * step;
  world.player.y += (dy / distance) * step;
  world.playerVelocityX = (dx / distance) * step;
}
