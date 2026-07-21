/**
 * ES2022 (ES13) Feature: Class Fields — Public, Private (#), Static,
 * Private Methods, Brand Checks (#x in obj)
 */
'use strict';

// ── Public instance fields ─────────────────────────────────────────────────
class Counter {
  // Field declarations — no constructor needed
  count = 0;
  step = 1;
  label = 'counter';
  history = [];                  // fresh array per instance (unlike prototype props)
  createdAt = Date.now();        // expressions allowed

  increment() {
    this.count += this.step;
    this.history.push(this.count);
    return this;
  }
}

const c1 = new Counter();
const c2 = new Counter();
c1.increment().increment();
console.log(c1.count, c1.history);
console.log(c2.count, c2.history);   // independent instances

// ── Private instance fields #x ─────────────────────────────────────────────
class BankAccount {
  #balance = 0;                  // truly private — not name-mangled, ENFORCED
  #transactions = [];
  owner;                         // public field, no initializer

  constructor(owner, initial = 0) {
    this.owner = owner;
    this.#balance = initial;
  }

  deposit(amount) {
    if (amount <= 0) throw new Error('Deposit must be positive');
    this.#balance += amount;
    this.#log('deposit', amount);
    return this;
  }

  withdraw(amount) {
    if (amount > this.#balance) throw new Error('Insufficient funds');
    this.#balance -= amount;
    this.#log('withdraw', amount);
    return this;
  }

  // ── Private methods ──────────────────────────────────────────────────────
  #log(type, amount) {
    this.#transactions.push({ type, amount, balance: this.#balance });
  }

  // Private getter
  get #formattedBalance() {
    return `$${this.#balance.toFixed(2)}`;
  }

  get statement() {
    return `${this.owner}: ${this.#formattedBalance} (${this.#transactions.length} transactions)`;
  }
}

const account = new BankAccount('Alice', 100);
account.deposit(50).withdraw(30);
console.log(account.statement);

// Private fields are inaccessible outside — even via bracket access
console.log(account['#balance']);            // undefined — just a weird key
// console.log(account.#balance);            // SyntaxError outside the class!

// Not visible to reflection
console.log(Object.keys(account));           // ['owner'] only
console.log(JSON.stringify(account));

// ── Static fields and static private ───────────────────────────────────────
class IdGenerator {
  static prefix = 'ID';                       // static public field
  static #counter = 0;                        // static private field
  static #instances = new Set();              // static private collection

  static next() {
    IdGenerator.#counter += 1;
    return `${IdGenerator.prefix}-${String(IdGenerator.#counter).padStart(4, '0')}`;
  }

  static #validate(id) {                      // static private method
    return id.startsWith(IdGenerator.prefix);
  }

  static register(id) {
    if (!IdGenerator.#validate(id)) throw new Error(`Invalid id: ${id}`);
    IdGenerator.#instances.add(id);
    return IdGenerator.#instances.size;
  }
}

console.log(IdGenerator.next());
console.log(IdGenerator.next());
console.log(`registered count: ${IdGenerator.register(IdGenerator.next())}`);

// ── Brand checks: #field in object ─────────────────────────────────────────
class Cache {
  #data = new Map();

  set(k, v) { this.#data.set(k, v); return this; }
  get(k) { return this.#data.get(k); }

  // Ergonomic brand check — is this REALLY a Cache instance?
  static isCache(obj) {
    return #data in obj;                      // ES2022 syntax!
  }
}

const realCache = new Cache();
const fakeCache = { set() {}, get() {}, };    // duck-typed impostor

console.log(Cache.isCache(realCache));        // true
console.log(Cache.isCache(fakeCache));        // false — brand check defeats duck typing
console.log(Cache.isCache({}));               // false

// Brand check for safe method implementation
class Temperature {
  #celsius;

  constructor(c) { this.#celsius = c; }

  equals(other) {
    // Guard against non-Temperature objects without try/catch
    if (!(#celsius in other)) return false;
    return this.#celsius === other.#celsius;
  }
}

const t1 = new Temperature(25);
const t2 = new Temperature(25);
const t3 = new Temperature(30);
console.log(t1.equals(t2), t1.equals(t3), t1.equals({ celsius: 25 }));

// ── Private fields in inheritance ──────────────────────────────────────────
class Base {
  #baseSecret = 'base';
  revealBase() { return this.#baseSecret; }
}

class Derived extends Base {
  #derivedSecret = 'derived';                 // separate namespace from Base's
  revealDerived() { return this.#derivedSecret; }
  revealBoth() { return `${this.revealBase()} + ${this.#derivedSecret}`; }
}

const d = new Derived();
console.log(d.revealBoth());

// ── Fields with computed initial values referencing other fields ───────────
class Rectangle {
  width = 10;
  height = 5;
  area = this.width * this.height;            // fields initialize in order
  #id = `rect-${Math.random().toString(36).slice(2, 8)}`;

  describe() {
    return `${this.#id}: ${this.width}x${this.height} = ${this.area}`;
  }
}
console.log(new Rectangle().describe());
