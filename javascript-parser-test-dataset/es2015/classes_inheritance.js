/**
 * ES2015 (ES6) Feature: Classes and Inheritance
 * class declarations, extends, super, getters/setters,
 * static members, computed method names.
 */
'use strict';

// ── Basic class declaration ────────────────────────────────────────────────
class Animal {
  constructor(name, sound) {
    this.name = name;
    this.sound = sound;
  }

  speak() {
    return `${this.name} says ${this.sound}`;
  }

  // Getter
  get description() {
    return `Animal(${this.name})`;
  }

  // Setter
  set nickname(value) {
    this._nickname = value.trim();
  }

  get nickname() {
    return this._nickname || this.name;
  }

  // Static method
  static create(name, sound) {
    return new Animal(name, sound);
  }

  // Static property via getter (ES2015 style)
  static get kingdom() {
    return 'Animalia';
  }
}

const generic = new Animal('Generic', '...');
console.log(generic.speak());
console.log(generic.description);
generic.nickname = '  Baxter  ';
console.log(generic.nickname);
console.log(Animal.kingdom);
console.log(Animal.create('Factory', 'beep').speak());

// ── Inheritance with extends and super ────────────────────────────────────
class Dog extends Animal {
  constructor(name, breed) {
    super(name, 'Woof');   // must call super before this
    this.breed = breed;
  }

  speak() {
    // super method call
    return `${super.speak()} (a ${this.breed})`;
  }

  fetch() {
    return `${this.name} fetches the ball!`;
  }
}

class Puppy extends Dog {
  constructor(name, breed, age) {
    super(name, breed);
    this.age = age;
  }

  speak() {
    return `${super.speak()} — only ${this.age} months old`;
  }
}

const rex = new Dog('Rex', 'Labrador');
console.log(rex.speak());
console.log(rex.fetch());

const pup = new Puppy('Buddy', 'Beagle', 4);
console.log(pup.speak());
console.log(pup instanceof Puppy, pup instanceof Dog, pup instanceof Animal);

// ── Class expressions ──────────────────────────────────────────────────────
const Shape = class {
  constructor(sides) {
    this.sides = sides;
  }
};

const NamedShape = class ShapeImpl {
  constructor(sides) {
    this.sides = sides;
  }
  clone() {
    return new ShapeImpl(this.sides);  // internal name usable inside
  }
};

const square = new NamedShape(4);
console.log(square.clone().sides);

// ── Computed method names ──────────────────────────────────────────────────
const methodName = 'dynamicMethod';
const getterName = 'dynamicValue';

class Dynamic {
  [methodName]() {
    return 'called via computed name';
  }

  get [getterName]() {
    return 42;
  }

  ['method_' + 2]() {
    return 'concatenated name';
  }
}

const d = new Dynamic();
console.log(d.dynamicMethod());
console.log(d.dynamicValue);
console.log(d.method_2());

// ── extends expression (mixins pattern) ────────────────────────────────────
const Serializable = (Base) => class extends Base {
  serialize() {
    return JSON.stringify(this);
  }
};

const Comparable = (Base) => class extends Base {
  equals(other) {
    return JSON.stringify(this) === JSON.stringify(other);
  }
};

class Point {
  constructor(x, y) {
    this.x = x;
    this.y = y;
  }
}

class SmartPoint extends Serializable(Comparable(Point)) {}

const p1 = new SmartPoint(1, 2);
const p2 = new SmartPoint(1, 2);
console.log(p1.serialize());
console.log(p1.equals(p2));

// ── new.target ─────────────────────────────────────────────────────────────
class OnlyNew {
  constructor() {
    if (new.target === undefined) {
      throw new Error('Must be called with new');
    }
    this.createdVia = new.target.name;
  }
}

class SubOnlyNew extends OnlyNew {}

console.log(new OnlyNew().createdVia);      // OnlyNew
console.log(new SubOnlyNew().createdVia);   // SubOnlyNew
