/**
 * ES2015 (ES6) Feature: Generators and Iterators
 * function*, yield, yield*, generator delegation,
 * Symbol.iterator protocol, infinite sequences.
 */
'use strict';

// ── Basic generator ────────────────────────────────────────────────────────
function* simpleGen() {
  yield 1;
  yield 2;
  yield 3;
}

const gen = simpleGen();
console.log(gen.next());   // { value: 1, done: false }
console.log(gen.next());   // { value: 2, done: false }
console.log(gen.next());   // { value: 3, done: false }
console.log(gen.next());   // { value: undefined, done: true }

// Generators are iterable
console.log([...simpleGen()]);
for (const v of simpleGen()) {
  console.log(`for-of: ${v}`);
}

// ── Generator with return value ────────────────────────────────────────────
function* withReturn() {
  yield 'a';
  yield 'b';
  return 'final';           // becomes { value: 'final', done: true }
  // yield 'unreachable';
}

const wr = withReturn();
console.log(wr.next());
console.log(wr.next());
console.log(wr.next());     // { value: 'final', done: true }
console.log([...withReturn()]);  // ['a', 'b'] — return value NOT spread

// ── Infinite generators ────────────────────────────────────────────────────
function* naturals() {
  let n = 0;
  while (true) {
    yield n++;
  }
}

function* take(iterable, count) {
  let taken = 0;
  for (const item of iterable) {
    if (taken >= count) return;
    yield item;
    taken++;
  }
}

console.log([...take(naturals(), 5)]);

function* fibonacci() {
  let [a, b] = [0, 1];
  while (true) {
    yield a;
    [a, b] = [b, a + b];
  }
}
console.log([...take(fibonacci(), 10)]);

// ── Two-way communication: next(value) ────────────────────────────────────
function* echoMachine() {
  while (true) {
    const received = yield 'ready';
    console.log(`  generator received: ${received}`);
  }
}

const echo = echoMachine();
console.log(echo.next().value);       // prime the generator
echo.next('hello');
echo.next(42);

// Accumulator via two-way communication
function* runningTotal() {
  let total = 0;
  while (true) {
    const amount = yield total;
    if (amount !== undefined) total += amount;
  }
}

const tally = runningTotal();
tally.next();                          // prime
console.log(tally.next(10).value);
console.log(tally.next(5).value);
console.log(tally.next(25).value);

// ── yield* delegation ──────────────────────────────────────────────────────
function* inner() {
  yield 'inner-1';
  yield 'inner-2';
  return 'inner-return';
}

function* outer() {
  yield 'outer-start';
  const innerResult = yield* inner();   // delegates, captures return
  yield `got: ${innerResult}`;
  yield* [10, 20, 30];                  // delegate to any iterable
  yield* 'ab';                          // strings are iterable
  yield 'outer-end';
}

console.log([...outer()]);

// Recursive tree traversal via delegation
function* traverse(node) {
  yield node.value;
  for (const child of node.children || []) {
    yield* traverse(child);
  }
}

const tree = {
  value: 'root',
  children: [
    { value: 'a', children: [{ value: 'a1' }, { value: 'a2' }] },
    { value: 'b', children: [{ value: 'b1' }] },
  ],
};
console.log([...traverse(tree)]);

// ── Generator methods: throw() and return() ───────────────────────────────
function* resilient() {
  try {
    yield 1;
    yield 2;
    yield 3;
  } catch (e) {
    console.log(`  caught inside generator: ${e.message}`);
    yield 'recovered';
  } finally {
    console.log('  generator cleanup');
  }
}

const r = resilient();
console.log(r.next());
console.log(r.throw(new Error('injected')));
console.log(r.next());

const r2 = resilient();
r2.next();
console.log(r2.return('early-exit'));   // triggers finally

// ── Custom iterables via Symbol.iterator ──────────────────────────────────
class Playlist {
  constructor(...songs) {
    this.songs = songs;
  }

  // Generator method as the iterator — clean pattern
  *[Symbol.iterator]() {
    for (const song of this.songs) {
      yield song;
    }
  }

  *shuffled() {
    const copy = [...this.songs];
    while (copy.length) {
      const i = Math.floor(Math.random() * copy.length);
      yield copy.splice(i, 1)[0];
    }
  }
}

const playlist = new Playlist('Song A', 'Song B', 'Song C');
console.log([...playlist]);
console.log([...playlist.shuffled()].length);

// ── Generators in object literals and classes ─────────────────────────────
const collection = {
  items: ['x', 'y', 'z'],
  *[Symbol.iterator]() {
    yield* this.items;
  },
  *reversed() {
    for (let i = this.items.length - 1; i >= 0; i--) {
      yield this.items[i];
    }
  },
};

console.log([...collection]);
console.log([...collection.reversed()]);

// ── Lazy evaluation pipeline ───────────────────────────────────────────────
function* map(iterable, fn) {
  for (const item of iterable) yield fn(item);
}

function* filter(iterable, pred) {
  for (const item of iterable) if (pred(item)) yield item;
}

const pipeline = take(
  filter(
    map(naturals(), n => n * n),
    n => n % 2 === 0
  ),
  5
);
console.log([...pipeline]);   // first 5 even squares
