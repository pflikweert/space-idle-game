import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { findGodotBinary } from './find-godot.mjs';

const result = spawnSync(findGodotBinary(), [
  '--quit-after', '3000',
  '--path', fileURLToPath(new URL('../../godot/void-drifter', import.meta.url)),
  '--script', fileURLToPath(new URL('./visual-projectile-vfx-qa.gd', import.meta.url)),
], { encoding: 'utf8', timeout: 180_000 });
const output = `${result.stdout ?? ''}${result.stderr ?? ''}`;
process.stdout.write(output);
process.exit(result.status === 0 && output.includes('VFX PERF') && !/SCRIPT ERROR|Parse Error|\bERROR:/.test(output) ? 0 : 1);
