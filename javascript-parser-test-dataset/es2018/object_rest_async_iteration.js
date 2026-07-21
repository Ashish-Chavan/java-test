/**
 * ES2018 (ES9) Feature: Object Rest/Spread, Async Iteration (for await...of),
 * Promise.prototype.finally
 */
'use strict';

// ── Object spread in literals ──────────────────────────────────────────────
const defaults = { theme: 'light', fontSize: 14, sidebar: true };
const userPrefs = { theme: 'dark', fontSize: 16 };

const settings = { ...defaults, ...userPrefs };
console.log(settings);   // later spreads win

// Spread with additional properties
const withMeta = { ...settings, updatedAt: '2024-01-15', version: 2 };
console.log(withMeta);

// Conditional spread — very common real-world pattern
const includeDebug = true;
const config = {
  host: 'localhost',
  ...(includeDebug && { debug: true, logLevel: 'verbose' }),
  ...(false && { neverIncluded: true }),
};
console.log(config);

// Shallow copy semantics
const original = { a: 1, nested: { b: 2 } };
const copy = { ...original };
copy.a = 99;
copy.nested.b = 99;         // nested objects are shared!
console.log(original.a, original.nested.b);   // 1, 99

// ── Object rest in destructuring ───────────────────────────────────────────
const user = {
  id: 1,
  name: 'Alice',
  email: 'alice@example.com',
  password: 'hunter2',
  createdAt: '2020-01-01',
};

// Classic use: strip sensitive fields
const { password, ...safeUser } = user;
console.log(safeUser);

// Rest in function params
function updateUser({ id, ...fields }) {
  return `Updating user ${id} with: ${Object.keys(fields).join(', ')}`;
}
console.log(updateUser({ id: 42, name: 'Bob', email: 'bob@x.com' }));

// Nested destructuring + rest
const response = {
  status: 200,
  headers: { 'content-type': 'application/json', 'x-request-id': 'abc' },
  body: { data: [1, 2, 3] },
};
const { status, headers: { 'content-type': contentType, ...otherHeaders }, ...restResponse } = response;
console.log(status, contentType, otherHeaders, Object.keys(restResponse));

// ── Async iteration: for await...of ────────────────────────────────────────
const delay = (ms, v) => new Promise(res => setTimeout(() => res(v), ms));

// Async generator producing values over time
async function* fetchPages(total) {
  for (let page = 1; page <= total; page++) {
    const data = await delay(5, { page, items: [`item-${page}a`, `item-${page}b`] });
    yield data;
  }
}

// Async iterable class via Symbol.asyncIterator
class EventStream {
  constructor(events) {
    this.events = events;
  }

  async *[Symbol.asyncIterator]() {
    for (const event of this.events) {
      await delay(2);
      yield event;
    }
  }
}

// for await over an array of promises
async function processPromiseArray() {
  const promises = [delay(10, 'first'), delay(5, 'second'), delay(1, 'third')];
  const results = [];
  for await (const value of promises) {
    results.push(value);       // resolves in ARRAY order, not completion order
  }
  return results;
}

// ── Promise.prototype.finally ──────────────────────────────────────────────
function fetchWithCleanup(shouldFail) {
  let connectionOpen = true;

  const work = shouldFail
    ? Promise.reject(new Error('fetch failed'))
    : Promise.resolve({ data: 'payload' });

  return work
    .then(result => `success: ${JSON.stringify(result)}`)
    .catch(err => `error: ${err.message}`)
    .finally(() => {
      connectionOpen = false;    // runs on BOTH success and failure
      console.log('  finally: connection closed');
    });
}

// finally passes through values and errors untouched
Promise.resolve('passthrough')
  .finally(() => 'this return value is ignored')
  .then(v => console.log(`finally passthrough: ${v}`));

// ── Main async runner ──────────────────────────────────────────────────────
(async () => {
  console.log('\n=== for await...of ===');

  for await (const page of fetchPages(3)) {
    console.log(`page ${page.page}:`, page.items);
  }

  const stream = new EventStream(['login', 'click', 'purchase', 'logout']);
  const seen = [];
  for await (const evt of stream) {
    seen.push(evt);
  }
  console.log('events:', seen);

  console.log('promise array:', await processPromiseArray());

  console.log('\n=== Promise.finally ===');
  console.log(await fetchWithCleanup(false));
  console.log(await fetchWithCleanup(true));

  // Async generator with yield* delegation
  async function* combined() {
    yield* fetchPages(2);
    yield { page: 'extra', items: [] };
  }
  const pages = [];
  for await (const p of combined()) pages.push(p.page);
  console.log('combined pages:', pages);
})();
