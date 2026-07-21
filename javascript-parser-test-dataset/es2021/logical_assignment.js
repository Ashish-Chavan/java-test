/**
 * ES2021 (ES12) Feature: Logical Assignment Operators (&&=, ||=, ??=)
 * and Numeric Separators (1_000_000)
 */
'use strict';

// ── ||= (OR assignment): assign if falsy ──────────────────────────────────
let title = '';
title ||= 'Untitled';
console.log(title);                  // 'Untitled' — '' is falsy

let count = 0;
count ||= 10;
console.log(count);                  // 10 — careful! 0 is falsy (often a bug)

let name = 'Alice';
name ||= 'Anonymous';
console.log(name);                   // 'Alice' — already truthy, no assignment

// ── ??= (nullish assignment): assign only if null/undefined ───────────────
let timeout = 0;
timeout ??= 30;
console.log(timeout);                // 0 — preserved! ??= respects 0

let retries = null;
retries ??= 3;
console.log(retries);                // 3 — null triggered assignment

let label;
label ??= 'default';
console.log(label);                  // 'default' — undefined triggered

let flag = false;
flag ??= true;
console.log(flag);                   // false — preserved! ??= respects false

// The idiomatic defaults pattern
function initConfig(options = {}) {
  options.host ??= 'localhost';
  options.port ??= 8080;
  options.secure ??= false;
  options.timeout ??= 0;             // 0 stays 0 if explicitly passed
  return options;
}
console.log(initConfig({ port: 3000, timeout: 0 }));
console.log(initConfig({}));

// ── &&= (AND assignment): assign only if truthy ───────────────────────────
let user = { name: 'Bob', session: 'abc123' };
user.session &&= user.session.toUpperCase();     // transform only if present
console.log(user.session);           // 'ABC123'

let noSession = { name: 'Carol', session: null };
noSession.session &&= noSession.session.toUpperCase();   // no throw!
console.log(noSession.session);      // null — untouched

// Conditional transformation pattern
let cache = { data: [1, 2, 3] };
cache.data &&= cache.data.filter(n => n > 1);
console.log(cache.data);

// ── Short-circuit semantics: NO assignment happens when skipped ────────────
const tracker = {
  _value: 'existing',
  assignments: 0,
  get value() { return this._value; },
  set value(v) { this.assignments++; this._value = v; },
};

tracker.value ||= 'new';             // skipped — setter NOT invoked
console.log(`assignments: ${tracker.assignments}`);   // 0 — key difference from a = a || b

tracker.value &&= 'replaced';        // truthy — setter invoked once
console.log(`assignments: ${tracker.assignments}, value: ${tracker.value}`);

// ── Numeric separators ─────────────────────────────────────────────────────
// Underscores for readability — ignored by the parser

const million        = 1_000_000;
const billion        = 1_000_000_000;
const budget         = 12_345_678.90;
const fraction       = 0.000_001;

console.log(million, billion, budget, fraction);

// In different bases
const hexColor    = 0xFF_A5_00;              // RGB grouping
const binaryMask  = 0b1010_0001_1000_0101;   // nibble grouping
const octalPerms  = 0o7_5_5;                 // permission digits
const bigNumber   = 9_007_199_254_740_991n;  // works with BigInt too

console.log(hexColor.toString(16));
console.log(binaryMask.toString(2));
console.log(octalPerms.toString(8));
console.log(bigNumber);

// Scientific notation
const avogadro = 6.022_140_76e23;
const planck   = 6.626_070_15e-34;
console.log(avogadro, planck);

// Invalid placements — parser rejection test cases:
// const bad1 = _100;        // this is an identifier, not a number
// const bad2 = 100_;        // SyntaxError: trailing separator
// const bad3 = 1__000;      // SyntaxError: consecutive separators
// const bad4 = 0._5;        // SyntaxError: separator after decimal point
// const bad5 = 0x_FF;       // SyntaxError: separator after base prefix

// ── Combining both features ────────────────────────────────────────────────
class RateLimiter {
  constructor(options = {}) {
    this.maxRequests = options.maxRequests ?? 10_000;
    this.windowMs    = options.windowMs ?? 60_000;
    this.current     = 0;
  }

  configure(overrides) {
    this.maxRequests ??= 10_000;
    overrides.maxRequests &&= Math.min(overrides.maxRequests, 100_000);
    Object.assign(this, overrides);
    return this;
  }

  tryAcquire() {
    if (this.current >= this.maxRequests) return false;
    this.current += 1;
    return true;
  }
}

const limiter = new RateLimiter({ windowMs: 30_000 });
console.log(`max: ${limiter.maxRequests.toLocaleString()}, window: ${limiter.windowMs}ms`);
limiter.configure({ maxRequests: 250_000 });
console.log(`capped max: ${limiter.maxRequests.toLocaleString()}`);
console.log(`acquire: ${limiter.tryAcquire()}`);
