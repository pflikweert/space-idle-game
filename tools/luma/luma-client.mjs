const LUMA_API_BASE_URL = 'https://agents.lumalabs.ai/v1';

export class LumaApiError extends Error {
  constructor(message, { status, detail, responseBody } = {}) {
    super(message);
    this.name = 'LumaApiError';
    this.status = status;
    this.detail = detail;
    this.responseBody = responseBody;
  }
}

async function parseResponseBody(response) {
  const text = await response.text();

  if (!text) {
    return null;
  }

  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

function getErrorDetail(body) {
  if (!body || typeof body !== 'object') {
    return body;
  }

  return body.detail ?? body.error ?? body.message ?? body;
}

async function requestJson(apiKey, path, options = {}) {
  const response = await fetch(`${LUMA_API_BASE_URL}${path}`, {
    ...options,
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
      ...options.headers,
    },
  });
  const body = await parseResponseBody(response);

  if (!response.ok) {
    const detail = getErrorDetail(body);
    throw new LumaApiError(`Luma API request failed with HTTP ${response.status}`, {
      status: response.status,
      detail,
      responseBody: body,
    });
  }

  return body;
}

export function createGeneration(apiKey, requestBody) {
  return requestJson(apiKey, '/generations', {
    method: 'POST',
    body: JSON.stringify(requestBody),
  });
}

export function getGeneration(apiKey, generationId) {
  return requestJson(apiKey, `/generations/${generationId}`);
}

export async function waitForGeneration(apiKey, generationId, options = {}) {
  const pollIntervalMs = options.pollIntervalMs ?? 3000;
  const timeoutMs = options.timeoutMs ?? 180000;
  const startedAt = Date.now();

  while (Date.now() - startedAt < timeoutMs) {
    const generation = await getGeneration(apiKey, generationId);

    if (generation.state === 'completed' || generation.state === 'failed') {
      return generation;
    }

    await new Promise((resolve) => {
      setTimeout(resolve, pollIntervalMs);
    });
  }

  throw new LumaApiError(`Timed out waiting for generation ${generationId}`, {
    detail: { generationId, timeoutMs },
  });
}

export async function downloadOutput(url) {
  const response = await fetch(url);

  if (!response.ok) {
    throw new LumaApiError(`Failed to download Luma output with HTTP ${response.status}`, {
      status: response.status,
      detail: await response.text(),
    });
  }

  return Buffer.from(await response.arrayBuffer());
}
