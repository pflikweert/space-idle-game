import { distanceSquared } from './math';
import type { Vector } from './types';

export function circlesOverlap(
  a: Vector & { radius: number },
  b: Vector & { radius: number }
) {
  const hitDistance = a.radius + b.radius;
  return distanceSquared(a, b) <= hitDistance * hitDistance;
}
