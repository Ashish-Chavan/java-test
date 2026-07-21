/**
 * ES2020 (ES11) Feature: BigInt
 * Arbitrary-precision integers. New primitive type with 'n' literal suffix.
 * Cannot mix with Number in arithmetic without explicit conversion.
 */
'use strict';

// ── BigInt literals ────────────────────────────────────────────────────────
const big       = 123n;                       // the n suffix — new grammar!
const huge      = 9007199254740993n;          // beyond Number.MAX_SAFE_INTEGER
const hexBig    = 0xFFFFFFFFFFFFFFFFn;        // hex BigInt literal
const octalBig  = 0o777777777777777777n;      // octal BigInt literal
const binaryBig = 0b1111111111111111111111111111111111111111111111111111111n;

console.log(typeof big);                      // 'bigint'
console.log(big);
console.log(huge);
console.log(hexBig);
console.log(octalBig);
console.log(binaryBig);

// ── The precision problem BigInt solves ────────────────────────────────────
console.log(Number.MAX_SAFE_INTEGER);         // 9007199254740991
console.log(9007199254740992 === 9007199254740993);   // true! Number breaks
console.log(9007199254740992n === 9007199254740993n); // false — BigInt exact

// Large factorials — impossible with Number
function factorial(n) {
  let result = 1n;
  for (let i = 2n; i <= n; i++) {
    result *= i;
  }
  return result;
}
console.log(`25! = ${factorial(25n)}`);
console.log(`50! has ${factorial(50n).toString().length} digits`);

// ── BigInt() constructor ───────────────────────────────────────────────────
console.log(BigInt(42));                      // from number
console.log(BigInt('123456789012345678901234567890'));   // from string
console.log(BigInt('0x1fffffffffffff'));      // from hex string
console.log(BigInt(true));                    // 1n

// Throws for non-integers:
try {
  BigInt(3.14);
} catch (e) {
  console.log(`BigInt(3.14): ${e.constructor.name}`);
}

// ── Arithmetic ─────────────────────────────────────────────────────────────
const x = 10n, y = 3n;
console.log(x + y);       // 13n
console.log(x - y);       // 7n
console.log(x * y);       // 30n
console.log(x / y);       // 3n — INTEGER division, truncates!
console.log(x % y);       // 1n
console.log(x ** y);      // 1000n
console.log(-x);          // -10n

// Unary + is NOT allowed (would conflict with asm.js)
try {
  // eslint-disable-next-line no-eval
  eval('+10n');
} catch (e) {
  console.log(`+10n: ${e.constructor.name}`);   // TypeError
}

// ── No mixing with Number ──────────────────────────────────────────────────
try {
  const bad = 10n + 5;    // TypeError!
} catch (e) {
  console.log(`10n + 5: ${e.message}`);
}

// Explicit conversion required
console.log(10n + BigInt(5));
console.log(Number(10n) + 5);

// ── Comparisons DO work across types ───────────────────────────────────────
console.log(10n == 10);       // true  — loose equality converts
console.log(10n === 10);      // false — different types
console.log(10n < 11);        // true
console.log(10n > 9.5);       // true
console.log(20n >= 20);       // true

// Sorting mixed arrays
const mixed = [4n, 6, 2n, 5, 1n, 3];
mixed.sort((a, b) => (a < b ? -1 : a > b ? 1 : 0));   // can't subtract mixed!
console.log(mixed);

// ── BigInt with bitwise operators ──────────────────────────────────────────
console.log(0b1010n & 0b0110n);    // 2n
console.log(0b1010n | 0b0110n);    // 14n
console.log(0b1010n ^ 0b0110n);    // 12n
console.log(1n << 64n);            // huge shift — impossible with Number
console.log(~0n);                  // -1n

// ── BigInt64Array / BigUint64Array ─────────────────────────────────────────
const i64 = new BigInt64Array(3);
i64[0] = 9223372036854775807n;     // max int64
i64[1] = -9223372036854775808n;    // min int64
console.log(i64);

const u64 = new BigUint64Array([18446744073709551615n]);  // max uint64
console.log(u64[0]);

// ── BigInt.asIntN / asUintN — wrapping to fixed width ─────────────────────
const overflow = 2n ** 64n;
console.log(BigInt.asUintN(64, overflow));         // 0n — wraps around
console.log(BigInt.asUintN(64, overflow + 5n));    // 5n
console.log(BigInt.asIntN(8, 200n));               // -56n — signed 8-bit wrap
console.log(BigInt.asIntN(8, 127n));               // 127n — fits

// ── Practical: precise financial math in cents... times a trillion ────────
const nationalDebtCents = 33_000_000_000_000_00n;  // numeric separators work!
const populationUS = 335_000_000n;
const perPersonCents = nationalDebtCents / populationUS;
console.log(`Debt per person: $${perPersonCents / 100n}.${perPersonCents % 100n}`);

// ── Practical: 64-bit IDs (Twitter snowflakes, DB keys) ────────────────────
const snowflakeId = 1745698273649234821n;
const timestamp = (snowflakeId >> 22n) + 1288834974657n;   // Twitter epoch
console.log(`Snowflake ${snowflakeId} -> timestamp ${timestamp}`);

// ── JSON does not support BigInt ───────────────────────────────────────────
try {
  JSON.stringify({ id: 123n });
} catch (e) {
  console.log(`JSON.stringify BigInt: ${e.constructor.name}`);
}

// Workaround with replacer
const json = JSON.stringify({ id: 123n }, (k, v) =>
  typeof v === 'bigint' ? v.toString() : v
);
console.log(json);
