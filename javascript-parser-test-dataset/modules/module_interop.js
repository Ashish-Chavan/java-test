/**
 * Module Systems: Interop and Dynamic Import (.js — the AMBIGUOUS extension)
 *
 * A plain .js file's module-ness depends on package.json "type" field —
 * information the parser may not have. This file is written to be valid
 * under BOTH parse goals where possible, then uses dynamic import().
 *
 * Key parser points:
 *   - import() is an EXPRESSION (call-like), legal in Scripts AND Modules —
 *     unlike import statements which are Module-only
 *   - import() accepts computed/dynamic specifiers (strings built at runtime)
 *   - import() can appear anywhere an expression can: conditions, loops,
 *     async functions, even inside CommonJS files
 *   - The parser must NOT treat 'import' purely as a statement keyword
 *
 * Parser test: verify import() parses as a call expression, and that this
 * file parses under both sourceType settings (or records which one worked).
 */
'use strict';

// ── Dynamic import: basic expression form ─────────────────────────────────
async function loadPathModule() {
  // import() returns a promise of the module namespace object
  const pathModule = await import('node:path');
  return pathModule.join('a', 'b');
}

// ── Dynamic import with computed specifier ─────────────────────────────────
async function loadByName(name) {
  const spec = 'node:' + name;              // built at runtime — legal!
  const mod = await import(spec);
  return Object.keys(mod).length;
}

// ── Dynamic import in a conditional ────────────────────────────────────────
async function loadPlatformHelper(isWindows) {
  const mod = isWindows
    ? await import('node:path')             // would be win32 helpers in real code
    : await import('node:path');
  return typeof mod.sep;
}

// ── Dynamic import with .then() chain (no await needed) ────────────────────
function loadWithThen() {
  return import('node:os')
    .then((os) => os.platform())
    .catch((err) => `failed: ${err.message}`);
}

// ── Destructuring the namespace after import() ────────────────────────────
async function loadDestructured() {
  const { join, resolve, basename } = await import('node:path');
  return basename(resolve(join('x', 'y', 'z.txt')));
}

// ── Promise.all over multiple dynamic imports ──────────────────────────────
async function loadMany() {
  const [pathMod, osMod, utilMod] = await Promise.all([
    import('node:path'),
    import('node:os'),
    import('node:util'),
  ]);
  return {
    path: typeof pathMod.join,
    os: typeof osMod.platform,
    util: typeof utilMod.format,
  };
}

// ── import() inside loops ──────────────────────────────────────────────────
async function loadSequentially(names) {
  const results = [];
  for (const name of names) {
    const mod = await import(`node:${name}`);   // template literal specifier
    results.push({ name, exportCount: Object.keys(mod).length });
  }
  return results;
}

// ── Lazy singleton pattern via dynamic import ─────────────────────────────
let cachedCrypto = null;

async function getCrypto() {
  if (cachedCrypto === null) {
    cachedCrypto = await import('node:crypto');
  }
  return cachedCrypto;
}

// ── Feature-detection interop: works in both CJS and ESM hosts ────────────
const isCommonJS = typeof module !== 'undefined' && typeof require !== 'undefined';
const isESM = !isCommonJS;

function describeEnvironment() {
  return {
    moduleSystem: isCommonJS ? 'CommonJS' : 'ESM (or browser)',
    hasRequire: typeof require !== 'undefined',
    hasDirname: typeof __dirname !== 'undefined',
    hasGlobalThis: typeof globalThis !== 'undefined',
  };
}

// ── Dual-mode export pattern (UMD-lite) ────────────────────────────────────
const api = {
  loadPathModule,
  loadByName,
  loadPlatformHelper,
  loadWithThen,
  loadDestructured,
  loadMany,
  loadSequentially,
  getCrypto,
  describeEnvironment,
};

// Attach to CJS exports if present; otherwise attach to globalThis.
// This runtime branching is exactly why .js files are ambiguous.
if (isCommonJS) {
  module.exports = api;
} else {
  globalThis.__interopApi = api;
}

// ── Demo runner ────────────────────────────────────────────────────────────
async function main() {
  console.log('Environment:', describeEnvironment());

  console.log('loadPathModule():', await loadPathModule());
  console.log('loadByName("os"):', await loadByName('os'), 'exports');
  console.log('loadPlatformHelper(false):', await loadPlatformHelper(false));
  console.log('loadWithThen():', await loadWithThen());
  console.log('loadDestructured():', await loadDestructured());
  console.log('loadMany():', await loadMany());

  const seq = await loadSequentially(['path', 'url']);
  console.log('loadSequentially:', seq);

  const crypto1 = await getCrypto();
  const crypto2 = await getCrypto();
  console.log('crypto singleton cached:', crypto1 === crypto2);
}

// No top-level await here — that would make this file Module-only.
main().catch((err) => {
  console.error('Demo failed:', err);
  if (typeof process !== 'undefined') process.exitCode = 1;
});
