/**
 * ES2015 (ES6) Feature: Template Literals, Tagged Templates,
 * Symbols, Map, Set, WeakMap, WeakSet
 */
'use strict';

// ── Template literals ──────────────────────────────────────────────────────
const name = 'World';
const simple = `Hello, ${name}!`;
console.log(simple);

// Expressions
const a = 6, b = 7;
console.log(`${a} * ${b} = ${a * b}`);
console.log(`Result is ${a * b > 40 ? 'big' : 'small'}`);

// Multi-line strings (no \n concatenation needed)
const multiline = `Line one
Line two
Line three`;
console.log(multiline);

// Nested templates
const items = ['apple', 'banana'];
const html = `<ul>${items.map(i => `<li>${i}</li>`).join('')}</ul>`;
console.log(html);

// ── Tagged templates ───────────────────────────────────────────────────────
function highlight(strings, ...values) {
  return strings.reduce((acc, str, i) => {
    const val = i < values.length ? `[${values[i]}]` : '';
    return acc + str + val;
  }, '');
}

const user = 'Alice';
const score = 95;
console.log(highlight`User ${user} scored ${score} points`);

// Tag that returns non-string
function metadata(strings, ...values) {
  return { template: strings.raw.join('{}'), values };
}
console.log(metadata`x=${1}, y=${2}`);

// String.raw — raw escape sequences
console.log(String.raw`No newline: \n stays literal`);
console.log(`With newline: \n interpreted`);

const windowsPath = String.raw`C:\Users\alice\Documents`;
console.log(windowsPath);

// SQL-style tag (common real-world pattern)
function sql(strings, ...values) {
  const query = strings.join('?');
  return { query, params: values };
}
const minAge = 18;
const status = 'active';
console.log(sql`SELECT * FROM users WHERE age > ${minAge} AND status = ${status}`);

// ── Symbols ────────────────────────────────────────────────────────────────
const sym1 = Symbol('description');
const sym2 = Symbol('description');
console.log(sym1 === sym2);              // false — every Symbol is unique
console.log(sym1.toString());
console.log(sym1.description);

// Symbols as object keys (non-enumerable in for...in / Object.keys)
const HIDDEN = Symbol('hidden');
const obj = {
  visible: 'you can see me',
  [HIDDEN]: 'secret data',
};
console.log(Object.keys(obj));           // ['visible'] only
console.log(obj[HIDDEN]);                // accessible with the symbol
console.log(Object.getOwnPropertySymbols(obj));

// Global symbol registry
const globalSym = Symbol.for('app.config');
const sameSym = Symbol.for('app.config');
console.log(globalSym === sameSym);      // true — registry lookup
console.log(Symbol.keyFor(globalSym));

// Well-known symbols: Symbol.iterator
class Range {
  constructor(start, end) {
    this.start = start;
    this.end = end;
  }

  [Symbol.iterator]() {
    let current = this.start;
    const end = this.end;
    return {
      next() {
        return current <= end
          ? { value: current++, done: false }
          : { value: undefined, done: true };
      },
    };
  }
}
console.log([...new Range(1, 5)]);

// Symbol.toPrimitive
class Temperature {
  constructor(celsius) { this.celsius = celsius; }
  [Symbol.toPrimitive](hint) {
    if (hint === 'number') return this.celsius;
    if (hint === 'string') return `${this.celsius}°C`;
    return `Temperature(${this.celsius})`;
  }
}
const temp = new Temperature(25);
console.log(+temp);
console.log(`${temp}`);

// ── Map ────────────────────────────────────────────────────────────────────
const map = new Map();
map.set('string key', 1);
map.set(42, 'number key');
map.set(true, 'boolean key');

const objKey = { id: 1 };
map.set(objKey, 'object key!');          // objects as keys — impossible with {}

console.log(map.get('string key'));
console.log(map.get(objKey));
console.log(map.size);
console.log(map.has(42));

map.delete(true);
console.log(map.size);

// Iteration
const inventory = new Map([
  ['apples', 5],
  ['bananas', 12],
  ['cherries', 3],
]);

for (const [fruit, qty] of inventory) {
  console.log(`${fruit}: ${qty}`);
}
console.log([...inventory.keys()]);
console.log([...inventory.values()]);

// ── Set ────────────────────────────────────────────────────────────────────
const set = new Set([1, 2, 2, 3, 3, 3]);
console.log(set.size);                   // 3 — duplicates removed
set.add(4).add(4).add(5);                // chainable
console.log([...set]);
console.log(set.has(3));
set.delete(1);
console.log([...set]);

// Set operations
const setA = new Set([1, 2, 3, 4]);
const setB = new Set([3, 4, 5, 6]);
const union        = new Set([...setA, ...setB]);
const intersection = new Set([...setA].filter(v => setB.has(v)));
const difference   = new Set([...setA].filter(v => !setB.has(v)));
console.log([...union], [...intersection], [...difference]);

// ── WeakMap / WeakSet ──────────────────────────────────────────────────────
const privateData = new WeakMap();

class Account {
  constructor(balance) {
    privateData.set(this, { balance });   // truly private, GC-friendly
  }
  getBalance() {
    return privateData.get(this).balance;
  }
  deposit(amount) {
    privateData.get(this).balance += amount;
    return this;
  }
}

const acct = new Account(100);
console.log(acct.getBalance());
acct.deposit(50);
console.log(acct.getBalance());
console.log(Object.keys(acct));          // [] — no leaked state

const visited = new WeakSet();
const node1 = { id: 1 };
visited.add(node1);
console.log(visited.has(node1));
console.log(visited.has({ id: 1 }));     // false — different object
