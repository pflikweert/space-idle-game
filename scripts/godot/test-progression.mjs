import { readFileSync } from 'node:fs';
import ts from 'typescript';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { findGodotBinary, godotLogArgs, godotOutputForAssertions } from './find-godot.mjs';

const binary = findGodotBinary();
if (!binary) throw new Error('Godot binary not found');
const result = spawnSync(binary, [
  '--headless', ...godotLogArgs('test-progression'), '--path', fileURLToPath(new URL('../../godot/void-drifter', import.meta.url)),
  '--script', fileURLToPath(new URL('./test-progression.gd', import.meta.url)),
], { encoding: 'utf8', timeout: 120_000 });
const output = godotOutputForAssertions(`${result.stdout ?? ''}${result.stderr ?? ''}`);
const parityLine = output.split('\n').find((line) => line.startsWith('ENEMY_PARITY:'));
const statsLine = output.split('\n').find((line) => line.startsWith('ENEMY_STATS:'));
const rostersLine = output.split('\n').find((line) => line.startsWith('ENEMY_WAVE_ROSTERS:'));
let parityPassed = false;
if (parityLine) {
  const source = readFileSync(new URL('../../src/game/core/enemies.ts', import.meta.url), 'utf8');
  const compiled = ts.transpileModule(source, { compilerOptions: { module: ts.ModuleKind.CommonJS } });
  const module = { exports: {} };
  new Function('exports', 'module', compiled.outputText)(module.exports, module);
  const mirror = JSON.parse(parityLine.slice('ENEMY_PARITY:'.length));
  parityPassed = module.exports.ENEMY_DEFINITIONS.every((entry) => {
    const expected = {
      weaponDamage: entry.weapon?.projectileDamage ?? 0, weaponReload: entry.weapon?.reloadSeconds ?? 0,
      navigationRadius: entry.navigationRadius ?? 0,
      status: entry.status, unlockWave: entry.unlockWave, weight: entry.spawn.weight,
      minRunLevel: entry.spawn.minRunLevel, hp: entry.baseStats.hp, speed: entry.baseStats.speed,
      contactDamage: entry.baseStats.contactDamage, cashReward: entry.baseStats.cashReward,
      coinReward: entry.baseStats.coinReward, hpMultiplier: entry.scaling.hpMultiplier,
      damageMultiplier: entry.scaling.damageMultiplier, radius: entry.baseStats.radius, assetKey: entry.assetKey,
    };
    return Object.entries(expected).every(([key, value]) => mirror[entry.id]?.[key] === value);
  }) && Object.keys(mirror).length === module.exports.ENEMY_DEFINITIONS.length;
  if (statsLine) {
    const samples = JSON.parse(statsLine.slice('ENEMY_STATS:'.length));
    parityPassed &&= Object.entries(samples).every(([id, waves]) =>
      Object.entries(waves).every(([wave, expected]) => {
        const actual = module.exports.getEnemyStats(id, Number(wave));
        return Math.abs(actual.hp - expected.hp) <= expected.hp * 1e-10 &&
          Math.abs(actual.contactDamage - expected.damage) <= expected.damage * 1e-10;
      }));
  } else parityPassed = false;
  if (rostersLine) {
    const rosters = JSON.parse(rostersLine.slice('ENEMY_WAVE_ROSTERS:'.length));
    parityPassed &&= Object.entries(rosters).every(([wave, expected]) => {
      const actual = module.exports.getWaveIntelRoster(Number(wave));
      return actual.length === expected.length && actual.every((entry, index) =>
        entry.definition.id === expected[index].id &&
        entry.guaranteedBoss === expected[index].boss &&
        (entry.spawnChance === null ? expected[index].chance < 0 : Math.abs(entry.spawnChance - expected[index].chance) < 1e-10) &&
        Math.abs(entry.stats.hp - expected[index].hp) < 1e-10 &&
        Math.abs(entry.stats.contactDamage - expected[index].damage) < 1e-10
      );
    });
  } else parityPassed = false;
}
process.stdout.write(output.split('\n').filter((line) => !line.startsWith('ENEMY_PARITY:') && !line.startsWith('ENEMY_STATS:') && !line.startsWith('ENEMY_WAVE_ROSTERS:')).join('\n'));
process.stdout.write(`Godot/TypeScript enemy parity: ${parityPassed ? 'passed' : 'FAILED'}\n`);
process.exit(parityPassed && result.status === 0 && !/SCRIPT ERROR|Parse Error|\bERROR:/.test(output) ? 0 : 1);
