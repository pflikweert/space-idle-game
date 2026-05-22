export const PROMPT_TEMPLATES = {
  'enemy.reference.front': {
    description: 'Front-view enemy ship reference.',
    build: (enemy) =>
      `Create a clean front-view reference of a VOID DRIFTER enemy ship named ${enemy.displayName}. Arcade-readable sci-fi silhouette, dark hull with neon red/cyan accents, transparent or flat neutral background, centered full object, no text, no UI, no pilot, no environment, consistent hard-surface details. Archetype: ${enemy.archetype}.`,
  },
  'enemy.reference.turnaround': {
    description: 'Four-view enemy ship turnaround reference.',
    build: (enemy) =>
      `Create a 4-view turnaround reference sheet for ${enemy.displayName}: front, rear/top, left side, right side. Same ship identity in every view, centered, consistent proportions, arcade-readable silhouette, neutral background, no labels, no text. Archetype: ${enemy.archetype}.`,
  },
  'enemy.sprite.transparent': {
    description: 'Transparent-background gameplay sprite reference.',
    build: (enemy) =>
      `Create a transparent-background game sprite of ${enemy.displayName}, 384x512 canvas, centered stable pivot, readable at ${enemy.recommendedDisplaySize}px, neon arcade sci-fi material, no shadow baked into background, no cropping, no text. Archetype: ${enemy.archetype}.`,
  },
  'enemy.animation.attack': {
    description: 'Attack-state sprite reference.',
    build: (enemy) =>
      `Create attack-state sprite references for ${enemy.displayName}: idle silhouette preserved, weapon glow active, muzzle/charge accents visible, same 384x512 centered canvas, transparent background, no explosion or death damage. Archetype: ${enemy.archetype}.`,
  },
  'enemy.animation.damaged': {
    description: 'Damaged-state sprite reference.',
    build: (enemy) =>
      `Create damaged-state sprite references for ${enemy.displayName}: same silhouette and pose as the movement sprite, small hull cracks, sparks, scorch marks, readable but not destroyed, transparent background. Archetype: ${enemy.archetype}.`,
  },
  'enemy.animation.death': {
    description: 'Death/explosion overlay reference.',
    build: (enemy) =>
      `Create a death/explosion variant for ${enemy.displayName}: debris and energy burst matching the ship palette, transparent background, suitable as short overlay VFX, do not replace movement sprite silhouette. Archetype: ${enemy.archetype}.`,
  },
  'enemy.demo.turnaround': {
    description: 'Polished 3D/turnaround demo reference.',
    build: (enemy) =>
      `Create a polished 3D/turnaround demo reference for ${enemy.displayName}, same design language, three-quarter view, cinematic but asset-reference focused, neutral background, no gameplay UI. Archetype: ${enemy.archetype}.`,
  },
  'enemy.vfx.explosion-set': {
    description: 'Shared enemy death explosion sprite-set reference.',
    build: () =>
      'Create a single transparent-background PNG sprite sheet for VOID DRIFTER enemy death explosions. Pixel-game friendly arcade sci-fi style, moderate detail, not photorealistic, not max fidelity. Include 4 to 6 small transition frames showing a red/cyan plasma pop dissipating, plus 4 alternate subtle ending variants. Some endings may include a few tiny hull fragments slowly drifting away, but most should stay clean and restrained. Keep each frame centered in its own grid cell, stable scale, no text, no UI, no background, no large screen-filling blasts, no smoky realism.',
  },
};

export function listPromptTemplateIds() {
  return Object.keys(PROMPT_TEMPLATES);
}

export function renderPromptTemplate(templateId, enemy) {
  const template = PROMPT_TEMPLATES[templateId];

  if (!template) {
    throw new Error(`Unknown Luma prompt template: ${templateId}`);
  }

  return template.build(enemy);
}
