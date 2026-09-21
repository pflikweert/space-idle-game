import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { findGodotBinary, godotLogArgs, godotOutputForAssertions } from './find-godot.mjs';

const result = spawnSync(findGodotBinary(), ['--headless',...godotLogArgs('test-active-loadout'),'--quit-after','1000','--path',fileURLToPath(new URL('../../godot/void-drifter',import.meta.url)),'--script',fileURLToPath(new URL('./test-active-loadout.gd',import.meta.url))], {encoding:'utf8',timeout:120_000});
const output = godotOutputForAssertions(`${result.stdout ?? ''}${result.stderr ?? ''}`);
process.stdout.write(output);
process.exit(result.status===0 && output.includes('Active loadout checks:') && !/SCRIPT ERROR|Parse Error|\bERROR:/.test(output) ? 0 : 1);
