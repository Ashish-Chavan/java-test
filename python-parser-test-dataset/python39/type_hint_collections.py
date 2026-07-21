"""
Python 3.9 Feature: Type Hint Improvements (PEP 585 + stdlib)
tuple[int, ...], type[MyClass], Annotated[], and using
standard collections in annotations without typing imports.
"""
from __future__ import annotations
from typing import Annotated, get_type_hints, get_args, get_origin
import typing


# ── tuple[] with specific element types ───────────────────────────────────
def rgb_to_hex(color: tuple[int, int, int]) -> str:
    r, g, b = color
    return f"#{r:02X}{g:02X}{b:02X}"


def parse_point(data: tuple[float, float]) -> str:
    x, y = data
    return f"({x:.2f}, {y:.2f})"


def parse_record(row: tuple[int, str, float, bool]) -> dict:
    id_, name, score, active = row
    return {"id": id_, "name": name, "score": score, "active": active}


# tuple[T, ...] = homogeneous tuple of any length
def sum_all(values: tuple[int, ...]) -> int:
    return sum(values)


print("=== tuple[] annotations ===")
print(rgb_to_hex((255, 165, 0)))
print(parse_point((3.14159, 2.71828)))
print(parse_record((1, "Alice", 92.5, True)))
print(sum_all((1, 2, 3, 4, 5)))


# ── type[T] — annotating a class itself (not an instance) ─────────────────
class Animal:
    name: str
    def __init__(self, name: str):
        self.name = name
    def speak(self) -> str:
        return f"{self.name} makes a sound"

class Dog(Animal):
    def speak(self) -> str:
        return f"{self.name} says Woof!"

class Cat(Animal):
    def speak(self) -> str:
        return f"{self.name} says Meow!"


def create_animal(cls: type[Animal], name: str) -> Animal:
    """Takes the CLASS, not an instance."""
    return cls(name)


def create_many(cls: type[Animal], names: list[str]) -> list[Animal]:
    return [cls(name) for name in names]


print("\n=== type[T] annotations ===")
dog = create_animal(Dog, "Rex")
cat = create_animal(Cat, "Whiskers")
print(dog.speak())
print(cat.speak())

pack = create_many(Dog, ["Buddy", "Max", "Bella"])
for animal in pack:
    print(f"  {animal.speak()}")


# ── Annotated[] — attaching metadata to type hints ────────────────────────
# Annotated[T, metadata...] — type is T, extra info is metadata

# Define validation metadata classes
class Range:
    def __init__(self, min_val: float, max_val: float):
        self.min_val = min_val
        self.max_val = max_val
    def validate(self, v):
        return self.min_val <= v <= self.max_val

class MaxLen:
    def __init__(self, max_length: int):
        self.max_length = max_length
    def validate(self, v):
        return len(v) <= self.max_length

class Regex:
    import re as _re
    def __init__(self, pattern: str):
        self.pattern = pattern
    def validate(self, v):
        import re
        return bool(re.fullmatch(self.pattern, v))


# Annotated type aliases
Age       = Annotated[int,   Range(0, 150)]
Score     = Annotated[float, Range(0.0, 100.0)]
Username  = Annotated[str,   MaxLen(20), Regex(r"[a-z][a-z0-9_]*")]
Password  = Annotated[str,   MaxLen(128)]


def validate_annotated(value, annotation) -> list[str]:
    """Extract and apply validators from Annotated metadata."""
    errors = []
    if get_origin(annotation) is Annotated:
        _, *validators = get_args(annotation)
        for v in validators:
            if hasattr(v, "validate") and not v.validate(value):
                errors.append(f"{type(v).__name__} validation failed for {value!r}")
    return errors


print("\n=== Annotated[] metadata ===")
test_cases = [
    (25, Age, "age=25"),
    (200, Age, "age=200"),
    (87.5, Score, "score=87.5"),
    ("alice_99", Username, "username=alice_99"),
    ("Alice", Username, "username=Alice (uppercase)"),
    ("a" * 25, Username, "username too long"),
]
for value, ann, label in test_cases:
    errors = validate_annotated(value, ann)
    status = "✓" if not errors else f"✗ {errors}"
    print(f"  {label}: {status}")


# ── stdlib collections in annotations ─────────────────────────────────────
from collections import deque, defaultdict, Counter, ChainMap

def process_queue(q: deque[str]) -> list[str]:
    results = []
    while q:
        results.append(q.popleft())
    return results

def build_counter(items: list[str]) -> Counter[str]:
    return Counter(items)

def layer_config(*configs: dict[str, str]) -> ChainMap[str, str]:
    return ChainMap(*configs)


print("\n=== stdlib collection annotations ===")
q: deque[str] = deque(["a", "b", "c"])
print(f"Queue processed: {process_queue(q)}")

c: Counter[str] = build_counter(["apple", "banana", "apple", "cherry", "apple"])
print(f"Counter: {c.most_common(2)}")

layered: ChainMap[str, str] = layer_config(
    {"env": "production"},
    {"host": "prod.example.com"},
    {"host": "localhost", "port": "8080"},
)
print(f"ChainMap host: {layered['host']}")   # production wins
