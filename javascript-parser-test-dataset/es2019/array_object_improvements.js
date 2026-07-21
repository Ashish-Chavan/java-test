/**
 * ES2019 (ES10) Feature: Array.flat/flatMap, Object.fromEntries,
 * Optional catch binding, String.trimStart/trimEnd, Symbol.description
 */
'use strict';

// ── Array.prototype.flat ───────────────────────────────────────────────────
const nested = [1, [2, 3], [4, [5, 6]]];

console.log(nested.flat());        // [1, 2, 3, 4, [5, 6]] — depth 1 default
console.log(nested.flat(2));       // [1, 2, 3, 4, 5, 6]

const deeplyNested = [1, [2, [3, [4, [5]]]]];
console.log(deeplyNested.flat(Infinity));   // fully flattened

// flat() removes holes in sparse arrays
const sparse = [1, , 3, , 5];
console.log(sparse.flat());        // [1, 3, 5]

// ── Array.prototype.flatMap ────────────────────────────────────────────────
const sentences = ['hello world', 'foo bar baz', 'single'];

// map then flat(1) in one pass
const words = sentences.flatMap(s => s.split(' '));
console.log(words);

// Compare: map alone gives nested arrays
console.log(sentences.map(s => s.split(' ')));

// flatMap for filtering + mapping simultaneously (return [] to drop)
const numbers = [1, 2, 3, 4, 5, 6];
const evenDoubled = numbers.flatMap(n => n % 2 === 0 ? [n * 2] : []);
console.log(evenDoubled);          // [4, 8, 12]

// flatMap for expanding elements (return multiple)
const duplicated = [1, 2, 3].flatMap(n => [n, n]);
console.log(duplicated);           // [1, 1, 2, 2, 3, 3]

// Practical: extracting nested data
const orders = [
  { id: 1, items: ['apple', 'banana'] },
  { id: 2, items: ['cherry'] },
  { id: 3, items: ['date', 'elderberry', 'fig'] },
];
const allItems = orders.flatMap(order => order.items);
console.log(allItems);

// Practical: generating ranges with gaps
const ranges = [[1, 3], [7, 9]];
const expanded = ranges.flatMap(([start, end]) =>
  Array.from({ length: end - start + 1 }, (_, i) => start + i)
);
console.log(expanded);             // [1, 2, 3, 7, 8, 9]

// ── Object.fromEntries ─────────────────────────────────────────────────────
// The inverse of Object.entries
const entries = [['a', 1], ['b', 2], ['c', 3]];
console.log(Object.fromEntries(entries));

// Map -> Object
const map = new Map([['x', 10], ['y', 20]]);
console.log(Object.fromEntries(map));

// The transform pattern: entries -> transform -> fromEntries
const prices = { apple: 1.5, banana: 0.5, cherry: 3.0 };

const doubled = Object.fromEntries(
  Object.entries(prices).map(([k, v]) => [k, v * 2])
);
console.log(doubled);

const affordable = Object.fromEntries(
  Object.entries(prices).filter(([, price]) => price < 2)
);
console.log(affordable);

const renamed = Object.fromEntries(
  Object.entries(prices).map(([k, v]) => [k.toUpperCase(), v])
);
console.log(renamed);

// URLSearchParams -> Object (very common in web code)
const params = new URLSearchParams('page=2&limit=10&sort=name');
console.log(Object.fromEntries(params));

// ── Optional catch binding ─────────────────────────────────────────────────
// catch no longer requires the (error) parameter

function isValidJson(text) {
  try {
    JSON.parse(text);
    return true;
  } catch {                        // ← no (e) — new in ES2019
    return false;
  }
}
console.log(isValidJson('{"valid": true}'));
console.log(isValidJson('not json'));

function tryParseNumber(text) {
  try {
    const n = Number(text);
    if (Number.isNaN(n)) throw new Error();
    return n;
  } catch {
    return 0;
  }
}
console.log(tryParseNumber('42'));
console.log(tryParseNumber('abc'));

// Feature detection pattern
function supportsFeature() {
  try {
    new Intl.ListFormat('en');
    return true;
  } catch {
    return false;
  }
}
console.log(`Intl.ListFormat supported: ${supportsFeature()}`);

// ── String.trimStart / trimEnd ─────────────────────────────────────────────
const padded = '   hello world   ';
console.log(`[${padded.trimStart()}]`);
console.log(`[${padded.trimEnd()}]`);
console.log(`[${padded.trim()}]`);

// Practical: cleaning indented lines while keeping trailing structure
const lines = ['  first  ', '    second  ', '  third '];
console.log(lines.map(l => l.trimStart()));

// ── Symbol.prototype.description ───────────────────────────────────────────
const sym = Symbol('my description');
console.log(sym.description);          // 'my description' — no toString parsing
console.log(Symbol('').description);   // ''
console.log(Symbol().description);     // undefined

// ── Stable Array.prototype.sort (guaranteed in ES2019) ────────────────────
const students = [
  { name: 'Alice', grade: 'B' },
  { name: 'Bob', grade: 'A' },
  { name: 'Carol', grade: 'B' },
  { name: 'Dave', grade: 'A' },
];
// Equal keys keep original relative order — now guaranteed by spec
const sorted = [...students].sort((a, b) => a.grade.localeCompare(b.grade));
console.log(sorted.map(s => `${s.name}(${s.grade})`));
// Bob before Dave, Alice before Carol — stability guaranteed
