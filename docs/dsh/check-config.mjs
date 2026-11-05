#!/usr/bin/env node
// Offline inspection only: no server, agent, API key, network probe or install.
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { dirname, join, resolve } from 'node:path';
import { mkdtempSync, mkdirSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';

const docs = dirname(fileURLToPath(import.meta.url));
const runtime = process.argv[2];
if (!runtime || process.argv.length !== 3) {
  console.error('Usage: node docs/dsh/check-config.mjs /absolute/path/to/dsh-runtime');
  process.exit(2);
}
const [major, minor] = process.versions.node.split('.').map(Number);
assert(major > 22 || (major === 22 && minor >= 12), 'Node >=22.12.0 is required.');
const requireRuntime = createRequire(join(resolve(runtime), 'package.json'));
const packageFile = requireRuntime.resolve('@deepseek-ai/dsh/package.json');
const manifest = JSON.parse(readFileSync(packageFile, 'utf8'));
assert.equal(manifest.version, '0.2.1-rc.5', 'DSH version changed; re-review this setup.');
const requireDsh = createRequire(packageFile);
const yaml = requireDsh('js-yaml');
// Preserve DSH expression tags as inert data. Never evaluate their JavaScript.
const schema = yaml.DEFAULT_SCHEMA.extend([
  new yaml.Type('tag:yaml.org,2002:js', {
    kind: 'scalar',
    construct: (expression) => ({ unevaluatedDshExpression: expression }),
  }),
]);
const readYaml = (file) => yaml.load(readFileSync(file, 'utf8'), { schema });
const config = (name) => join(docs, 'config', name);
const privacy = config('privacy.patch.yml');
const web = config('webpage-worker.patch.yml');
const headless = config('headless-webpage-worker.patch.yml');
for (const file of [privacy, web, headless]) {
  assert(Array.isArray(readYaml(file)), 'Every patch must be a YAML list.');
}
const declaredPackage = JSON.parse(readFileSync(join(docs, 'package.example.json'), 'utf8'));
assert.equal(declaredPackage.dependencies['@deepseek-ai/dsh'], manifest.version);
const skill = readFileSync(join(docs, 'skills/ball-art-review/SKILL.md'), 'utf8');
const frontmatter = skill.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n/);
assert(frontmatter, 'Skill requires YAML frontmatter.');
const skillMeta = yaml.load(frontmatter[1]);
assert.equal(skillMeta.name, 'ball-art-review');
assert(typeof skillMeta.description === 'string' && skillMeta.description.trim());

const handoffDocs = [skill,
  readFileSync(join(docs, 'README.md'), 'utf8'),
  readFileSync(join(docs, 'TASK.template.md'), 'utf8'),
  readFileSync(web, 'utf8'), readFileSync(headless, 'utf8')];
for (const content of handoffDocs) {
  assert(content.includes('游戏总指挥'), 'Every handoff must name the game director.');
  assert(!content.includes('总指挥（美术总负责人）'), 'Game director must not be mislabeled as art director.');
}

