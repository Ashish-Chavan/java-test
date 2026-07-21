/**
 * ES2021 (ES12) Feature: String.replaceAll, Promise.any,
 * WeakRef, FinalizationRegistry
 */
'use strict';

// ── String.prototype.replaceAll ────────────────────────────────────────────
const sentence = 'the cat sat on the mat with the hat';

// Before ES2021: replace only did the FIRST occurrence with a string
console.log(sentence.replace('the', 'a'));       // only first 'the'

// Old workarounds: global regex or split/join
console.log(sentence.replace(/the/g, 'a'));
console.log(sentence.split('the').join('a'));

// ES2021: replaceAll — clean and intention-revealing
console.log(sentence.replaceAll('the', 'a'));

// No regex escaping needed for special characters — the big win!
const price = 'Costs $5. Save $2. Final: $3.';
console.log(price.replaceAll('$', '€'));
// vs regex which needs: price.replace(/\$/g, '€')

const code = 'a.b.c.d';
console.log(code.replaceAll('.', '/'));
// vs regex: code.replace(/\./g, '/') — unescaped . would match everything!

// With replacer function
const template = 'x + x = 2x';
let counter = 0;
console.log(template.replaceAll('x', () => `x${++counter}`));

// With special replacement patterns
console.log('john smith'.replaceAll(/(\w+)/g, '[$1]'));

// replaceAll with regex REQUIRES the g flag — parser/runtime test case
try {
  'test'.replaceAll(/t/, 'T');       // TypeError: non-global regex
} catch (e) {
  console.log(`non-global regex: ${e.constructor.name}`);
}
console.log('test'.replaceAll(/t/g, 'T'));   // fine with /g

// Practical: sanitizing
function escapeHtml(str) {
  return str
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}
console.log(escapeHtml('<script>alert("xss")</script>'));

// ── Promise.any ────────────────────────────────────────────────────────────
// Resolves with the FIRST fulfilled promise; rejects only if ALL reject
// (with AggregateError). Compare: race takes first settled (even rejection).

const delay = (ms, v) => new Promise(res => setTimeout(() => res(v), ms));
const failAfter = (ms, msg) => new Promise((_, rej) => setTimeout(() => rej(new Error(msg)), ms));

(async () => {
  console.log('\n=== Promise.any ===');

  // First success wins — failures before it are ignored
  const fastest = await Promise.any([
    failAfter(1, 'mirror-1 down'),        // fails first but ignored
    delay(20, 'mirror-2 response'),
    delay(10, 'mirror-3 response'),       // first SUCCESS
  ]);
  console.log(`  fastest success: ${fastest}`);

  // Compare with race — first settled wins, including rejections
  try {
    await Promise.race([
      failAfter(1, 'fast failure'),
      delay(20, 'slow success'),
    ]);
  } catch (e) {
    console.log(`  race rejected with: ${e.message}`);
  }

  // All reject -> AggregateError
  try {
    await Promise.any([
      failAfter(1, 'server A down'),
      failAfter(2, 'server B down'),
      failAfter(3, 'server C down'),
    ]);
  } catch (e) {
    console.log(`  ${e.constructor.name}: ${e.message}`);
    console.log(`  individual errors: ${e.errors.map(err => err.message).join('; ')}`);
  }

  // Practical: redundant endpoint fetching
  async function fetchFromMirrors(mirrors) {
    try {
      return await Promise.any(mirrors.map(m =>
        m.healthy ? delay(m.latency, `data from ${m.name}`) : failAfter(1, `${m.name} unreachable`)
      ));
    } catch {
      return 'all mirrors down — using cache';
    }
  }

  console.log('  ' + await fetchFromMirrors([
    { name: 'us-east', healthy: false, latency: 5 },
    { name: 'eu-west', healthy: true, latency: 15 },
    { name: 'ap-south', healthy: true, latency: 8 },
  ]));

  // ── WeakRef ──────────────────────────────────────────────────────────────
  console.log('\n=== WeakRef ===');

  let bigObject = { data: new Array(1000).fill('x'), id: 'cache-entry-1' };
  const weakRef = new WeakRef(bigObject);

  // deref() returns the object if still alive, undefined if collected
  const alive = weakRef.deref();
  console.log(`  deref while alive: ${alive?.id}`);

  // Cache pattern: hold weakly, let GC reclaim under pressure
  class WeakCache {
    #map = new Map();

    set(key, value) {
      this.#map.set(key, new WeakRef(value));
    }

    get(key) {
      const ref = this.#map.get(key);
      const value = ref?.deref();
      if (ref && !value) this.#map.delete(key);   // clean up dead entry
      return value;
    }
  }

  const cache = new WeakCache();
  cache.set('user:1', bigObject);
  console.log(`  cache hit: ${cache.get('user:1')?.id}`);
  console.log(`  cache miss: ${cache.get('user:2')}`);

  // ── FinalizationRegistry ─────────────────────────────────────────────────
  console.log('\n=== FinalizationRegistry ===');

  const registry = new FinalizationRegistry((heldValue) => {
    // Called some time AFTER the registered object is garbage collected
    console.log(`  finalizer ran for: ${heldValue}`);
  });

  registry.register(bigObject, 'cache-entry-1 was collected');

  // Unregister token pattern
  const token = {};
  let tempResource = { name: 'temp' };
  registry.register(tempResource, 'temp collected', token);
  registry.unregister(token);          // cancel the callback

  console.log('  registered (finalizer timing is non-deterministic; may not print)');
  bigObject = null;                    // drop strong reference — GC eligible
})();
