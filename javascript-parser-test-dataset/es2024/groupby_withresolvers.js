/**
 * ES2024 (ES15) Feature: Object.groupBy / Map.groupBy,
 * Promise.withResolvers, RegExp v flag, String.isWellFormed
 */
'use strict';

// ── Object.groupBy ─────────────────────────────────────────────────────────
const inventory = [
  { name: 'asparagus', type: 'vegetable', qty: 5 },
  { name: 'banana',    type: 'fruit',     qty: 0 },
  { name: 'goat',      type: 'meat',      qty: 23 },
  { name: 'cherry',    type: 'fruit',     qty: 5 },
  { name: 'fish',      type: 'meat',      qty: 22 },
];

// Group by property
const byType = Object.groupBy(inventory, item => item.type);
console.log(Object.keys(byType));
console.log(byType.fruit.map(i => i.name));
console.log(byType.meat.map(i => i.name));

// Group by computed key
const byStock = Object.groupBy(inventory, ({ qty }) =>
  qty === 0 ? 'outOfStock' : qty < 10 ? 'low' : 'plenty'
);
console.log(byStock.outOfStock?.map(i => i.name));
console.log(byStock.low?.map(i => i.name));
console.log(byStock.plenty?.map(i => i.name));

// Group numbers
const nums = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
const parity = Object.groupBy(nums, n => n % 2 === 0 ? 'even' : 'odd');
console.log(parity);

// Result has null prototype — hasOwnProperty not available directly
const groups = Object.groupBy([1], () => 'key');
console.log(Object.getPrototypeOf(groups));          // null — parser/runtime nuance
console.log(Object.hasOwn(groups, 'key'));           // use hasOwn instead

// ── Map.groupBy ────────────────────────────────────────────────────────────
// Same idea but returns a Map — keys can be ANY value, including objects

const restock = { restock: true };
const sufficient = { restock: false };

const restockMap = Map.groupBy(inventory, ({ qty }) => qty < 6 ? restock : sufficient);
console.log(restockMap.get(restock).map(i => i.name));       // object as key!
console.log(restockMap.get(sufficient).map(i => i.name));

// Grouping by numeric ranges into a Map
const grades = [95, 82, 67, 88, 74, 91, 55];
const gradeMap = Map.groupBy(grades, score =>
  score >= 90 ? 'A' : score >= 80 ? 'B' : score >= 70 ? 'C' : 'F'
);
for (const [grade, scores] of gradeMap) {
  console.log(`${grade}: ${scores.join(', ')}`);
}

// ── Promise.withResolvers ──────────────────────────────────────────────────
// Returns { promise, resolve, reject } — no more "executor escape" hack

// The OLD pattern this replaces:
let oldResolve;
const oldPromise = new Promise((res) => { oldResolve = res; });   // awkward!

// The ES2024 way:
const { promise, resolve, reject } = Promise.withResolvers();

setTimeout(() => resolve('resolved externally!'), 10);

// Practical: event-to-promise bridging
class TaskQueue {
  #queue = [];
  #waiting = null;

  push(task) {
    if (this.#waiting) {
      const { resolve } = this.#waiting;
      this.#waiting = null;
      resolve(task);                       // hand directly to waiter
    } else {
      this.#queue.push(task);
    }
  }

  async next() {
    if (this.#queue.length > 0) {
      return this.#queue.shift();
    }
    // Nothing queued — create externally-resolvable promise and wait
    this.#waiting = Promise.withResolvers();
    return this.#waiting.promise;
  }
}

// Practical: cancellable deferred
function deferredWithTimeout(ms) {
  const { promise, resolve, reject } = Promise.withResolvers();
  const timer = setTimeout(() => reject(new Error(`timed out after ${ms}ms`)), ms);
  return {
    promise,
    complete(value) { clearTimeout(timer); resolve(value); },
  };
}

// ── RegExp v flag — set notation and string properties ────────────────────
// Superset of the u flag with set operations in character classes

// Set difference: \p{Letter} minus vowels
const consonants = /[\p{Letter}--[aeiouAEIOU]]/gv;
console.log('Hello World'.match(consonants).join(''));

// Set intersection: letters AND ASCII
const asciiLetters = /[\p{Letter}&&\p{ASCII}]/gv;
console.log('abc-Δδ-123-xyz'.match(asciiLetters).join(''));

// Nested character classes
const digitsOrDashes = /[[0-9][-]]+/gv;
console.log('phone: 555-123-4567'.match(digitsOrDashes));

// Properties of strings — multi-codepoint matching (v-flag exclusive)
const flagEmoji = /\p{RGI_Emoji}/v;
console.log(flagEmoji.test('🇺🇸'));                  // true — TWO code points!
console.log(flagEmoji.test('👨‍👩‍👧‍👦'));                 // family = many code points

// flags introspection
const vRegex = /[\p{Letter}]/v;
console.log(vRegex.unicodeSets);                    // true
console.log(vRegex.flags);                          // 'v'

// ── String.isWellFormed / toWellFormed ─────────────────────────────────────
// Detect and repair lone surrogates (invalid UTF-16)

const good = 'hello 🌍';
const lone = 'broken \uD800 surrogate';              // unpaired high surrogate

console.log(good.isWellFormed());                   // true
console.log(lone.isWellFormed());                   // false

const repaired = lone.toWellFormed();               // lone surrogate -> U+FFFD
console.log(repaired.isWellFormed());               // true
console.log(repaired.includes('\uFFFD'));           // true — replacement char

// Practical: safe encodeURI (throws on lone surrogates otherwise)
function safeEncode(str) {
  return encodeURI(str.toWellFormed());
}
console.log(safeEncode(lone).slice(0, 30));

// ── Async runner for the promise demos ─────────────────────────────────────
(async () => {
  console.log(await promise);

  const q = new TaskQueue();
  setTimeout(() => q.push('task-A'), 5);
  console.log(`dequeued: ${await q.next()}`);       // waits for push

  q.push('task-B');                                 // queued before next()
  console.log(`dequeued: ${await q.next()}`);       // immediate

  const d = deferredWithTimeout(50);
  d.complete('finished in time');
  console.log(await d.promise);

  const late = deferredWithTimeout(5);
  try {
    await late.promise;
  } catch (e) {
    console.log(e.message);
  }
})();
