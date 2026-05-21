import { PLAYER_BOUNDS_PADDING, PLAYER_RADIUS } from './constants';
import type { PlayfieldSize, Vector } from './types';

export function distanceSquared(a: Vector, b: Vector) {
  const dx = a.x - b.x;
  const dy = a.y - b.y;
  return dx * dx + dy * dy;
}

export function normalize(dx: number, dy: number) {
  const length = Math.hypot(dx, dy) || 1;
  return {
    x: dx / length,
    y: dy / length,
  };
}

export function clamp(value: number, min: number, max: number) {
  return Math.max(min, Math.min(max, value));
}

export function clampPointToPlayfield(point: Vector, size: PlayfieldSize) {
  const inset = PLAYER_RADIUS + PLAYER_BOUNDS_PADDING;
  return {
    x: clamp(point.x, inset, Math.max(inset, size.width - inset)),
    y: clamp(point.y, inset, Math.max(inset, size.height - inset)),
  };
}

export function formatTime(seconds: number) {
  const wholeSeconds = Math.floor(seconds);
  const minutes = Math.floor(wholeSeconds / 60);
  const remainingSeconds = wholeSeconds % 60;
  return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
}
