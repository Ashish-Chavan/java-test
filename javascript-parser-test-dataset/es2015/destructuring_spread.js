/**
 * ES2015 (ES6) Feature: Destructuring, Rest, Spread
 * Array/object destructuring, nested patterns, defaults,
 * rest parameters, spread in calls and literals.
 */
'use strict';

// ── Array destructuring ────────────────────────────────────────────────────
const rgb = [255, 165, 0];
const [red, green, blue] = rgb;
console.log(red, green, blue);

// Skipping elements
const [first, , third] = ['a', 'b', 'c'];
console.log(first, third);

// Defaults
const [x = 0, y = 0, z = 0] = [10, 20];
console.log(x, y, z);

// Swap without temp variable
let a = 1, b = 2;
[a, b] = [b, a];
console.log(a, b);

// Rest in array destructuring
const [head, ...tail] = [1, 2, 3, 4, 5];
console.log(head, tail);

// Nested array destructuring
const matrix = [[1, 2], [3, 4]];
const [[m00, m01], [m10, m11]] = matrix;
console.log(m00, m01, m10, m11);

// From function return
function minMax(arr) {
  return [Math.min(...arr), Math.max(...arr)];
}
const [lo, hi] = minMax([3, 1, 4, 1, 5, 9]);
console.log(lo, hi);

// ── Object destructuring ───────────────────────────────────────────────────
const user = {
  id: 42,
  name: 'Alice',
  email: 'alice@example.com',
  address: { city: 'Springfield', zip: '12345' },
  roles: ['admin', 'editor'],
};

const { name, email } = user;
console.log(name, email);

// Renaming
const { id: userId, name: userName } = user;
console.log(userId, userName);

// Defaults
const { theme = 'dark', name: displayName = 'Anonymous' } = user;
console.log(theme, displayName);

// Nested object destructuring
const { address: { city, zip } } = user;
console.log(city, zip);

// Nested + rename + default
const { address: { city: town, country = 'USA' } } = user;
console.log(town, country);

// Mixed: object containing array
const { roles: [primaryRole, ...otherRoles] } = user;
console.log(primaryRole, otherRoles);

// Rest in object destructuring (technically ES2018 but commonly grouped)
const { id, ...rest } = user;
console.log(id, Object.keys(rest));

// ── Destructuring in function parameters ───────────────────────────────────
function greet({ name, greeting = 'Hello' }) {
  return `${greeting}, ${name}!`;
}
console.log(greet({ name: 'Bob' }));
console.log(greet({ name: 'Carol', greeting: 'Hi' }));

function drawChart({ size = 'big', coords = { x: 0, y: 0 }, radius = 25 } = {}) {
  return `size=${size}, at (${coords.x},${coords.y}), r=${radius}`;
}
console.log(drawChart());
console.log(drawChart({ coords: { x: 18, y: 30 }, radius: 30 }));

// Array param destructuring
function distance([x1, y1], [x2, y2]) {
  return Math.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2);
}
console.log(distance([0, 0], [3, 4]));

// ── Rest parameters ────────────────────────────────────────────────────────
function sum(...numbers) {
  return numbers.reduce((acc, n) => acc + n, 0);
}
console.log(sum(1, 2, 3, 4, 5));

function tagged(first, second, ...others) {
  return { first, second, count: others.length };
}
console.log(tagged('a', 'b', 'c', 'd', 'e'));

// ── Spread in function calls ───────────────────────────────────────────────
const nums = [5, 2, 8, 1];
console.log(Math.max(...nums));
console.log(Math.min(...nums, 0));   // mix spread with regular args

// ── Spread in array literals ───────────────────────────────────────────────
const start = [1, 2];
const end = [5, 6];
const combined = [...start, 3, 4, ...end];
console.log(combined);

// Copy (shallow)
const copy = [...combined];
copy.push(7);
console.log(combined.length, copy.length);

// String spread
const chars = [...'hello'];
console.log(chars);

// Set/Map spread
const unique = [...new Set([1, 2, 2, 3, 3, 3])];
console.log(unique);

// ── Spread in object literals (ES2018 but grouped here) ────────────────────
const defaults = { theme: 'light', fontSize: 14 };
const overrides = { fontSize: 18, bold: true };
const settings = { ...defaults, ...overrides };
console.log(settings);

// ── Destructuring in loops ─────────────────────────────────────────────────
const entries = [['a', 1], ['b', 2], ['c', 3]];
for (const [key, value] of entries) {
  console.log(`${key} -> ${value}`);
}

const people = [
  { name: 'Dave', age: 30 },
  { name: 'Eve', age: 25 },
];
for (const { name: personName, age } of people) {
  console.log(`${personName} is ${age}`);
}
