"""
Python 3.7 Feature: Dataclasses (PEP 557)
@dataclass auto-generates __init__, __repr__, __eq__ and more.
Supports field(), __post_init__, ClassVar, InitVar, and inheritance.
"""
from __future__ import annotations
from dataclasses import dataclass, field, fields, asdict, astuple, replace, KW_ONLY
from typing import ClassVar, List, Optional
import math


# ── Basic dataclass ────────────────────────────────────────────────────────
@dataclass
class Point:
    x: float
    y: float

    def distance_to(self, other: Point) -> float:
        return math.sqrt((self.x - other.x)**2 + (self.y - other.y)**2)


p1 = Point(1.0, 2.0)
p2 = Point(4.0, 6.0)
print(f"Point: {p1}")                       # auto __repr__
print(f"Equal: {p1 == Point(1.0, 2.0)}")    # auto __eq__
print(f"Distance: {p1.distance_to(p2):.4f}")


# ── Default values and field() ─────────────────────────────────────────────
@dataclass
class Config:
    host: str = "localhost"
    port: int = 8080
    debug: bool = False
    tags: List[str] = field(default_factory=list)    # mutable default
    metadata: dict = field(default_factory=dict)
    _internal: str = field(default="", repr=False)   # hidden from repr


cfg = Config(host="prod.example.com", tags=["web", "api"])
print(f"\nConfig: {cfg}")


# ── __post_init__ for validation and derived fields ────────────────────────
@dataclass
class Circle:
    radius: float
    _area: float = field(init=False, repr=False)
    _circumference: float = field(init=False, repr=False)

    def __post_init__(self):
        if self.radius <= 0:
            raise ValueError(f"Radius must be positive, got {self.radius}")
        self._area = math.pi * self.radius ** 2
        self._circumference = 2 * math.pi * self.radius

    @property
    def area(self) -> float:
        return self._area

    @property
    def circumference(self) -> float:
        return self._circumference


c = Circle(5.0)
print(f"\nCircle: {c}")
print(f"  area={c.area:.4f}, circumference={c.circumference:.4f}")


# ── Frozen dataclass (immutable) ───────────────────────────────────────────
@dataclass(frozen=True)
class Coordinate:
    lat: float
    lon: float
    altitude: float = 0.0

    def __hash__(self):     # frozen dataclasses are hashable
        return hash((self.lat, self.lon, self.altitude))


home = Coordinate(51.5074, -0.1278, 11.0)
print(f"\nCoordinate: {home}")
print(f"Hashable: {hash(home)}")

locations = {home: "London", Coordinate(48.8566, 2.3522): "Paris"}
print(f"Lookup: {locations[home]}")


# ── ClassVar and ordering ─────────────────────────────────────────────────
@dataclass(order=True)
class Version:
    major: int
    minor: int
    patch: int = 0
    _count: ClassVar[int] = 0   # ClassVar excluded from __init__

    def __post_init__(self):
        Version._count += 1

    def __str__(self):
        return f"{self.major}.{self.minor}.{self.patch}"


versions = [Version(1, 2), Version(2, 0), Version(1, 10, 3), Version(1, 2, 1)]
print(f"\nVersions sorted: {sorted(versions)}")
print(f"Max version: {max(versions)}")


# ── Inheritance ────────────────────────────────────────────────────────────
@dataclass
class Animal:
    name: str
    sound: str
    legs: int = 4

@dataclass
class Pet(Animal):
    owner: str = ""
    vaccinated: bool = False

@dataclass
class Dog(Pet):
    breed: str = "Mixed"

    def speak(self) -> str:
        return f"{self.name} says {self.sound}!"


rex = Dog(name="Rex", sound="Woof", owner="Alice", breed="Labrador", vaccinated=True)
print(f"\nDog: {rex}")
print(rex.speak())


# ── asdict, astuple, replace ──────────────────────────────────────────────
print(f"\nasdict:   {asdict(p1)}")
print(f"astuple:  {astuple(p1)}")
p3 = replace(p1, x=99.0)
print(f"replace:  {p3}")


# ── Inspecting fields ──────────────────────────────────────────────────────
print(f"\nFields of Dog:")
for f in fields(Dog):
    print(f"  {f.name}: {f.type} (default={f.default!r})")
