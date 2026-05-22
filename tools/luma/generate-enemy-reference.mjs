#!/usr/bin/env node

import { createHash } from 'node:crypto';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  createGeneration,
  downloadOutput,
  waitForGeneration,
} from './luma-client.mjs';
import {
  listPromptTemplateIds,
  PROMPT_TEMPLATES,
  renderPromptTemplate,
} from './prompt-templates.mjs';

const DEFAULT_MODEL = 'uni-1';
const DEFAULT_OUTPUT_FORMAT = 'png';
const DEFAULT_USER_ID = 'void-drifter-local-dev';
const DEFAULT_POLL_INTERVAL_MS = 3000;
const DEFAULT_TIMEOUT_MS = 180000;
const MAX_IMAGE_REFS = 9;

const TOOL_DIR = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(TOOL_DIR, '../..');
const MANIFEST_PATH = path.join(REPO_ROOT, 'assets/game/enemies/enemy-assets-manifest.json');
const ENV_LOCAL_PATH = path.join(REPO_ROOT, '.env.local');

function usage() {
  return `Usage:
  node tools/luma/generate-enemy-reference.mjs --enemy <asset-folder> --template <template-id> [options]

Required:
  --enemy <asset-folder>       Enemy folder key from assets/game/enemies/enemy-assets-manifest.json
  --template <template-id>     Prompt template id

Options:
  --dry-run                    Print sanitized request and do not call Luma
  --ref <path>                 Local PNG/JPEG/WebP reference file; repeat up to ${MAX_IMAGE_REFS} times
  --model <model>              uni-1 or uni-1-max (default: ${DEFAULT_MODEL})
  --output-format <format>     png or jpeg (default: ${DEFAULT_OUTPUT_FORMAT})
  --aspect-ratio <ratio>       Optional Luma aspect ratio, such as 1:1, 3:2, or 16:9
  --user-id <id>               Opaque Luma user_id (default: ${DEFAULT_USER_ID})
  --web-search                 Enable Luma web_search (default: false)
  --poll-interval-ms <number>  Poll interval for real generation (default: ${DEFAULT_POLL_INTERVAL_MS})
  --timeout-ms <number>        Poll timeout for real generation (default: ${DEFAULT_TIMEOUT_MS})
  --list-templates             List available prompt template ids
  --help                       Show this help

Examples:
  node tools/luma/generate-enemy-reference.mjs --enemy red-scout-drone --template enemy.reference.front --dry-run
  node tools/luma/generate-enemy-reference.mjs --enemy shared-vfx --template enemy.vfx.explosion-set --aspect-ratio 16:9 --dry-run
  npm run luma:enemy:dry-run -- --enemy red-fighter --template enemy.sprite.transparent
`;
}

function parseArgs(argv) {
  const options = {
    refs: [],
    dryRun: false,
    model: DEFAULT_MODEL,
    outputFormat: DEFAULT_OUTPUT_FORMAT,
    userId: DEFAULT_USER_ID,
    webSearch: false,
    pollIntervalMs: DEFAULT_POLL_INTERVAL_MS,
    timeoutMs: DEFAULT_TIMEOUT_MS,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    const next = argv[index + 1];

    switch (arg) {
      case '--help':
      case '-h':
        options.help = true;
        break;
      case '--list-templates':
        options.listTemplates = true;
        break;
      case '--dry-run':
        options.dryRun = true;
        break;
      case '--web-search':
        options.webSearch = true;
        break;
      case '--enemy':
        options.enemy = requireValue(arg, next);
        index += 1;
        break;
      case '--template':
        options.template = requireValue(arg, next);
        index += 1;
        break;
      case '--ref':
        options.refs.push(requireValue(arg, next));
        index += 1;
        break;
      case '--model':
        options.model = requireValue(arg, next);
        index += 1;
        break;
      case '--output-format':
        options.outputFormat = requireValue(arg, next);
        index += 1;
        break;
      case '--aspect-ratio':
        options.aspectRatio = requireValue(arg, next);
        index += 1;
        break;
      case '--user-id':
        options.userId = requireValue(arg, next);
        index += 1;
        break;
      case '--poll-interval-ms':
        options.pollIntervalMs = parsePositiveInteger(arg, requireValue(arg, next));
        index += 1;
        break;
      case '--timeout-ms':
        options.timeoutMs = parsePositiveInteger(arg, requireValue(arg, next));
        index += 1;
        break;
      default:
        throw new Error(`Unknown argument: ${arg}`);
    }
  }

  return options;
}

