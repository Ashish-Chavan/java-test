#!/usr/bin/env node
/**
 * ES2023 (ES14) Feature: Change Array by Copy (toSorted, toReversed,
 * toSpliced, with), findLast/findLastIndex, Hashbang Grammar
 *
 * ⚠ PARSER TEST CASE: Line 1 is a hashbang (#!) — standardized in ES2023.
 * A parser must accept #! ONLY as the very first line of a file.
 */
'use strict';

// ── toSorted() — non-mutating sort ─────────────────────────────────────────
const scores = [42, 7, 99, 23, 65];

const ascending = scores.toSorted((a, b) => a - b);
const descending = scores.toSorted((a, b) => b - a);

console.log(ascending);
console.log(descending);
console.log(scores);              // ORIGINAL UNCHANGED — the whole point

// Compare with mutating sort:
const mutated = [...scores];
mutated.sort((a, b) => a - b);    // old way needed a manual copy first

// Default lexicographic sort
console.log(['banana', 'Apple', 'cherry'].toSorted());
console.log([10, 9, 100, 1].toSorted());          // lexicographic gotcha: [1,10,100,9]
console.log([10, 9, 100, 1].toSorted((a, b) => a - b));

// ── toReversed() — non-mutating reverse ────────────────────────────────────
const timeline = ['boot', 'login', 'browse', 'purchase', 'logout'];

const newest_first = timeline.toReversed();
console.log(newest_first);
console.log(timeline);            // unchanged

// Chainable — no intermediate copies needed
const topThreeReversed = scores.toSorted((a, b) => b - a).slice(0, 3).toReversed();
console.log(topThreeReversed);

// ── toSpliced() — non-mutating splice ──────────────────────────────────────
const weekdays = ['Mon', 'Tue', 'Thu', 'Fri'];

const fixed = weekdays.toSpliced(2, 0, 'Wed');          // insert at 2
console.log(fixed);
console.log(weekdays);            // unchanged

const replaced = weekdays.toSpliced(0, 2, 'Sat', 'Sun');  // replace first two
console.log(replaced);

const removed = weekdays.toSpliced(1, 2);               // remove 2 from index 1
console.log(removed);

// ── with() — non-mutating single-element replacement ───────────────────────
const grid = ['empty', 'empty', 'empty', 'empty'];

const placed = grid.with(2, 'X');
console.log(placed);
console.log(grid);                // unchanged

// Negative index works
console.log(grid.with(-1, 'O'));

// Chained with() for immutable updates — React-style state patterns
const board = [1, 2, 3, 4, 5];
const updated = board.with(0, 10).with(4, 50);
console.log(updated);

// Practical: immutable state update (Redux/React style)
const todos = [
  { id: 1, text: 'Learn ES2023', done: false },
  { id: 2, text: 'Test parser', done: false },
];

const toggleIndex = todos.findIndex(t => t.id === 1);
const newTodos = todos.with(toggleIndex, { ...todos[toggleIndex], done: true });
console.log(newTodos[0].done, todos[0].done);   // true, false — original intact

// ── findLast() and findLastIndex() ─────────────────────────────────────────
const events = [
  { type: 'error', code: 500, time: 1 },
  { type: 'info',  code: 200, time: 2 },
  { type: 'error', code: 404, time: 3 },
  { type: 'info',  code: 200, time: 4 },
];

// find() searches front-to-back; findLast() back-to-front
const firstError = events.find(e => e.type === 'error');
const lastError  = events.findLast(e => e.type === 'error');

console.log(`first error: code ${firstError.code} at t=${firstError.time}`);
console.log(`last error:  code ${lastError.code} at t=${lastError.time}`);

console.log(events.findIndex(e => e.type === 'error'));       // 0
console.log(events.findLastIndex(e => e.type === 'error'));   // 2

// No match cases
console.log(events.findLast(e => e.type === 'fatal'));        // undefined
console.log(events.findLastIndex(e => e.type === 'fatal'));   // -1

// Practical: latest matching log entry (before ES2023: reverse-then-find, or loop)
const measurements = [3.2, 4.1, 5.7, 4.9, 6.2, 4.4];
const lastBelowFive = measurements.findLast(m => m < 5);
console.log(`most recent sub-5 reading: ${lastBelowFive}`);

// ── TypedArray support ─────────────────────────────────────────────────────
const samples = new Float64Array([0.5, 0.1, 0.9, 0.3]);
console.log(samples.toSorted());
console.log(samples.toReversed());
console.log(samples.with(0, 0.99));
console.log(samples.findLast(s => s < 0.5));
// Note: toSpliced does NOT exist on TypedArrays (fixed length)

// ── Symbols as WeakMap keys (also ES2023) ──────────────────────────────────
const weakMap = new WeakMap();
const uniqueSym = Symbol('unregistered symbol');

weakMap.set(uniqueSym, 'symbols can be weakmap keys now');
console.log(weakMap.get(uniqueSym));

// Registered symbols still NOT allowed
try {
  weakMap.set(Symbol.for('registered'), 'nope');
} catch (e) {
  console.log(`registered symbol as key: ${e.constructor.name}`);
}
