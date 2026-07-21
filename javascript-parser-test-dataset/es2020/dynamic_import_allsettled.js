/**
 * ES2020 (ES11) Feature: Dynamic import(), globalThis,
 * Promise.allSettled, String.matchAll
 */
'use strict';

// ── globalThis ─────────────────────────────────────────────────────────────
// One universal way to reach the global object.
// Before: window (browser) / global (Node) / self (workers) / this (sloppy mode)

console.log(typeof globalThis);              // 'object' everywhere

globalThis.APP_VERSION = '2.1.0';
console.log(globalThis.APP_VERSION);

// Environment detection using globalThis
const environment =
  typeof globalThis.window !== 'undefined' ? 'browser' :
  typeof globalThis.process !== 'undefined' ? 'node' :
  'unknown';
console.log(`Running in: ${environment}`);

// ── String.prototype.matchAll ──────────────────────────────────────────────
// Returns an iterator of ALL match objects (with groups) — g flag required

const text = 'Contact: alice@example.com and bob@test.org or carol@demo.net';
const emailPattern = /(?<user>\w+)@(?<domain>[\w.]+)/g;

// matchAll returns full match objects, unlike match with /g
for (const match of text.matchAll(emailPattern)) {
  console.log(`  ${match[0]} -> user=${match.groups.user}, domain=${match.groups.domain} at index ${match.index}`);
}

// Collect into array
const allMatches = [...text.matchAll(emailPattern)];
console.log(`Found ${allMatches.length} emails`);

// Compare: match with /g loses capture groups
console.log(text.match(emailPattern));       // just the full strings

// Practical: template variable extraction
const template = 'Hello {{name}}, your order {{orderId}} ships {{date}}';
const vars = [...template.matchAll(/\{\{(\w+)\}\}/g)].map(m => m[1]);
console.log(`Template vars: ${vars}`);

// Practical: parsing key=value pairs
const queryString = 'page=2&limit=10&sort=name&order=asc';
const params = Object.fromEntries(
  [...queryString.matchAll(/(\w+)=(\w+)/g)].map(m => [m[1], m[2]])
);
console.log(params);

// ── Promise.allSettled ─────────────────────────────────────────────────────
// Waits for ALL promises — never rejects, reports each outcome

const delay = (ms, v) => new Promise(res => setTimeout(() => res(v), ms));
const failAfter = (ms, msg) => new Promise((_, rej) => setTimeout(() => rej(new Error(msg)), ms));

(async () => {
  console.log('\n=== Promise.allSettled ===');

  const results = await Promise.allSettled([
    delay(10, 'first success'),
    failAfter(5, 'second failed'),
    delay(15, 'third success'),
    Promise.reject(new Error('instant failure')),
    Promise.resolve('instant success'),
  ]);

  for (const [i, result] of results.entries()) {
    if (result.status === 'fulfilled') {
      console.log(`  [${i}] fulfilled: ${result.value}`);
    } else {
      console.log(`  [${i}] rejected: ${result.reason.message}`);
    }
  }

  // Practical: batch operations where partial failure is acceptable
  const urls = ['api/users', 'api/orders', 'api/broken', 'api/products'];
  const fetches = urls.map(url =>
    url.includes('broken')
      ? failAfter(5, `404 for ${url}`)
      : delay(5, { url, data: 'payload' })
  );

  const outcomes = await Promise.allSettled(fetches);
  const succeeded = outcomes.filter(o => o.status === 'fulfilled').map(o => o.value.url);
  const failed = outcomes.filter(o => o.status === 'rejected').map(o => o.reason.message);

  console.log(`  Succeeded: ${succeeded.join(', ')}`);
  console.log(`  Failed: ${failed.join(', ')}`);

  // Contrast with Promise.all — fails fast on first rejection
  try {
    await Promise.all(fetches.map(() => failAfter(1, 'boom')));
  } catch (e) {
    console.log(`  Promise.all rejects immediately: ${e.message}`);
  }

  // ── Dynamic import() ─────────────────────────────────────────────────────
  console.log('\n=== Dynamic import() ===');

  // import() is a syntax form (not a function!) returning a promise.
  // Works in both scripts and modules — unlike static import.

  try {
    // Conditional loading — the primary use case
    const moduleName = 'path';
    const mod = await import(moduleName);           // computed specifier!
    console.log(`  Loaded '${moduleName}':`, typeof mod.join === 'function' ? 'has join()' : 'unknown');

    // Destructuring the namespace object
    const { basename, extname } = await import('path');
    console.log(`  basename: ${basename('/foo/bar/baz.txt')}`);
    console.log(`  extname:  ${extname('script.test.js')}`);
  } catch (e) {
    console.log(`  import failed (expected outside Node): ${e.constructor.name}`);
  }

  // Lazy loading pattern
  let heavyModule = null;
  async function getHeavyModule() {
    if (!heavyModule) {
      heavyModule = await import('util');           // loaded once, on demand
      console.log('  heavy module loaded lazily');
    }
    return heavyModule;
  }
  await getHeavyModule();
  await getHeavyModule();                           // second call: cached

  // Error handling for missing modules
  try {
    await import('this-module-does-not-exist-xyz');
  } catch (e) {
    console.log(`  missing module: ${e.code || e.constructor.name}`);
  }
})();

// ── import.meta (companion feature) ────────────────────────────────────────
// Only valid inside modules — in this .js script it would be a SyntaxError:
// console.log(import.meta.url);   // SyntaxError in non-module context
// (See the modules/ folder for import.meta usage in .mjs files)
