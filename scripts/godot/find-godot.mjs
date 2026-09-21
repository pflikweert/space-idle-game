import { existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
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

// Godot's macOS RotatedFileLogger can crash while rotating user://logs when
// repeated headless checks start in the same profile. Keep check output in a
// unique temporary file so verification never depends on the user's profile
// directory or its log rotation state.
export function godotLogArgs(label = 'run') {
  const safeLabel = String(label).replace(/[^a-z0-9-]/gi, '-');
  const logPath = join(tmpdir(), `void-drifter-godot-${safeLabel}-${process.pid}-${Date.now()}.log`);
  return ['--log-file', logPath];
}

export function godotOutputForAssertions(output) {
  return String(output).replace(
    /ERROR: Condition "ret != noErr" is true\. Returning: ""\n\s+at: get_system_ca_certificates \(platform\/macos\/os_macos\.mm:1028\)\n?/g,
    ''
  );
}
