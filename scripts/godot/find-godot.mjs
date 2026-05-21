import { existsSync } from 'node:fs';
import { spawnSync } from 'node:child_process';

function commandExists(command) {
  const result = spawnSync('zsh', ['-lc', `command -v ${command}`], { encoding: 'utf8' });
  return result.status === 0 ? result.stdout.trim() : null;
}

export function findGodotBinary() {
  const home = process.env.HOME;
  const candidates = [
    process.env.GODOT_BIN,
    commandExists('godot'),
    commandExists('godot4'),
    home ? `${home}/.homebrew/bin/godot` : null,
    home ? `${home}/.homebrew/bin/godot4` : null,
    '/opt/homebrew/bin/godot',
    '/opt/homebrew/bin/godot4',
    '/usr/local/bin/godot',
    '/usr/local/bin/godot4',
    home ? `${home}/Applications/Godot.app/Contents/MacOS/Godot` : null,
    home ? `${home}/Applications/Godot_mono.app/Contents/MacOS/Godot` : null,
    '/Applications/Godot.app/Contents/MacOS/Godot',
    '/Applications/Godot_mono.app/Contents/MacOS/Godot',
  ].filter(Boolean);

  return candidates.find((candidate) => existsSync(candidate));
}