function requireValue(arg, value) {
  if (!value || value.startsWith('--')) {
    throw new Error(`${arg} requires a value`);
  }

  return value;
}

function parsePositiveInteger(arg, value) {
  const parsed = Number.parseInt(value, 10);

  if (!Number.isFinite(parsed) || parsed <= 0) {
    throw new Error(`${arg} must be a positive integer`);
  }

  return parsed;
}

function validateOptions(options) {
  if (options.help || options.listTemplates) {
    return;
  }

  if (!options.enemy) {
    throw new Error('--enemy is required');
  }

  if (!options.template) {
    throw new Error('--template is required');
  }

  if (!['uni-1', 'uni-1-max'].includes(options.model)) {
    throw new Error('--model must be uni-1 or uni-1-max');
  }

  if (!['png', 'jpeg'].includes(options.outputFormat)) {
    throw new Error('--output-format must be png or jpeg');
  }

  if (
    options.aspectRatio &&
    !['3:1', '2:1', '16:9', '3:2', '1:1', '2:3', '9:16', '1:2', '1:3'].includes(
      options.aspectRatio
    )
  ) {
    throw new Error('--aspect-ratio must be one of 3:1, 2:1, 16:9, 3:2, 1:1, 2:3, 9:16, 1:2, or 1:3');
  }

  if (options.refs.length > MAX_IMAGE_REFS) {
    throw new Error(`--ref accepts at most ${MAX_IMAGE_REFS} files for image generation`);
  }
}

async function readManifest() {
  return JSON.parse(await readFile(MANIFEST_PATH, 'utf8'));
}

async function loadLocalEnv() {
  let content;
  try {
    content = await readFile(ENV_LOCAL_PATH, 'utf8');
  } catch (error) {
    if (error.code === 'ENOENT') {
      return;
    }

    throw error;
  }

  for (const rawLine of content.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith('#')) {
      continue;
    }

    const normalizedLine = line.startsWith('export ') ? line.slice('export '.length).trim() : line;
    const separatorIndex = normalizedLine.indexOf('=');
    if (separatorIndex <= 0) {
      continue;
    }

    const key = normalizedLine.slice(0, separatorIndex).trim();
    let value = normalizedLine.slice(separatorIndex + 1).trim();

    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    } else {
      const commentIndex = value.indexOf(' #');
      if (commentIndex >= 0) {
        value = value.slice(0, commentIndex).trim();
      }
    }

    if (!process.env[key]) {
      process.env[key] = value;
    }
  }
}

async function writeManifest(manifest) {
  await writeFile(MANIFEST_PATH, `${JSON.stringify(manifest, null, 2)}\n`);
}

function getAsset(manifest, assetKey) {
  if (assetKey === 'shared-vfx') {
    return {
      kind: 'shared-vfx',
      key: assetKey,
      data: {
        displayName: 'Shared Enemy Death Explosion VFX',
        archetype: 'subtle reusable enemy death effect set',
        recommendedDisplaySize: 96,
        generation: manifest.sharedVfx?.generation,
      },
    };
  }

  const enemy = manifest.enemies?.[assetKey];

  if (!enemy) {
    throw new Error(
      `Unknown enemy "${assetKey}". Available: ${[
        ...Object.keys(manifest.enemies ?? {}),
        'shared-vfx',
      ].join(', ')}`
    );
  }

  return { kind: 'enemy', key: assetKey, data: enemy };
}

