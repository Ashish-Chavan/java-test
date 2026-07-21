/**
 * ES2017 (ES8) Feature: async/await
 * Asynchronous functions that read like synchronous code.
 * async function declarations, expressions, arrows, methods.
 */
'use strict';

// ── Helper: simulated async operations ────────────────────────────────────
const delay = (ms, value) => new Promise(resolve => setTimeout(() => resolve(value), ms));
const fail = (ms, message) => new Promise((_, reject) => setTimeout(() => reject(new Error(message)), ms));

// ── async function declaration ─────────────────────────────────────────────
async function fetchUser(id) {
  const user = await delay(10, { id, name: `User${id}` });
  return user;
}

// ── async function expression ──────────────────────────────────────────────
const fetchScore = async function (userId) {
  return await delay(10, userId * 10);
};

// ── async arrow function ───────────────────────────────────────────────────
const fetchStatus = async (id) => {
  const status = await delay(5, id % 2 === 0 ? 'active' : 'inactive');
  return status;
};

// ── async methods in classes and objects ───────────────────────────────────
class ApiClient {
  constructor(baseUrl) {
    this.baseUrl = baseUrl;
  }

  async get(path) {
    await delay(5);
    return { url: `${this.baseUrl}${path}`, status: 200 };
  }

  // async + static
  static async healthCheck() {
    return await delay(5, 'healthy');
  }
}

const service = {
  name: 'orders',
  async list() {                              // shorthand async method
    return await delay(5, ['order-1', 'order-2']);
  },
};

// ── Sequential vs parallel await ───────────────────────────────────────────
async function sequential() {
  const start = Date.now();
  const a = await delay(20, 'a');             // waits 20ms
  const b = await delay(20, 'b');             // waits another 20ms
  return { values: [a, b], elapsed: Date.now() - start };
}

async function parallel() {
  const start = Date.now();
  const [a, b] = await Promise.all([          // both run concurrently
    delay(20, 'a'),
    delay(20, 'b'),
  ]);
  return { values: [a, b], elapsed: Date.now() - start };
}

// ── Error handling: try/catch with await ───────────────────────────────────
async function robustFetch(shouldFail) {
  try {
    if (shouldFail) {
      await fail(5, 'Network timeout');
    }
    return await delay(5, 'success');
  } catch (err) {
    return `caught: ${err.message}`;
  } finally {
    // cleanup runs either way
  }
}

// Rejected promise from async function = throw
async function alwaysThrows() {
  throw new Error('async functions wrap throws in rejected promises');
}

// ── await with non-promise values ──────────────────────────────────────────
async function awaitNonPromise() {
  const plain = await 42;                     // wrapped in Promise.resolve
  const thenable = await {                    // custom thenables work too
    then(resolve) { resolve('from thenable'); },
  };
  return [plain, thenable];
}

// ── async in loops ─────────────────────────────────────────────────────────
async function processSequentially(ids) {
  const results = [];
  for (const id of ids) {
    results.push(await fetchUser(id));        // one at a time
  }
  return results;
}

async function processInParallel(ids) {
  return Promise.all(ids.map(id => fetchUser(id)));   // all at once
}

// ── async IIFE ─────────────────────────────────────────────────────────────
(async () => {
  console.log('=== async/await demo ===');

  const user = await fetchUser(1);
  console.log('user:', user);

  const score = await fetchScore(user.id);
  console.log('score:', score);

  console.log('status:', await fetchStatus(2));

  const client = new ApiClient('https://api.example.com');
  console.log('get:', await client.get('/users'));
  console.log('health:', await ApiClient.healthCheck());
  console.log('orders:', await service.list());

  const seq = await sequential();
  const par = await parallel();
  console.log(`sequential took ~${seq.elapsed}ms, parallel took ~${par.elapsed}ms`);

  console.log(await robustFetch(false));
  console.log(await robustFetch(true));

  try {
    await alwaysThrows();
  } catch (e) {
    console.log('caught from async throw:', e.message);
  }

  console.log('non-promise awaits:', await awaitNonPromise());

  const seqUsers = await processSequentially([1, 2, 3]);
  console.log('sequential users:', seqUsers.map(u => u.name));

  const parUsers = await processInParallel([4, 5, 6]);
  console.log('parallel users:', parUsers.map(u => u.name));

  // await in conditions and expressions
  if (await fetchStatus(4) === 'active') {
    console.log('user 4 is active');
  }

  const combined = `${await delay(1, 'Hello')}, ${await delay(1, 'World')}!`;
  console.log(combined);
})();
