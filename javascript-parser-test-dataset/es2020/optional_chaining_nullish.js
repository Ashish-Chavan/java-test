/**
 * ES2020 (ES11) Feature: Optional Chaining (?.) and Nullish Coalescing (??)
 * The two most impactful operators since ES6.
 */
'use strict';

// ── Optional chaining: property access ?. ─────────────────────────────────
const user = {
  name: 'Alice',
  address: {
    city: 'Springfield',
    geo: { lat: 39.78, lng: -89.65 },
  },
  // no 'company' property
};

console.log(user.address?.city);            // 'Springfield'
console.log(user.company?.name);            // undefined — no throw!
console.log(user.company?.address?.city);   // undefined — short-circuits

// Without optional chaining this throws:
// console.log(user.company.name);  // TypeError: Cannot read properties of undefined

// Deep chains
console.log(user.address?.geo?.lat);
console.log(user.address?.geo?.altitude);   // undefined

// ── Optional chaining: dynamic property access ?.[  ] ─────────────────────
const key = 'city';
console.log(user.address?.[key]);
console.log(user.missing?.[key]);

const settings = { 'theme-dark': true };
const settingName = 'theme-dark';
console.log(settings?.[settingName]);

// Array element access
const matrix = [[1, 2], [3, 4]];
console.log(matrix[0]?.[1]);       // 2
console.log(matrix[5]?.[0]);       // undefined — no throw on missing row

// ── Optional chaining: method calls ?.() ───────────────────────────────────
const api = {
  fetch() { return 'fetched data'; },
  // no 'cancel' method
};

console.log(api.fetch?.());        // 'fetched data'
console.log(api.cancel?.());       // undefined — no throw

// Optional callbacks — extremely common pattern
function processData(data, { onSuccess, onError, onProgress } = {}) {
  onProgress?.(0);
  try {
    const result = data.toUpperCase();
    onProgress?.(100);
    onSuccess?.(result);
    return result;
  } catch (e) {
    onError?.(e);
    return null;
  }
}

console.log(processData('hello', { onSuccess: r => console.log(`callback: ${r}`) }));
console.log(processData('world'));   // no callbacks — no crash

// ── Short-circuit semantics ────────────────────────────────────────────────
let sideEffectCount = 0;
const incr = () => { sideEffectCount++; return 'key'; };

const nothing = null;
nothing?.[incr()];                 // incr NOT called — whole chain short-circuits
nothing?.method(incr());           // incr NOT called
console.log(`side effects: ${sideEffectCount}`);   // 0

// ── Nullish coalescing ?? ──────────────────────────────────────────────────
// Returns right side only for null/undefined — NOT for other falsy values

const config = {
  timeout: 0,          // valid zero!
  retries: null,
  label: '',           // valid empty string!
  verbose: false,      // valid false!
};

// The || bug that ?? fixes:
console.log(config.timeout || 30);    // 30 — WRONG, 0 was intentional
console.log(config.timeout ?? 30);    // 0  — correct

console.log(config.label || 'default');   // 'default' — WRONG
console.log(config.label ?? 'default');   // ''        — correct

console.log(config.verbose || true);      // true — WRONG
console.log(config.verbose ?? true);      // false — correct

console.log(config.retries ?? 3);         // 3 — null triggers fallback
console.log(config.missing ?? 'fallback'); // undefined triggers fallback

// ── ?? chaining ────────────────────────────────────────────────────────────
const primary = null;
const secondary = undefined;
const tertiary = 'found it';
console.log(primary ?? secondary ?? tertiary ?? 'last resort');

// ── ?? + ?. together: the power combo ─────────────────────────────────────
const response = {
  data: {
    users: [
      { name: 'Bob', settings: null },
    ],
  },
};

const theme    = response.data?.users?.[0]?.settings?.theme ?? 'system-default';
const username = response.data?.users?.[0]?.name ?? 'Anonymous';
const missing  = response.data?.admins?.[0]?.name ?? 'No admin';

console.log(theme);
console.log(username);
console.log(missing);

// ── Parser edge cases ──────────────────────────────────────────────────────
// ?? cannot mix with && or || without parentheses — SyntaxError!
// const bad = a || b ?? c;        // SyntaxError
// const bad2 = a ?? b || c;       // SyntaxError
const a = null, b = false, c = 'ok';
const good1 = (a || b) ?? c;       // parens required — parser test case
const good2 = a ?? (b || c);
console.log(good1, good2);

// ?. is not a syntax for optional assignment
// user.missing?.prop = 5;         // SyntaxError — can't assign through ?.

// Numeric edge: ?. followed by digit is parsed as ternary-ish...
// obj?.5 is invalid; obj?.[5] is the correct form
const arr = ['zero', 'one'];
console.log(arr?.[1]);

// delete with optional chaining
const obj = { temp: 'delete me' };
delete obj?.temp;
console.log(obj.temp);             // undefined