function getMediaType(filePath) {
  const extension = path.extname(filePath).toLowerCase();

  if (extension === '.png') {
    return 'image/png';
  }

  if (extension === '.jpg' || extension === '.jpeg') {
    return 'image/jpeg';
  }

  if (extension === '.webp') {
    return 'image/webp';
  }

  throw new Error(`Unsupported reference image extension for ${filePath}; use PNG, JPEG, or WebP`);
}

async function buildImageRefs(refPaths) {
  const refs = [];

  for (const refPath of refPaths) {
    const absolutePath = path.resolve(REPO_ROOT, refPath);
    const data = await readFile(absolutePath);
    refs.push({
      data: data.toString('base64'),
      media_type: getMediaType(absolutePath),
      localPath: path.relative(REPO_ROOT, absolutePath),
      sha256: createHash('sha256').update(data).digest('hex'),
    });
  }

  return refs;
}

function buildRequestBody({ prompt, options, imageRefs }) {
  const body = {
    prompt,
    model: options.model,
    type: 'image',
    output_format: options.outputFormat,
    web_search: options.webSearch,
    user_id: options.userId,
  };

  if (options.aspectRatio) {
    body.aspect_ratio = options.aspectRatio;
  }

  if (imageRefs.length > 0) {
    body.image_ref = imageRefs.map((ref) => ({
      data: ref.data,
      media_type: ref.media_type,
    }));
  }

  return body;
}

function sanitizeRequestBody(body) {
  return {
    ...body,
    image_ref: body.image_ref?.map((ref) => ({
      media_type: ref.media_type,
      data: `<base64:${ref.data.length} chars>`,
    })),
  };
}

function getTimestamp() {
  return new Date().toISOString().replaceAll(':', '').replaceAll('.', '-');
}

async function readRunRecords(runRecordsPath) {
  try {
    return JSON.parse(await readFile(runRecordsPath, 'utf8'));
  } catch (error) {
    if (error.code === 'ENOENT') {
      return [];
    }

    throw error;
  }
}

async function writeRunRecord(enemyKey, record) {
  const generationDir = path.join(REPO_ROOT, 'assets/game/enemies', enemyKey, 'generation');
  const runRecordsPath = path.join(generationDir, 'luma-runs.json');
  await mkdir(generationDir, { recursive: true });
  const records = await readRunRecords(runRecordsPath);
  records.push(record);
  await writeFile(runRecordsPath, `${JSON.stringify(records, null, 2)}\n`);
}

function appendUnique(values, additions) {
  const next = Array.isArray(values) ? [...values] : [];

  for (const addition of additions) {
    if (addition && !next.includes(addition)) {
      next.push(addition);
    }
  }

  return next;
}

async function updateManifestAfterSuccess({ manifest, assetKey, options, outputPath, generation, imageRefs }) {
  const asset = getAsset(manifest, assetKey);
  const target = asset.kind === 'shared-vfx' ? manifest.sharedVfx : asset.data;
  const generationMetadata = {
    provider: 'luma',
    model: options.model,
    promptTemplateIds: [],
    referenceImagePaths: [],
    generationIds: [],
    ...target.generation,
  };

  generationMetadata.model = options.model;
  generationMetadata.promptTemplateIds = appendUnique(generationMetadata.promptTemplateIds, [
    options.template,
  ]);
  generationMetadata.referenceImagePaths = appendUnique(generationMetadata.referenceImagePaths, [
    outputPath,
    ...imageRefs.map((ref) => ref.localPath),
  ]);
  generationMetadata.generationIds = appendUnique(generationMetadata.generationIds, [generation.id]);
  generationMetadata.createdAt = generation.created_at ?? new Date().toISOString();

  target.generation = generationMetadata;
  await writeManifest(manifest);
}