const temp = mkdtempSync(join(tmpdir(), 'balls-dsh-config-'));
try {
  for (const folder of ['os-home', 'state', 'agents', 'work']) {
    mkdirSync(join(temp, folder));
  }
  // Deliberately do not inherit process.env. In particular, do not forward
  // API keys, model endpoints, proxies, real HOME or an existing DSH_HOME.
  const env = {
    HOME: join(temp, 'os-home'),
    USERPROFILE: join(temp, 'os-home'),
    DSH_HOME: join(temp, 'state'),
    DSH_AGENTS_HOME: join(temp, 'agents'),
    PATH: dirname(process.execPath),
  };
  if (process.platform === 'win32' && process.env.SystemRoot) {
    env.SystemRoot = process.env.SystemRoot;
  }
  function compose(profile, patch) {
    const result = spawnSync(process.execPath, [
      join(dirname(packageFile), 'lib/bin.js'),
      '--profile', profile,
      '--patch', patch,
      '--patch', privacy,
      '--dump-config',
    ], {
      cwd: join(temp, 'work'), env, encoding: 'utf8',
      timeout: 30_000, maxBuffer: 8 * 1024 * 1024,
    });
    // Do not dump potentially sensitive composed configuration to stdout.
    assert(!result.error, `Configuration dump could not complete: ${result.error?.code ?? 'unknown'}`);
    assert.equal(result.status, 0, `DSH ${profile} configuration dump failed; inspect the local installation.`);
    const entries = yaml.load(result.stdout, { schema });
    assert(Array.isArray(entries), 'Composed config must be a list.');
    const named = new Map();
    for (const entry of entries) {
      if (!entry.id) continue;
      assert(!named.has(entry.id), `Duplicate composed entry: ${entry.id}`);
      named.set(entry.id, entry);
    }
    assert.equal(named.get('session-log-deepseek')?.config?.enabled, false);
    assert.equal(named.get('session-telemetry-otel')?.config?.mode, 'DISABLED');
    return named;
  }
  const webEntries = compose('web', web);
  const preset = webEntries.get('preset-webpage-worker')?.config;
  assert.equal(preset?.id, 'webpage-worker');
  assert.equal(preset?.name, '网页制作员');
  const plugins = preset.plugins;
  for (const name of ['dsh-persona', 'dsh-agent-instructions', 'dsh-tool-bash',
    'dsh-tool-fs', 'dsh-tool-fs-search', 'dsh-skill-filesystem', 'dsh-tool-skill',
    'dsh-tool-ask-user', 'dsh-tool-present']) {
    assert(plugins.some((p) => p.name === `@deepseek-ai/${name}`), `Missing ${name}`);
    requireDsh.resolve(`@deepseek-ai/${name}`);
  }
  assert(!plugins.some((p) => /subagent/.test(p.name)), 'Web worker must not expose child-agent tools.');
  const webPersona = plugins.find((p) => p.name === '@deepseek-ai/dsh-persona').config.prefix;
  assert(webPersona.includes('ball-art-review'));
  assert(webPersona.includes('游戏总指挥（游戏总策划）'));
  assert(!webPersona.includes('美术总负责人'));
  const headlessEntries = compose('headless', headless);
  assert(!headlessEntries.has('preset-webpage-worker'), 'Headless is not the Web preset.');
  const headlessPersona = headlessEntries.get('system-prompt')?.config?.personaPrefix;
  assert(headlessPersona?.includes('ball-art-review'));
  assert(headlessPersona.includes('游戏总指挥（游戏总策划）'));
  assert(!headlessPersona.includes('美术总负责人'));
  assert.equal(headlessEntries.get('credentials')?.disabled, true, 'Headless credential behavior changed.');
  for (const id of ['tool-subagent', 'tool-subagent-fork', 'tool-subagent-control', 'tool-subagent-list-agents']) {
    assert.equal(headlessEntries.get(id)?.disabled, true, `${id} must be disabled.`);
  }
  for (const id of ['agent-instructions', 'skill', 'skill-filesystem', 'tool-skill']) {
    assert(headlessEntries.has(id), `Missing headless ${id}`);
    assert.notEqual(headlessEntries.get(id).disabled, true);
  }
  console.log('PASS: game-director identity across both profiles, skill and handoff docs.');
  console.log('PASS: pinned DSH version, package sample, YAML and skill frontmatter.');
  console.log('PASS: Web webpage-worker composition and installed plugin resolution.');
  console.log('PASS: headless persona, skill support, disabled child-agent tools and credential distinction.');
  console.log('PASS: both profiles disable extra Session Log and Session OTel upload.');
  console.log('NOT RUN: UI loading, model calls, runtime permission enforcement, paid tasks, deployment or Codex bridge.');
} finally {
  // Only remove the freshly generated, credential-free temporary fixture.
  rmSync(temp, { recursive: true, force: true });
}
