/**
 * Proposals: Decorators — TC39 Stage 3 (NOT yet standard ECMAScript)
 *
 * ⚠️ PARSER REJECTION TEST ⚠️
 * The @decorator syntax below is NOT part of any ratified ECMAScript
 * edition (as of ES2024). It requires:
 *   - Babel with @babel/plugin-proposal-decorators, or
 *   - TypeScript 5.0+ (which implements the Stage 3 semantics), or
 *   - A parser with explicit proposal support (e.g. acorn-stage3, espree
 *     with ecmaFeatures, @typescript-eslint/parser)
 *
 * A strictly spec-compliant ES2024 parser MUST fail on this file.
 * Record: (a) does it fail cleanly with a useful position/message,
 *         (b) or does it crash / silently mis-parse?
 *
 * Grammar being tested (Stage 3 shape):
 *   - @expr before class declarations
 *   - @expr before class methods, getters, setters
 *   - @expr before class fields (public and static)
 *   - Multiple decorators stacked on one target
 *   - Decorator factories: @factory(args)
 *   - Member-expression decorators: @namespace.decorator
 */
'use strict';

// ── Simple decorator functions (Stage 3 signature: (value, context)) ──────

function logged(value, context) {
  if (context.kind === 'method') {
    return function (...args) {
      console.log(`CALL ${context.name}(${args.join(', ')})`);
      const result = value.call(this, ...args);
      console.log(`  -> ${result}`);
      return result;
    };
  }
}

function readonly(value, context) {
  if (context.kind === 'field') {
    return function (initialValue) {
      Object.defineProperty(this, context.name, {
        value: initialValue,
        writable: false,
        configurable: false,
      });
      return initialValue;
    };
  }
}

function registered(value, context) {
  if (context.kind === 'class') {
    ClassRegistry.add(context.name, value);
    return value;
  }
}

const ClassRegistry = {
  _classes: new Map(),
  add(name, cls) { this._classes.set(name, cls); },
  get(name) { return this._classes.get(name); },
  get size() { return this._classes.size; },
};

// ── Decorator factory (takes config, returns decorator) ───────────────────

function throttle(ms) {
  return function (value, context) {
    let lastCall = 0;
    return function (...args) {
      const now = Date.now();
      if (now - lastCall < ms) {
        console.log(`THROTTLED ${context.name} (within ${ms}ms)`);
        return undefined;
      }
      lastCall = now;
      return value.call(this, ...args);
    };
  };
}

function defaultValue(val) {
  return function (value, context) {
    if (context.kind === 'field') {
      return function (initial) {
        return initial === undefined ? val : initial;
      };
    }
  };
}

// ── Namespace object for member-expression decorators ─────────────────────

const validators = {
  positive(value, context) {
    return function (...args) {
      for (const arg of args) {
        if (typeof arg === 'number' && arg <= 0) {
          throw new RangeError(`${context.name}: arguments must be positive`);
        }
      }
      return value.call(this, ...args);
    };
  },
};

// ── Class-level decorator ──────────────────────────────────────────────────

@registered
class ShoppingCart {
  // Field decorators
  @readonly
  storeId = 'store-001';

  @defaultValue(0)
  discount;

  items = [];

  // Method decorator
  @logged
  addItem(name, price) {
    this.items.push({ name, price });
    return this.items.length;
  }

  // Stacked decorators (applied bottom-up)
  @logged
  @validators.positive
  applyDiscount(percent) {
    this.discount = percent;
    return `discount set to ${percent}%`;
  }

  // Decorator factory on a method
  @throttle(1000)
  checkout() {
    const total = this.items.reduce((sum, i) => sum + i.price, 0);
    const discounted = total * (1 - this.discount / 100);
    return `total: ${discounted.toFixed(2)}`;
  }

  // Decorated getter
  @logged
  get itemCount() {
    return this.items.length;
  }

  // Decorated static method
  @logged
  static describe() {
    return 'A decorated shopping cart class';
  }
}

// ── Second decorated class: decorator + extends interaction ───────────────

@registered
class DiscountCart extends ShoppingCart {
  @defaultValue(10)
  discount;

  @logged
  addBulkItems(items) {
    for (const [name, price] of items) {
      this.addItem(name, price);
    }
    return this.items.length;
  }
}

// ── Demo (only runs if a decorator-aware toolchain compiled this) ──────────

console.log('Registered classes:', ClassRegistry.size);

const cart = new ShoppingCart();
cart.addItem('widget', 9.99);
cart.addItem('gadget', 24.95);
console.log('Item count:', cart.itemCount);

cart.applyDiscount(15);
console.log(cart.checkout());
console.log(cart.checkout());   // throttled — within 1000ms

try {
  cart.applyDiscount(-5);       // validators.positive throws
} catch (err) {
  console.log('Caught:', err.message);
}

console.log(ShoppingCart.describe());

const bulk = new DiscountCart();
bulk.addBulkItems([['a', 1], ['b', 2], ['c', 3]]);
console.log('Bulk cart items:', bulk.items.length, 'default discount:', bulk.discount);
