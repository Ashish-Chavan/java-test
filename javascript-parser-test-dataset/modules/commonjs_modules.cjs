/**
 * Module Systems: CommonJS (.cjs extension)
 *
 * CommonJS is Node.js's original module system. Key grammar points:
 *   - require() is just a function CALL, not a keyword — valid anywhere
 *   - module.exports / exports.x are plain object assignments
 *   - No import/export STATEMENTS allowed (those are ESM-only grammar)
 *   - __dirname and __filename are available (not in ESM!)
 *   - Top-level await is a SYNTAX ERROR in CommonJS
 *
 * Parser test: a .cjs file containing `import x from 'y'` should FAIL.
 * This file contains only valid CJS and must parse as a Script, not a Module.
 */
'use strict';

// ── Basic require ──────────────────────────────────────────────────────────
const path = require('path');
const fs = require('fs');
const { EventEmitter } = require('events');           // destructured require
const util = require('util');

// ── require with property access ───────────────────────────────────────────
const join = require('path').join;
const { promisify } = require('util');

// ── CJS-only globals ───────────────────────────────────────────────────────
console.log('__dirname: ', typeof __dirname);          // 'string' in CJS
console.log('__filename:', typeof __filename);
console.log('module:    ', typeof module);
console.log('exports:   ', typeof exports);
console.log('require:   ', typeof require);

// ── Conditional require — legal because require() is just a function ──────
let optionalDep = null;
try {
  optionalDep = require('some-optional-package');
} catch (err) {
  console.log('Optional package not installed — using fallback');
}

// require inside a function (lazy loading)
function lazyLoadCrypto() {
  const crypto = require('crypto');                    // deferred until called
  return crypto.randomBytes(8).toString('hex');
}

// require inside a condition
const os = process.platform === 'win32'
  ? require('os')
  : require('os');                                     // same here, but shape matters

// Dynamic require with computed path (valid CJS, impossible in static ESM)
const moduleName = 'pa' + 'th';
const dynamicPath = require(moduleName);
console.log('Dynamic require worked:', typeof dynamicPath.join === 'function');

// ── Defining exports: exports.x style ─────────────────────────────────────
exports.VERSION = '1.0.0';

exports.add = function add(a, b) {
  return a + b;
};

exports.multiply = (a, b) => a * b;

// ── Defining exports: module.exports assignment ───────────────────────────
class Logger extends EventEmitter {
  constructor(prefix) {
    super();
    this.prefix = prefix;
    this.entries = [];
  }

  log(message) {
    const entry = `[${this.prefix}] ${message}`;
    this.entries.push(entry);
    this.emit('logged', entry);
    return entry;
  }

  get count() {
    return this.entries.length;
  }
}

// Named helper kept module-private (not exported)
function formatBytes(bytes) {
  const units = ['B', 'KB', 'MB', 'GB'];
  let i = 0;
  let value = bytes;
  while (value >= 1024 && i < units.length - 1) {
    value /= 1024;
    i += 1;
  }
  return `${value.toFixed(1)} ${units[i]}`;
}

// ── module.exports as a whole-object replacement ───────────────────────────
// NOTE: this REPLACES the earlier exports.add / exports.multiply bindings —
// a classic CJS gotcha that parsers see in the wild constantly.
module.exports = {
  Logger,
  formatBytes,
  lazyLoadCrypto,

  // re-attach the earlier helpers so both styles appear in one file
  VERSION: exports.VERSION,
  add: exports.add,
  multiply: exports.multiply,

  // inline definition in export object
  clamp(value, lo, hi) {
    return Math.max(lo, Math.min(value, hi));
  },
};

// ── module.exports.x after replacement — also valid ───────────────────────
module.exports.createdAt = new Date().toISOString();

// ── require.resolve and require.cache ─────────────────────────────────────
const resolvedPath = require.resolve('path');
console.log('require.resolve("path"):', resolvedPath);
console.log('require.cache is object:', typeof require.cache === 'object');

// ── Demo usage ─────────────────────────────────────────────────────────────
const logger = new Logger('APP');
logger.on('logged', (entry) => console.log('event:', entry));
logger.log('CommonJS module loaded');
logger.log('All exports defined');

console.log('Log count:', logger.count);
console.log('formatBytes(1536):', formatBytes(1536));
console.log('clamp(15, 0, 10):', module.exports.clamp(15, 0, 10));
console.log('add(2, 3):', module.exports.add(2, 3));
console.log('lazy crypto hex:', lazyLoadCrypto());
