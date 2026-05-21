import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { findGodotBinary } from './find-godot.mjs';

const scriptDir = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(scriptDir, '../..');
const projectDir = join(repoRoot, 'godot/void-drifter');
const exportPath = join(repoRoot, 'public/godot/void-drifter/index.html');
const buildInfoPath = join(repoRoot, 'public/godot/void-drifter/build-info.json');

const godotBinary = findGodotBinary();

if (!godotBinary) {
  console.error('Godot binary not found.');
  console.error('Install Godot 4.x or set GODOT_BIN=/path/to/Godot before running this script.');
  process.exit(1);
}

mkdirSync(dirname(exportPath), { recursive: true });

const result = spawnSync(
  godotBinary,
  ['--headless', '--path', projectDir, '--export-release', 'Web', exportPath],
  {
    cwd: repoRoot,
    encoding: 'utf8',
    stdio: 'inherit',
  }
);

if (result.status !== 0) {
  console.error('Godot web export failed.');
  process.exit(result.status ?? 1);
}

writeFileSync(
  buildInfoPath,
  `${JSON.stringify(
    {
      generatedAt: new Date().toISOString(),
      project: 'godot/void-drifter',
      entry: '/godot/void-drifter/index.html',
    },
    null,
    2
  )}\n`
);

console.log(`Godot web build exported to ${exportPath}`);
