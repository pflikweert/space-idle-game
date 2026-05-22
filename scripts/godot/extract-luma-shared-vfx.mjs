import { readdirSync, statSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import path from 'node:path';

import { findGodotBinary } from './find-godot.mjs';

const repoRoot = process.cwd();
const defaultReferenceDir = path.join(
  repoRoot,
  'assets/game/enemies/shared-vfx/references/luma'
);

function parseArgs(argv) {
  const options = {};

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    const next = argv[index + 1];

    if (arg === '--source') {
      if (!next || next.startsWith('--')) {
        throw new Error('--source requires a path');
      }
      options.source = next;
      index += 1;
    } else if (arg === '--help' || arg === '-h') {
      options.help = true;
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }

  return options;
}

function usage() {
  return `Usage:
  npm run luma:vfx:extract -- --source <path>
  npm run luma:vfx:extract

When --source is omitted, the newest enemy.vfx.explosion-set image under
assets/game/enemies/shared-vfx/references/luma is used.`;
}

function findNewestExplosionSheet() {
  const candidates = readdirSync(defaultReferenceDir)
    .filter((fileName) => /^enemy\.vfx\.explosion-set-.*\.(jpe?g|png)$/i.test(fileName))
    .map((fileName) => {
      const absolutePath = path.join(defaultReferenceDir, fileName);
      return {
        path: absolutePath,
        mtimeMs: statSync(absolutePath).mtimeMs,
      };
    })
    .sort((left, right) => right.mtimeMs - left.mtimeMs);

  if (candidates.length === 0) {
    throw new Error(`No Luma explosion sheets found in ${defaultReferenceDir}`);
  }

  return candidates[0].path;
}

function main() {
  const options = parseArgs(process.argv.slice(2));

  if (options.help) {
    console.log(usage());
    return;
  }

  const godotBin = findGodotBinary();
  if (!godotBin) {
    throw new Error('Could not find Godot. Set GODOT_BIN=/path/to/Godot and try again.');
  }

  const source = options.source ? path.resolve(repoRoot, options.source) : findNewestExplosionSheet();
  const scriptPath = path.join(repoRoot, 'scripts/godot/extract-luma-shared-vfx.gd');
  const result = spawnSync(
    godotBin,
    [
      '--headless',
      '--path',
      'godot/void-drifter',
      '--script',
      scriptPath,
      '--',
      `--repo-root=${repoRoot}`,
      `--source=${source}`,
    ],
    {
      cwd: repoRoot,
      encoding: 'utf8',
      stdio: 'inherit',
    }
  );

  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
}

try {
  main();
} catch (error) {
  console.error(error.message);
  process.exit(1);
}
