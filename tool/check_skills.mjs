#!/usr/bin/env node
// Validates the Claude Code skills shipped with the kit. No dependencies:
// the frontmatter is two flat keys, and a YAML parser for that is a
// dependency with a changelog.
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';

const root = new URL('..', import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');
const skillsDir = join(root, '.claude', 'skills');
const manifestPath = join(root, '.claude-plugin', 'plugin.json');
const MAX_DESCRIPTION = 1536;
const failures = [];

function frontmatter(text) {
  const match = /^---\r?\n([\s\S]*?)\r?\n---\r?\n/.exec(text);
  if (match === null) return null;
  const fields = {};
  for (const line of match[1].split(/\r?\n/)) {
    const colon = line.indexOf(':');
    if (colon === -1) continue;
    fields[line.slice(0, colon).trim()] = line.slice(colon + 1).trim().replace(/^"(.*)"$/, '$1');
  }
  return fields;
}

for (const dir of readdirSync(skillsDir)) {
  const skillPath = join(skillsDir, dir);
  if (!statSync(skillPath).isDirectory()) continue;
  let text;
  try {
    text = readFileSync(join(skillPath, 'SKILL.md'), 'utf8');
  } catch {
    failures.push(`${dir}: SKILL.md missing`);
    continue;
  }
  const fields = frontmatter(text);
  if (fields === null) {
    failures.push(`${dir}: no YAML frontmatter`);
    continue;
  }
  if (fields.name !== dir) failures.push(`${dir}: frontmatter name is "${fields.name ?? ''}", expected "${dir}"`);
  if (!fields.description) failures.push(`${dir}: description missing`);
  else if (fields.description.length > MAX_DESCRIPTION) failures.push(`${dir}: description has ${fields.description.length} chars, max ${MAX_DESCRIPTION}`);
  for (const section of ['## When to use', '## Inputs', '## Steps', '## Verify', '## Pitfalls']) {
    if (!text.includes(section)) failures.push(`${dir}: section "${section}" missing`);
  }
  if (failures.every((failure) => !failure.startsWith(`${dir}:`))) console.log(`ok  ${dir} — ${fields.description.slice(0, 70)}…`);
}

try {
  const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'));
  for (const field of ['name', 'version', 'description', 'skills']) {
    if (!manifest[field]) failures.push(`plugin.json: "${field}" missing`);
  }
  if (manifest.skills !== './.claude/skills/') failures.push(`plugin.json: skills must be "./.claude/skills/", got "${manifest.skills}"`);
} catch (error) {
  failures.push(`plugin.json: ${error.message}`);
}

if (failures.length > 0) {
  for (const failure of failures) console.error(`FAIL ${failure}`);
  process.exit(1);
}
console.log('skills ok');
