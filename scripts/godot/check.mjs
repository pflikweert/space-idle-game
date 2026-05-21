import { dirname, join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { findGodotBinary } from './find-godot.mjs';

const scriptDir = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(scriptDir, '../..');
const projectDir = join(repoRoot, 'godot/void-drifter');
const godotBinary = findGodotBinary();

if (!godotBinary) {
  console.error('Godot binary not found.');
  console.error('Install Godot 4.x or set GODOT_BIN=/path/to/Godot before running this script.');
  process.exit(1);
}

const result = spawnSync(
  godotBinary,
  ['--headless', '--path', projectDir, '--quit-after', '1', '--verbose'],
  {
    cwd: repoRoot,
    encoding: 'utf8',
  }
);

const output = `${result.stdout ?? ''}${result.stderr ?? ''}`;
process.stdout.write(result.stdout ?? '');
process.stderr.write(result.stderr ?? '');

if (result.status !== 0) {
  console.error('Godot headless scene-load failed.');
  process.exit(result.status ?? 1);
}

if (/SCRIPT ERROR|Parse Error|Failed to load script|\bERROR:/i.test(output)) {
  console.error('Godot script parse/load error detected.');
  process.exit(1);
}

console.log('Godot headless scene-load check passed.');
