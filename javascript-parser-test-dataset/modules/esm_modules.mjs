/**
 * Module Systems: ECMAScript Modules (.mjs extension)
 *
 * This file exercises EVERY import/export grammar form in the ESM spec.
 * Key parser points:
 *   - import/export are STATEMENTS with static grammar (not function calls)
 *   - Only allowed at top level — an import inside a block is a SyntaxError
 *   - Must be parsed with sourceType: "module" (implicit strict mode)
 *   - 'this' is undefined at module top level (vs module.exports in CJS)
 *   - import.meta is only legal in modules
 *   - String literal module specifiers only (no computed specifiers)
 *
 * Parser test: this file must parse as a Module. The same content in a
 * .cjs context should FAIL. require()/__dirname do NOT exist here.
 */

// ── Import forms ───────────────────────────────────────────────────────────

// 1. Default import
import path from 'node:path';

// 2. Named imports
import { join, resolve } from 'node:path';

// 3. Named import with alias
import { basename as getBaseName, extname as getExt } from 'node:path';

// 4. Namespace import
import * as os from 'node:os';

// 5. Default + named combined
import util, { promisify, format } from 'node:util';

// 6. Default + namespace combined
import fs, * as fsAll from 'node:fs';

// 7. Side-effect-only import (no bindings)
import 'node:process';

// ── import.meta — module-only meta property ───────────────────────────────
console.log('import.meta.url:', import.meta.url);
console.log('is module URL:', import.meta.url.startsWith('file://'));

// ── Module-scope 'this' is undefined (vs CJS where it's exports) ──────────
console.log('top-level this:', this === undefined ? 'undefined (ESM)' : 'defined (CJS?)');

// ── Export forms ───────────────────────────────────────────────────────────

// 1. Named export of declaration
export const VERSION = '2.0.0';
export let counter = 0;
export var legacyVar = 'still valid';

// 2. Named export of function declaration
export function increment() {
  counter += 1;
  return counter;
}

// 3. Named export of async function
export async function fetchConfig(name) {
  return { name, loadedAt: Date.now() };
}

// 4. Named export of generator
export function* idGenerator(start = 1) {
  let id = start;
  while (true) {
    yield id++;
  }
}

// 5. Named export of class
export class Registry {
  #items = new Map();

  register(key, value) {
    this.#items.set(key, value);
    return this;
  }

  get(key) {
    return this.#items.get(key);
  }

  get size() {
    return this.#items.size;
  }
}

// 6. Export list (declare first, export later)
const internalHelper = (x) => x * 2;
const anotherHelper = (x) => x + 100;
function calculate(a, b) {
  return internalHelper(a) + anotherHelper(b);
}

export { calculate, internalHelper as double };

// 7. Export with alias
const secretName = 'hidden';
export { secretName as publicName };

// 8. Default export (expression form)
export default class Application {
  constructor(name) {
    this.name = name;
    this.registry = new Registry();
    this.ids = idGenerator(1000);
  }

  start() {
    const id = this.ids.next().value;
    return `${this.name} started with id ${id} (v${VERSION})`;
  }
}

// ── Re-export forms (aggregation) ─────────────────────────────────────────

// 9. Re-export named from another module
export { sep, delimiter } from 'node:path';

// 10. Re-export with alias
export { platform as osPlatform } from 'node:os';

// 11. Re-export everything (namespace merge, excludes default)
export * from 'node:querystring';

// 12. Re-export namespace under a name
export * as pathUtils from 'node:path';

// 13. Re-export another module's default as a named export
export { default as utilDefault } from 'node:util';

// ── Demo usage ─────────────────────────────────────────────────────────────
console.log('join:', join('a', 'b', 'c'));
console.log('alias basename:', getBaseName('/tmp/file.txt'));
console.log('alias extname:', getExt('/tmp/file.txt'));
console.log('namespace os.platform():', os.platform());
console.log('format:', format('%s = %d', 'answer', 42));
console.log('fs === fsAll.default:', fs === fsAll.default);

const app = new Application('TestApp');
console.log(app.start());
console.log('increment:', increment(), increment());
console.log('calculate(5, 10):', calculate(5, 10));

const reg = new Registry();
reg.register('a', 1).register('b', 2);
console.log('registry size:', reg.size);
