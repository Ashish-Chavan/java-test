/**
 * ES2017 (ES8) Feature: Object.entries/values, String padding,
 * Object.getOwnPropertyDescriptors, trailing commas in function params
 */
'use strict';

// ── Object.values() ────────────────────────────────────────────────────────
const scores = { alice: 95, bob: 87, carol: 92 };

console.log(Object.values(scores));                    // [95, 87, 92]
console.log(Object.values(scores).reduce((a, b) => a + b, 0));

const average = Object.values(scores).reduce((a, b) => a + b, 0) / Object.values(scores).length;
console.log(`Average: ${average.toFixed(1)}`);

// Works on arrays and strings too
console.log(Object.values([10, 20, 30]));
console.log(Object.values('abc'));

// ── Object.entries() ───────────────────────────────────────────────────────
console.log(Object.entries(scores));
// [['alice', 95], ['bob', 87], ['carol', 92]]

// The killer combo: entries + destructuring in for-of
for (const [name, score] of Object.entries(scores)) {
  console.log(`${name}: ${score}`);
}

// Object -> Map conversion
const scoreMap = new Map(Object.entries(scores));
console.log(scoreMap.get('alice'));

// Filtering objects via entries
const passing = Object.entries(scores)
  .filter(([, score]) => score >= 90)
  .map(([name]) => name);
console.log(`Passing: ${passing}`);

// Transforming objects (pre-fromEntries pattern)
const doubled = Object.entries(scores).reduce((acc, [k, v]) => {
  acc[k] = v * 2;
  return acc;
}, {});
console.log(doubled);

// ── String.prototype.padStart / padEnd ─────────────────────────────────────
console.log('5'.padStart(3, '0'));           // '005'
console.log('42'.padStart(8));               // '      42' (default pad = space)
console.log('7'.padStart(2, '0'));           // '07'

console.log('Name'.padEnd(15, '.') + 'Value');
console.log('abc'.padEnd(10, '123'));        // 'abc1231231'

// Practical: formatting a table
const inventory = [
  ['Widget', 42, 9.99],
  ['Gadget', 7, 24.95],
  ['Doohickey', 156, 4.49],
];

console.log('Item'.padEnd(12) + 'Qty'.padStart(6) + 'Price'.padStart(10));
console.log('-'.repeat(28));
for (const [item, qty, price] of inventory) {
  console.log(
    item.padEnd(12) +
    String(qty).padStart(6) +
    `$${price.toFixed(2)}`.padStart(10)
  );
}

// Practical: masking sensitive data
function maskCard(number) {
  return number.slice(-4).padStart(number.length, '*');
}
console.log(maskCard('4242424242424242'));

// Practical: binary/hex formatting
console.log((255).toString(2).padStart(8, '0'));    // 11111111
console.log((5).toString(2).padStart(8, '0'));      // 00000101
console.log((255).toString(16).padStart(4, '0'));   // 00ff

// Time formatting
function formatTime(h, m, s) {
  const pad = n => String(n).padStart(2, '0');
  return `${pad(h)}:${pad(m)}:${pad(s)}`;
}
console.log(formatTime(9, 5, 3));

// ── Object.getOwnPropertyDescriptors ───────────────────────────────────────
const source = {
  regular: 'value',
  get computed() { return this.regular.toUpperCase(); },
};

const descriptors = Object.getOwnPropertyDescriptors(source);
console.log(Object.keys(descriptors));
console.log(typeof descriptors.computed.get);   // 'function' — getter preserved

// Proper shallow clone that keeps getters/setters (Object.assign would evaluate them)
const clone = Object.create(
  Object.getPrototypeOf(source),
  Object.getOwnPropertyDescriptors(source)
);
console.log(clone.computed);    // getter still works
source.regular = 'changed';
console.log(clone.computed);    // clone independent

// ── Trailing commas in function parameters/calls ───────────────────────────
// (a grammar change — significant for parsers even though invisible at runtime)

function withTrailingComma(
  first,
  second,
  third,        // <- trailing comma in params: legal since ES2017
) {
  return [first, second, third];
}

const result = withTrailingComma(
  1,
  2,
  3,            // <- trailing comma in call: legal since ES2017
);
console.log(result);

const arrowTrailing = (
  a,
  b,
) => a + b;
console.log(arrowTrailing(10, 20));

class TrailingInMethods {
  method(
    x,
    y,
  ) {
    return x * y;
  }
}
console.log(new TrailingInMethods().method(6, 7));
