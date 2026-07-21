/**
 * ES2016 (ES7) Feature: Exponentiation Operator (**) and Array.prototype.includes
 * The smallest ES release — exactly two features.
 */
'use strict';

// ── Exponentiation operator ** ─────────────────────────────────────────────
console.log(2 ** 10);              // 1024 — replaces Math.pow(2, 10)
console.log(3 ** 3);               // 27
console.log(10 ** -2);             // 0.01
console.log(2 ** 0.5);             // sqrt(2)
console.log((-2) ** 2);            // 4 — parens REQUIRED for negative base
// console.log(-2 ** 2);           // SyntaxError! ambiguous — parser test case

// Right-associative (unlike most operators)
console.log(2 ** 3 ** 2);          // 512 = 2 ** (3 ** 2) = 2 ** 9
console.log((2 ** 3) ** 2);        // 64

// With BigInt-style large results
console.log(2 ** 53);              // max safe integer + 1
console.log(Number.MAX_SAFE_INTEGER === 2 ** 53 - 1);

// ── Exponentiation assignment **= ──────────────────────────────────────────
let base = 3;
base **= 2;
console.log(base);                 // 9
base **= 2;
console.log(base);                 // 81

let growth = 1.05;
growth **= 10;                     // compound growth over 10 periods
console.log(growth.toFixed(4));

// Practical: compound interest
function compoundInterest(principal, rate, years, compoundsPerYear = 12) {
  return principal * (1 + rate / compoundsPerYear) ** (compoundsPerYear * years);
}
console.log(`$1000 at 5% for 10yr: $${compoundInterest(1000, 0.05, 10).toFixed(2)}`);

// Practical: distance formula
function distance3D([x1, y1, z1], [x2, y2, z2]) {
  return ((x2 - x1) ** 2 + (y2 - y1) ** 2 + (z2 - z1) ** 2) ** 0.5;
}
console.log(distance3D([0, 0, 0], [1, 2, 2]));

// ── Array.prototype.includes ───────────────────────────────────────────────
const fruits = ['apple', 'banana', 'cherry'];

console.log(fruits.includes('banana'));      // true
console.log(fruits.includes('grape'));       // false

// vs indexOf — the key difference: NaN handling
const values = [1, 2, NaN, 4];
console.log(values.indexOf(NaN));            // -1 — indexOf can't find NaN!
console.log(values.includes(NaN));           // true — includes uses SameValueZero

// fromIndex parameter
const letters = ['a', 'b', 'c', 'a', 'b'];
console.log(letters.includes('a'));          // true
console.log(letters.includes('a', 1));       // true (found at index 3)
console.log(letters.includes('a', 4));       // false

// Negative fromIndex (counts from end)
console.log(letters.includes('b', -1));      // true (checks last element)
console.log(letters.includes('c', -2));      // false

// undefined vs sparse arrays
const sparse = [1, , 3];                     // hole at index 1
console.log(sparse.includes(undefined));     // true — holes count as undefined
console.log(sparse.indexOf(undefined));      // -1 — indexOf skips holes

// Practical: validation
const ALLOWED_ROLES = ['admin', 'editor', 'viewer'];

function checkAccess(role) {
  if (!ALLOWED_ROLES.includes(role)) {
    return `Denied: '${role}' is not a valid role`;
  }
  return `Granted: ${role}`;
}
console.log(checkAccess('editor'));
console.log(checkAccess('hacker'));

// Practical: replacing multi-condition checks
const statusCode = 404;

// Old style:
if (statusCode === 400 || statusCode === 404 || statusCode === 422) {
  console.log('client error (old style)');
}

// ES2016 style:
if ([400, 404, 422].includes(statusCode)) {
  console.log('client error (includes style)');
}

// On strings too (technically ES2015 String.includes, shown for contrast)
const sentence = 'The quick brown fox';
console.log(sentence.includes('quick'));
console.log(sentence.includes('slow'));
