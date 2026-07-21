/**
 * ES2022 (ES13) Feature: Array/String .at(), Object.hasOwn,
 * Error cause option
 */
'use strict';

// ── .at() — relative indexing with negatives ──────────────────────────────
const letters = ['a', 'b', 'c', 'd', 'e'];

console.log(letters.at(0));       // 'a'
console.log(letters.at(2));       // 'c'
console.log(letters.at(-1));      // 'e' — THE feature: last element!
console.log(letters.at(-2));      // 'd'
console.log(letters.at(99));      // undefined — out of range
console.log(letters.at(-99));     // undefined

// Before .at(): the clunky alternatives
console.log(letters[letters.length - 1]);        // verbose
console.log(letters.slice(-1)[0]);               // allocates an array

// .at() on strings
const word = 'JavaScript';
console.log(word.at(0));          // 'J'
console.log(word.at(-1));         // 't'
console.log(word.at(-6));         // 'S'

// .at() on TypedArrays
const bytes = new Uint8Array([10, 20, 30, 40]);
console.log(bytes.at(-1));        // 40

// Practical: peek at stack/queue ends
class Stack {
  #items = [];
  push(v) { this.#items.push(v); return this; }
  pop() { return this.#items.pop(); }
  peek() { return this.#items.at(-1); }         // clean!
  peekSecond() { return this.#items.at(-2); }
}

const stack = new Stack().push(1).push(2).push(3);
console.log(stack.peek(), stack.peekSecond());

// Practical: last N elements pattern
const logs = ['boot', 'load', 'render', 'idle', 'click'];
console.log(`latest: ${logs.at(-1)}, previous: ${logs.at(-2)}`);

// ── Object.hasOwn ──────────────────────────────────────────────────────────
// Safe replacement for Object.prototype.hasOwnProperty.call(obj, key)

const config = { debug: true, port: 8080 };

console.log(Object.hasOwn(config, 'debug'));       // true
console.log(Object.hasOwn(config, 'toString'));    // false — inherited, not own
console.log('toString' in config);                 // true — `in` includes prototype chain

// Why hasOwn matters: objects without prototypes
const dict = Object.create(null);                  // no prototype at all
dict.key = 'value';

// dict.hasOwnProperty('key');                     // TypeError! no such method
console.log(Object.hasOwn(dict, 'key'));           // works fine

// Why hasOwn matters: shadowed hasOwnProperty
const sneaky = {
  hasOwnProperty() { return true; },               // lies!
  real: 1,
};
console.log(sneaky.hasOwnProperty('fake'));        // true — LIES
console.log(Object.hasOwn(sneaky, 'fake'));        // false — truth
console.log(Object.hasOwn(sneaky, 'real'));        // true

// Practical: safe iteration guard
function ownEntries(obj) {
  const result = [];
  for (const key in obj) {
    if (Object.hasOwn(obj, key)) {                 // skip inherited
      result.push([key, obj[key]]);
    }
  }
  return result;
}

const parent = { inherited: 'from proto' };
const child = Object.create(parent);
child.own1 = 'a';
child.own2 = 'b';
console.log(ownEntries(child));

// ── Error cause ────────────────────────────────────────────────────────────
// new Error(message, { cause }) — chain errors without losing the original

function readConfigFile() {
  throw new Error('ENOENT: config.json not found');
}

function loadConfig() {
  try {
    readConfigFile();
  } catch (err) {
    // Wrap with high-level context, preserve low-level cause
    throw new Error('Failed to load application config', { cause: err });
  }
}

function startApp() {
  try {
    loadConfig();
  } catch (err) {
    throw new Error('Application startup failed', { cause: err });
  }
}

try {
  startApp();
} catch (err) {
  // Walk the cause chain
  console.log('\nError chain:');
  let current = err;
  let depth = 0;
  while (current) {
    console.log(`${'  '.repeat(depth)}${depth > 0 ? '└ caused by: ' : ''}${current.message}`);
    current = current.cause;
    depth += 1;
  }
}

// cause works on all error types
const typeErr = new TypeError('bad type', { cause: 'raw string cause' });
console.log(typeErr.cause);        // cause can be ANY value, not just Error

const withData = new Error('validation failed', {
  cause: { field: 'email', value: 'not-an-email', rule: 'format' },
});
console.log(withData.cause);

// Practical: retry wrapper preserving last failure
async function withRetry(fn, attempts = 3) {
  let lastError;
  for (let i = 1; i <= attempts; i++) {
    try {
      return await fn(i);
    } catch (err) {
      lastError = err;
    }
  }
  throw new Error(`All ${attempts} attempts failed`, { cause: lastError });
}

(async () => {
  try {
    await withRetry(async (attempt) => {
      throw new Error(`attempt ${attempt} network timeout`);
    }, 2);
  } catch (err) {
    console.log(`${err.message} — last cause: ${err.cause.message}`);
  }
})();