async function run() {
  await loadLocalEnv();
  const options = parseArgs(process.argv.slice(2));
  validateOptions(options);

  if (options.help) {
    console.log(usage());
    return;
  }

  if (options.listTemplates) {
    for (const templateId of listPromptTemplateIds()) {
      console.log(`${templateId}\t${PROMPT_TEMPLATES[templateId].description}`);
    }
    return;
  }

  const manifest = await readManifest();
  const asset = getAsset(manifest, options.enemy);
  const prompt = renderPromptTemplate(options.template, asset.data);
  const imageRefs = await buildImageRefs(options.refs);
  const requestBody = buildRequestBody({ prompt, options, imageRefs });

  if (options.dryRun) {
    console.log(
      JSON.stringify(
        {
          dryRun: true,
          endpoint: 'POST https://agents.lumalabs.ai/v1/generations',
          asset: options.enemy,
          assetKind: asset.kind,
          template: options.template,
          outputDirectory: `assets/game/enemies/${options.enemy}/references/luma`,
          requestBody: sanitizeRequestBody(requestBody),
          localReferences: imageRefs.map((ref) => ({
            path: ref.localPath,
            media_type: ref.media_type,
            sha256: ref.sha256,
          })),
        },
        null,
        2
      )
    );
    return;
  }

  const apiKey = process.env.LUMA_AGENTS_API_KEY;
  if (!apiKey) {
    throw new Error('LUMA_AGENTS_API_KEY is required for real generation. Use --dry-run to inspect without calling Luma.');
  }

  if (apiKey.toLowerCase().startsWith('bearer ')) {
    throw new Error('LUMA_AGENTS_API_KEY must be the raw key value without a "Bearer " prefix.');
  }

  if (!apiKey.startsWith('luma-api-')) {
    throw new Error('LUMA_AGENTS_API_KEY does not look like a Luma Agents key. Current Agents API keys are documented as luma-api-* tokens from platform.lumalabs.ai.');
  }

  let created;
  try {
    created = await createGeneration(apiKey, requestBody);
  } catch (error) {
    if (error.status === 401) {
      throw new Error(
        'Luma rejected LUMA_AGENTS_API_KEY with HTTP 401. Use an Agents API key, omit any "Bearer " prefix, and keep it only in your local shell or .env.local.'
      );
    }

    throw error;
  }
  const completed = await waitForGeneration(apiKey, created.id, {
    pollIntervalMs: options.pollIntervalMs,
    timeoutMs: options.timeoutMs,
  });

  if (completed.state !== 'completed') {
    throw new Error(
      `Luma generation ${completed.id} failed: ${completed.failure_code ?? 'unknown'} ${completed.failure_reason ?? ''}`.trim()
    );
  }

  const output = completed.output?.find((candidate) => candidate.type === 'image') ?? completed.output?.[0];
  if (!output?.url) {
    throw new Error(`Luma generation ${completed.id} completed without an output URL`);
  }

  const outputDir = path.join(REPO_ROOT, 'assets/game/enemies', options.enemy, 'references/luma');
  await mkdir(outputDir, { recursive: true });
  const outputFilename = `${options.template}-${getTimestamp()}.${options.outputFormat}`;
  const absoluteOutputPath = path.join(outputDir, outputFilename);
  const relativeOutputPath = path.relative(REPO_ROOT, absoluteOutputPath);
  const outputBytes = await downloadOutput(output.url);
  await writeFile(absoluteOutputPath, outputBytes);

  const record = {
    id: completed.id,
    createdAt: completed.created_at,
    completedAt: new Date().toISOString(),
    enemy: options.enemy,
    template: options.template,
    model: options.model,
    outputFormat: options.outputFormat,
    aspectRatio: options.aspectRatio ?? null,
    webSearch: options.webSearch,
    userId: options.userId,
    outputPath: relativeOutputPath,
    prompt,
    inputReferences: imageRefs.map((ref) => ({
      path: ref.localPath,
      media_type: ref.media_type,
      sha256: ref.sha256,
    })),
  };
  await writeRunRecord(options.enemy, record);
  await updateManifestAfterSuccess({
    manifest,
    assetKey: options.enemy,
    options,
    outputPath: relativeOutputPath,
    generation: completed,
    imageRefs,
  });

  console.log(JSON.stringify({ generationId: completed.id, outputPath: relativeOutputPath }, null, 2));
}

run().catch((error) => {
  console.error(error.message);
  if (error.detail) {
    console.error(JSON.stringify(error.detail, null, 2));
  }
  process.exit(1);
});
