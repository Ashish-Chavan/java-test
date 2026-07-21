/**
 * ES2015 (ES6) Feature: Arrow Functions, let/const, Block Scoping
 * Arrow function forms, lexical this, TDZ, const semantics.
 */
'use strict';

// ── Arrow function syntax variations ───────────────────────────────────────
const noParams     = () => 'no params';
const oneParam     = x => x * 2;                  // parens optional for 1 param
const twoParams    = (a, b) => a + b;
const withBody     = (a, b) => { const s = a + b; return s * 2; };
const returnObject = (k, v) => ({ [k]: v });      // parens needed for object literal
const nested       = a => b => c => a + b + c;    // curried

console.log(noParams());
console.log(oneParam(21));
console.log(twoParams(3, 4));
console.log(withBody(1, 2));
console.log(returnObject('key', 'value'));
console.log(nested(1)(2)(3));

// ── Lexical `this` binding ────────────────────────────────────────────────
const counter = {
  count: 0,
  // Regular function: `this` is dynamic
  incrementRegular: function () {
    this.count += 1;
    return this.count;
  },
  // Arrow in method that needs callbacks: `this` captured lexically
  incrementAsyncStyle: function () {
    const tick = () => {
      this.count += 1;      // `this` refers to counter, not the callback caller
      return this.count;
    };
    return tick();
  },
};

console.log(counter.incrementRegular());
console.log(counter.incrementAsyncStyle());

// Classic problem arrow functions solve:
class Timer {
  constructor() {
    this.seconds = 0;
    this.history = [];
  }

  start() {
    // Arrow keeps `this` = Timer instance
    [1, 2, 3].forEach((n) => {
      this.seconds += n;
      this.history.push(this.seconds);
    });
    return this.history;
  }
}
console.log(new Timer().start());

// ── let: block scoping ─────────────────────────────────────────────────────
let outer = 'outer';
{
  let outer = 'inner';       // shadows, doesn't overwrite
  console.log(outer);        // inner
}
console.log(outer);          // outer

// Loop scoping: each iteration gets its own binding
const callbacks = [];
for (let i = 0; i < 3; i++) {
  callbacks.push(() => i);
}
console.log(callbacks.map(cb => cb()));   // [0, 1, 2] — with var it'd be [3,3,3]

// ── const semantics ────────────────────────────────────────────────────────
const PI = 3.14159;
// PI = 3; // TypeError: Assignment to constant variable

// const prevents rebinding, NOT mutation
const config = { debug: false };
config.debug = true;              // OK — object is mutable
config.level = 'verbose';         // OK
console.log(config);

const items = [1, 2, 3];
items.push(4);                    // OK — array is mutable
console.log(items);

// Object.freeze for actual immutability
const frozen = Object.freeze({ x: 1 });
frozen.x = 99;                    // silently ignored (throws in strict mode... actually throws here)
console.log(frozen.x);

// ── Temporal Dead Zone (TDZ) ───────────────────────────────────────────────
function tdzDemo() {
  // console.log(tdzVar);  // ReferenceError: Cannot access before initialization
  let tdzVar = 'initialized';
  return tdzVar;
}
console.log(tdzDemo());

// typeof is NOT safe with TDZ (unlike undeclared vars)
function tdzTypeof() {
  try {
    // eslint-disable-next-line no-use-before-define
    return typeof tdzLet;   // throws! (typeof undeclaredVar would return 'undefined')
  } catch (e) {
    return `TDZ error: ${e.constructor.name}`;
  } finally {
    let tdzLet = 1;         // declaration that creates the TDZ above
  }
}
console.log(tdzTypeof());

// ── Arrow functions have no `arguments` ───────────────────────────────────
function regularWithArguments() {
  return arguments.length;
}
const arrowUsingRest = (...args) => args.length;   // use rest instead

console.log(regularWithArguments(1, 2, 3));
console.log(arrowUsingRest(1, 2, 3, 4));

// ── Arrow functions cannot be constructors ────────────────────────────────
const NotAClass = () => {};
try {
  new NotAClass();
} catch (e) {
  console.log(`Cannot construct: ${e.constructor.name}`);
}

// ── Immediately Invoked Arrow Function ─────────────────────────────────────
const result = ((x, y) => x * y)(6, 7);
console.log(result);

// ── Default parameters (ES2015) interacting with arrows ──────────────────
const greet = (name = 'World', greeting = `Hello`) => `${greeting}, ${name}!`;
console.log(greet());
console.log(greet('Alice'));
console.log(greet('Bob', 'Hi'));

// Default referring to earlier param
const range = (start, end = start + 10) => [start, end];
console.log(range(5));
console.log(range(5, 8));
