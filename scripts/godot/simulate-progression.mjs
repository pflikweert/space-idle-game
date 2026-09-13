import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { findGodotBinary } from './find-godot.mjs';

const binary = findGodotBinary();
if (!binary) throw new Error('Godot binary not found');
const result = spawn(binary, [
  '--headless', '--path', fileURLToPath(new URL('../../godot/void-drifter', import.meta.url)),
  '--script', fileURLToPath(new URL('./simulate-progression.gd', import.meta.url)),
  '--', ...process.argv.slice(2),
], { timeout: 900_000 });
let failed = false;
let tail = '';
for (const stream of [result.stdout, result.stderr]) {
  stream.on('data', (chunk) => {
    process.stdout.write(chunk);
    const text = tail + chunk.toString();
    failed ||= /SCRIPT ERROR|Parse Error|\bERROR:/.test(text);
    tail = text.slice(-64);
  });
}
result.on('error', (error) => { console.error(error.message); failed = true; });
result.on('close', (code) => process.exit(code === 0 && !failed ? 0 : 1));
