"""
Python 3.11 Feature: Variadic Generics — TypeVarTuple + Unpack (PEP 646)
TypeVarTuple (*Ts) captures an arbitrary number of type parameters.
Unpack[Ts] unpacks them. Critical for typing N-dimensional arrays,
function composition, and tuple transformations.
"""
from __future__ import annotations
from typing import TypeVar, TypeVarTuple, Unpack, Generic, overload, Callable


T  = TypeVar("T")
Ts = TypeVarTuple("Ts")


# ── Basic TypeVarTuple ────────────────────────────────────────────────────
class Tuple(Generic[*Ts]):
    """A typed tuple wrapper demonstrating TypeVarTuple syntax."""
    def __init__(self, *args: *Ts):
        self._data = args

    def __repr__(self) -> str:
        return f"Tuple{self._data}"

    def to_tuple(self) -> tuple[*Ts]:
        return self._data  # type: ignore


t1: Tuple[int, str, float] = Tuple(1, "hello", 3.14)
t2: Tuple[bool, int, int, str] = Tuple(True, 10, 20, "end")
print(f"t1: {t1}")
print(f"t2: {t2}")


# ── Prepend/Append patterns ────────────────────────────────────────────────
class PrependedTuple(Generic[T, *Ts]):
    """T is prepended before the variadic types."""
    def __init__(self, first: T, *rest: *Ts):
        self.first = first
        self.rest = rest

    def __repr__(self):
        return f"Prepended({self.first!r}, {self.rest!r})"


class AppendedTuple(Generic[*Ts, T]):
    """T is appended after the variadic types."""
    def __init__(self, *init: *Ts, last: T):
        self.init = init
        self.last = last

    def __repr__(self):
        return f"Appended({self.init!r}, last={self.last!r})"


p = PrependedTuple(42, "hello", True)
a = AppendedTuple(1, 2, 3, last="end")
print(f"\n{p}")
print(f"{a}")


# ── Array/Tensor shape typing ──────────────────────────────────────────────
# The canonical use case: typing shape-typed arrays like numpy

from typing import Protocol

class Shape(Protocol):
    """Marker for shape dimensions."""
    ...

class Batch:    pass
class Height:   pass
class Width:    pass
class Channels: pass


class Array(Generic[*Ts]):
    """
    Shape-typed array. Array[Batch, Height, Width, Channels]
    represents a 4D array with those named dimensions.
    """
    def __init__(self, data: list, shape: tuple):
        self._data = data
        self._shape = shape

    @property
    def shape(self) -> tuple[*Ts]:
        return self._shape  # type: ignore

    def reshape(self, *new_shape: int) -> "Array":
        return Array(self._data, new_shape)

    def __repr__(self) -> str:
        return f"Array(shape={self._shape})"


# Type-safe array operations
image: Array[Batch, Height, Width, Channels] = Array([], (32, 224, 224, 3))
flat: Array[Batch, int] = image.reshape(32, -1)
print(f"\nImage array: {image}")
print(f"Flattened:   {flat}")


# ── Function composition with TypeVarTuple ────────────────────────────────
def map_tuple(fn: Callable[[T], T], t: tuple[*Ts]) -> tuple:
    """Apply fn to each element of a tuple."""
    return tuple(fn(x) for x in t)  # type: ignore


def zip_tuples(
    a: tuple[*Ts],
    b: tuple[*Ts],
) -> list[tuple]:
    """Zip two same-shaped tuples."""
    return list(zip(a, b))


nums   = (1, 2, 3, 4, 5)
doubled = map_tuple(lambda x: x * 2, nums)
print(f"\nDoubled tuple: {doubled}")

zipped = zip_tuples((1, 2, 3), (4, 5, 6))
print(f"Zipped: {zipped}")


# ── Pipeline with variadic types ──────────────────────────────────────────
class Pipeline(Generic[*Ts]):
    """
    A processing pipeline whose type captures all intermediate types.
    """
    def __init__(self, *steps):
        self._steps = steps

    def run(self, input_data):
        result = input_data
        for step in self._steps:
            result = step(result)
        return result

    def __repr__(self):
        return f"Pipeline({len(self._steps)} steps)"


pipeline = Pipeline(
    lambda x: x * 2,
    lambda x: x + 10,
    lambda x: str(x),
    lambda x: f"result: {x}",
)
print(f"\n{pipeline}")
print(f"Output: {pipeline.run(5)}")


# ── TypeVarTuple with Unpack in function signatures ────────────────────────
def first_and_rest(first: T, *rest: *Ts) -> tuple[T, tuple[*Ts]]:
    return (first, rest)  # type: ignore

head, tail = first_and_rest(1, "a", True, 3.14)
print(f"\nHead: {head!r}, Tail: {tail!r}")
