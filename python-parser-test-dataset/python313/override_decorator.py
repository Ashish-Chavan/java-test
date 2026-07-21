"""
Python 3.13 Feature: @override (PEP 698) and @deprecated (PEP 702)

@override — marks a method as intentionally overriding a base class method.
  Type checkers error if no matching base method exists.
  Available since 3.12 in typing, fully stable in 3.13.

@deprecated — marks a function/class as deprecated.
  Emits DeprecationWarning at runtime when called.
  Readable by type checkers for IDE warnings.
"""
import warnings
from typing import override
from typing_extensions import deprecated   # also available from warnings in 3.13


# ── @override ─────────────────────────────────────────────────────────────
print("=== @override decorator ===")

class Animal:
    def speak(self) -> str:
        return "..."

    def move(self) -> str:
        return "moves"

    def describe(self) -> str:
        return f"{type(self).__name__}: speaks={self.speak()!r}, moves={self.move()!r}"


class Dog(Animal):
    @override
    def speak(self) -> str:         # ✓ overrides Animal.speak
        return "Woof!"

    @override
    def move(self) -> str:          # ✓ overrides Animal.move
        return "runs"


class Cat(Animal):
    @override
    def speak(self) -> str:         # ✓ correct override
        return "Meow!"

    # @override
    # def spek(self) -> str:        # ✗ type checker would flag: no base method 'spek'
    #     return "typo"


class Robot(Animal):
    @override
    def speak(self) -> str:
        return "Beep boop"

    @override
    def move(self) -> str:
        return "rolls"


animals = [Dog(), Cat(), Robot()]
for animal in animals:
    print(f"  {animal.describe()}")


# ── @override in abstract classes ─────────────────────────────────────────
from abc import ABC, abstractmethod

class Shape(ABC):
    @abstractmethod
    def area(self) -> float: ...

    @abstractmethod
    def perimeter(self) -> float: ...

    def describe(self) -> str:
        return f"{type(self).__name__}: area={self.area():.2f}, perimeter={self.perimeter():.2f}"


class Circle(Shape):
    def __init__(self, radius: float):
        self.radius = radius

    @override
    def area(self) -> float:
        import math
        return math.pi * self.radius ** 2

    @override
    def perimeter(self) -> float:
        import math
        return 2 * math.pi * self.radius


class Rectangle(Shape):
    def __init__(self, w: float, h: float):
        self.w, self.h = w, h

    @override
    def area(self) -> float:
        return self.w * self.h

    @override
    def perimeter(self) -> float:
        return 2 * (self.w + self.h)


shapes = [Circle(5), Rectangle(4, 6)]
for s in shapes:
    print(f"  {s.describe()}")


# ── @deprecated ───────────────────────────────────────────────────────────
print("\n=== @deprecated decorator ===")

@deprecated("Use new_function() instead — added in version 2.0")
def old_function(x: int, y: int) -> int:
    """Old implementation kept for backward compatibility."""
    return x + y


@deprecated("Use UserV2 class instead")
class User:
    def __init__(self, name: str):
        self.name = name


# Calling deprecated items emits DeprecationWarning
with warnings.catch_warnings(record=True) as caught:
    warnings.simplefilter("always")

    result = old_function(3, 4)
    user = User("Alice")

    for w in caught:
        print(f"  Warning: {w.category.__name__}: {w.message}")
        print(f"    from: {w.filename}:{w.lineno}")


# ── Deprecating specific methods ──────────────────────────────────────────
class APIClient:
    def get(self, url: str) -> dict:
        """Current API."""
        return {"url": url, "status": 200}

    @deprecated("Use get() with params= argument instead")
    def get_with_params(self, url: str, **params) -> dict:
        """Deprecated: manually builds query string."""
        query = "&".join(f"{k}={v}" for k, v in params.items())
        return self.get(f"{url}?{query}")

    @deprecated("Use client.session.post() for better control")
    def post(self, url: str, data: dict) -> dict:
        return {"url": url, "data": data, "status": 201}


client = APIClient()

with warnings.catch_warnings(record=True) as caught:
    warnings.simplefilter("always")
    result = client.get_with_params("/users", page=1, limit=10)
    print(f"\nResult: {result}")

for w in caught:
    print(f"  ⚠ {w.message}")


# ── Combining @override and @deprecated ───────────────────────────────────
print("\n=== Combined usage ===")

class BaseProcessor:
    def process(self, data: str) -> str:
        return data

    def process_v2(self, data: str, *, strict: bool = False) -> str:
        return data.strip() if strict else data


class LegacyProcessor(BaseProcessor):
    @override
    @deprecated("LegacyProcessor.process() is deprecated; use process_v2(strict=True)")
    def process(self, data: str) -> str:
        return data.upper()

    @override
    def process_v2(self, data: str, *, strict: bool = False) -> str:
        return data.strip().upper() if strict else data.upper()


proc = LegacyProcessor()
with warnings.catch_warnings(record=True) as caught:
    warnings.simplefilter("always")
    r1 = proc.process("  hello  ")
    r2 = proc.process_v2("  hello  ", strict=True)

print(f"  process():         {r1!r}")
print(f"  process_v2():      {r2!r}")
for w in caught:
    print(f"  ⚠ {w.message}")
