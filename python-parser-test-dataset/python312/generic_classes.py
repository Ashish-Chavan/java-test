"""
Python 3.12 Feature: Generic Classes — New Syntax (PEP 695)
class MyClass[T]: replaces class MyClass(Generic[T]):
Supports type parameters directly in the class header.
Multiple type vars, bounds, and constraints all supported.
"""
from __future__ import annotations
from typing import Protocol, runtime_checkable


# ── Old approach (pre 3.12) ───────────────────────────────────────────────
# from typing import TypeVar, Generic
# T = TypeVar("T")
# class Stack(Generic[T]):  ...


# ── New syntax: class Name[T] ─────────────────────────────────────────────
class Stack[T]:
    """Type-safe stack using new generic syntax."""

    def __init__(self) -> None:
        self._items: list[T] = []

    def push(self, item: T) -> None:
        self._items.append(item)

    def pop(self) -> T:
        if not self._items:
            raise IndexError("Stack is empty")
        return self._items.pop()

    def peek(self) -> T:
        if not self._items:
            raise IndexError("Stack is empty")
        return self._items[-1]

    def __len__(self) -> int:
        return len(self._items)

    def __repr__(self) -> str:
        return f"Stack({self._items!r})"


s: Stack[int] = Stack()
s.push(1)
s.push(2)
s.push(3)
print(f"Stack: {s}, peek={s.peek()}, pop={s.pop()}, after={s}")


# ── Multiple type parameters ───────────────────────────────────────────────
class Pair[K, V]:
    """Key-value pair with two independent type parameters."""

    def __init__(self, key: K, value: V) -> None:
        self.key = key
        self.value = value

    def swap(self) -> Pair[V, K]:
        return Pair(self.value, self.key)

    def map_value[U](self, fn: (V) -> U) -> Pair[K, U]:
        return Pair(self.key, fn(self.value))

    def __repr__(self) -> str:
        return f"Pair({self.key!r}, {self.value!r})"


p: Pair[str, int] = Pair("age", 30)
print(f"\n{p}")
print(f"Swapped: {p.swap()}")
print(f"Mapped:  {p.map_value(lambda x: x * 2)}")


# ── Type bounds: [T: SomeType] ────────────────────────────────────────────
class SortedList[T: (int, float, str)]:
    """List that stays sorted; T must be int, float, or str."""

    def __init__(self) -> None:
        self._data: list[T] = []

    def insert(self, item: T) -> None:
        import bisect
        bisect.insort(self._data, item)

    def remove(self, item: T) -> None:
        self._data.remove(item)

    def __repr__(self) -> str:
        return f"SortedList({self._data!r})"


nums: SortedList[int] = SortedList()
for n in [5, 2, 8, 1, 9, 3]:
    nums.insert(n)
print(f"\n{nums}")

words: SortedList[str] = SortedList()
for w in ["banana", "apple", "cherry", "date"]:
    words.insert(w)
print(f"{words}")


# ── Protocol bound ────────────────────────────────────────────────────────
@runtime_checkable
class Comparable(Protocol):
    def __lt__(self, other) -> bool: ...
    def __le__(self, other) -> bool: ...


class MinHeap[T: Comparable]:
    """Min-heap where elements must be comparable."""

    def __init__(self) -> None:
        self._heap: list[T] = []

    def push(self, item: T) -> None:
        import heapq
        heapq.heappush(self._heap, item)

    def pop(self) -> T:
        import heapq
        return heapq.heappop(self._heap)

    def peek(self) -> T:
        return self._heap[0]

    def __len__(self) -> int:
        return len(self._heap)

    def __repr__(self) -> str:
        return f"MinHeap({sorted(self._heap)!r})"


heap: MinHeap[int] = MinHeap()
for n in [5, 2, 8, 1, 9, 3]:
    heap.push(n)
print(f"\n{heap}")
while heap:
    print(f"  pop: {heap.pop()}")


# ── Generic with inheritance ───────────────────────────────────────────────
class Container[T]:
    def __init__(self, value: T):
        self._value = value

    def get(self) -> T:
        return self._value

    def transform[U](self, fn: (T) -> U) -> Container[U]:
        return Container(fn(self._value))

    def __repr__(self) -> str:
        return f"Container({self._value!r})"


class ValidatedContainer[T](Container[T]):
    def __init__(self, value: T, validator: (T) -> bool):
        if not validator(value):
            raise ValueError(f"Validation failed for {value!r}")
        super().__init__(value)


c: Container[int] = Container(42)
c2 = c.transform(lambda x: f"value={x}")
print(f"\n{c}")
print(f"{c2}")

vc: ValidatedContainer[int] = ValidatedContainer(10, lambda x: x > 0)
print(f"Validated: {vc}")

try:
    bad = ValidatedContainer(-1, lambda x: x > 0)
except ValueError as e:
    print(f"Rejected: {e}")
