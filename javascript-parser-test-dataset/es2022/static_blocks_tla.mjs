/**
 * ES2022 (ES13) Feature: Static Initialization Blocks + Top-Level Await
 *
 * ⚠ PARSER TEST CASE: This file MUST be .mjs (or in a "type": "module"
 * package). Top-level await is ONLY legal at module scope — a script-goal
 * parser should REJECT the top-level await below. That's the test.
 */

// ── Static initialization blocks ───────────────────────────────────────────
class DatabaseConfig {
  static host;
  static port;
  static credentials;
  static #secret;                  // static private, initialized in block

  // static block: runs once when the class is evaluated
  static {
    const env = 'production';      // complex init logic with local scope
    if (env === 'production') {
      DatabaseConfig.host = 'db.prod.internal';
      DatabaseConfig.port = 5432;
    } else {
      DatabaseConfig.host = 'localhost';
      DatabaseConfig.port = 5433;
    }
    DatabaseConfig.#secret = `secret-${Math.random().toString(36).slice(2)}`;
    DatabaseConfig.credentials = { user: 'app', vault: true };
  }

  // Multiple static blocks are allowed — run in order
  static {
    console.log(`DatabaseConfig initialized: ${DatabaseConfig.host}:${DatabaseConfig.port}`);
  }

  static hasSecret() {
    return DatabaseConfig.#secret !== undefined;
  }
}

console.log(DatabaseConfig.credentials);
console.log(`has secret: ${DatabaseConfig.hasSecret()}`);

// Static block accessing private state — the "friend" pattern
let revealSecret;                  // module-scoped accessor

class Vault {
  #contents = 'gold';

  static {
    // Static blocks can grant outside access to private fields
    revealSecret = (vault) => vault.#contents;
  }
}

const vault = new Vault();
console.log(`vault contents via friend fn: ${revealSecret(vault)}`);

// Static block with try/catch for fallible initialization
class FeatureFlags {
  static flags = {};

  static {
    try {
      // Simulated config parse that might fail
      FeatureFlags.flags = JSON.parse('{"darkMode": true, "beta": false}');
    } catch {
      FeatureFlags.flags = { darkMode: false, beta: false };   // safe defaults
    }
  }
}
console.log(FeatureFlags.flags);

// ── Top-level await ────────────────────────────────────────────────────────
// await at module scope — NO wrapping async function needed.
// This is the syntax a script-mode parser must reject.

const delay = (ms, v) => new Promise(res => setTimeout(() => res(v), ms));

console.log('before top-level await');
const config = await delay(10, { app: 'demo', version: '1.0' });   // ← module-only syntax
console.log('after top-level await:', config);

// Top-level await in expressions
const [a, b] = await Promise.all([
  delay(5, 'first'),
  delay(5, 'second'),
]);
console.log(a, b);

// Conditional dynamic import with top-level await — the canonical use case
const useNativePath = true;
const pathModule = useNativePath
  ? await import('path')
  : null;
console.log(`path module loaded: ${typeof pathModule?.join === 'function'}`);

// Top-level await in try/catch
let remoteData;
try {
  remoteData = await delay(5, { status: 'ok' });
} catch {
  remoteData = { status: 'fallback' };
}
console.log(remoteData);

// Top-level for await
async function* countTo(n) {
  for (let i = 1; i <= n; i++) yield await delay(1, i);
}

const collected = [];
for await (const n of countTo(3)) {          // for await at top level!
  collected.push(n);
}
console.log('for await collected:', collected);

// ── import.meta — also module-only syntax ──────────────────────────────────
console.log(`import.meta.url ends with .mjs: ${import.meta.url.endsWith('.mjs')}`);

export const initialized = true;             // export — also module-only
export default config;
