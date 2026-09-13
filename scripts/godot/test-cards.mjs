import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { findGodotBinary } from './find-godot.mjs';
const result = spawnSync(findGodotBinary(), ['--headless', '--quit-after', '1000', '--path', fileURLToPath(new URL('../../godot/void-drifter', import.meta.url)), '--script', fileURLToPath(new URL('./test-cards.gd', import.meta.url))], { encoding: 'utf8', timeout: 120_000 });
const output = `${result.stdout ?? ''}${result.stderr ?? ''}`;
process.stdout.write(output);
process.exit(result.status === 0 && output.includes('Card checks:') && !/SCRIPT ERROR|Parse Error|\bERROR:/.test(output) ? 0 : 1);
