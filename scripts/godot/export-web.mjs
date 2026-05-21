import { existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const scriptDir = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(scriptDir, '../..');
const projectDir = join(repoRoot, 'godot/void-drifter');
const exportPath = join(repoRoot, 'public/godot/void-drifter/index.html');
const buildInfoPath = join(repoRoot, 'public/godot/void-drifter/build-info.json');

function commandExists(command) {
  const result = spawnSync('zsh', ['-lc', `command -v ${command}`], { encoding: 'utf8' });
  return result.status === 0 ? result.stdout.trim() : null;
}

function findGodotBinary() {
  const candidates = [
    process.env.GODOT_BIN,
    commandExists('godot'),
    commandExists('godot4'),
    '/Applications/Godot.app/Contents/MacOS/Godot',
    '/Applications/Godot_mono.app/Contents/MacOS/Godot',
  ].filter(Boolean);

  return candidates.find((candidate) => existsSync(candidate));
}

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
