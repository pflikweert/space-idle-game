#!/usr/bin/env node
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const repoRoot = path.resolve(path.dirname(__filename), '../..');
const sourcePath = 'docs/project/void-drifter-game-reference.md';
const outputPath = 'docs/upload/chatgpt-project-context.md';
const isCheckMode = process.argv.includes('--check');

function absolute(relativePath) {
  return path.join(repoRoot, relativePath);
}

function normalizeLf(value) {
  return String(value ?? '').replace(/\r\n?/g, '\n');
}

async function buildBundle() {
  const source = normalizeLf(await fs.readFile(absolute(sourcePath), 'utf8')).trim();
  return [
    '# VOID DRIFTER ChatGPT Project Context',
    '',
    'This is the single generated file intended for manual upload to a ChatGPT Project.',
    `Canonical source: \`${sourcePath}\`.`,
    'Do not edit this artifact directly; update the canonical dossier and run `npm run docs:upload`.',
    '',
    '---',
    '',
    source,
    '',
  ].join('\n');
}

async function main() {
  const nextContent = await buildBundle();
  if (isCheckMode) {
    const existing = await fs.readFile(absolute(outputPath), 'utf8').catch(() => null);
    if (existing === null || normalizeLf(existing) !== nextContent) {
      console.error(`${outputPath} is out of date. Run \`npm run docs:upload\`.`);
      process.exitCode = 1;
      return;
    }
    console.log(`${outputPath} is up to date.`);
    return;
  }

  await fs.mkdir(path.dirname(absolute(outputPath)), { recursive: true });
  await fs.writeFile(absolute(outputPath), nextContent);
  console.log(`Prepared the single ChatGPT upload file at ${outputPath}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
