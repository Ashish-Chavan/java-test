"""
Python 3.12 Feature: Generic Functions — New Syntax (PEP 695)
def fn[T](...) replaces def fn(... : T) with separate TypeVar declaration.
Cleaner, more readable, and scoped to the function.
"""
from __future__ import annotations
from typing import Callable


# ── Old approach (pre 3.12) ───────────────────────────────────────────────
# from typing import TypeVar
# T = TypeVar("T")
# def first(lst: list[T]) -> T: ...  (T was module-scoped)


# ── New syntax: def fn[T](...) ────────────────────────────────────────────
def first[T](lst: list[T]) -> T:
    """Return the first element of a list."""
    if not lst:
        raise IndexError("List is empty")
    return lst[0]


def last[T](lst: list[T]) -> T:
    """Return the last element of a list."""
    return lst[-1]


def identity[T](value: T) -> T:
    """Return the value unchanged."""
    return value


print("=== Basic Generic Functions ===")
print(first([1, 2, 3]))
print(first(["a", "b", "c"]))
print(last([10, 20, 30]))
print(identity(42))
print(identity("hello"))


# ── Multiple type parameters ───────────────────────────────────────────────
def zip_with[T, U, V](
    fn: Callable[[T, U], V],
    xs: list[T],
    ys: list[U],
) -> list[V]:
    return [fn(x, y) for x, y in zip(xs, ys)]


def map_pair[K, V, U](
    fn: Callable[[V], U],
    pairs: list[tuple[K, V]],
) -> list[tuple[K, U]]:
    return [(k, fn(v)) for k, v in pairs]


print("\n=== Multiple Type Params ===")
sums = zip_with(lambda a, b: a + b, [1, 2, 3], [10, 20, 30])
print(f"zip_with(+): {sums}")

pairs = [("a", 1), ("b", 2), ("c", 3)]
doubled = map_pair(lambda x: x * 2, pairs)
print(f"map_pair(*2): {doubled}")


# ── Type bounds [T: SomeType] ─────────────────────────────────────────────
def maximum[T: (int, float, str)](items: list[T]) -> T:
    """Find maximum — T must be int, float, or str."""
    return max(items)


def minimum[T: (int, float, str)](items: list[T]) -> T:
    return min(items)


def clamp[T: (int, float)](value: T, lo: T, hi: T) -> T:
    return max(lo, min(value, hi))


print("\n=== Bounded Type Params ===")
print(f"max ints:   {maximum([3, 1, 4, 1, 5, 9, 2, 6])}")
print(f"max strs:   {maximum(['banana', 'apple', 'cherry'])}")
print(f"clamp:      {clamp(15, 0, 10)}")
print(f"clamp:      {clamp(-3.5, 0.0, 1.0)}")


# ── Higher-order generic functions ────────────────────────────────────────
def compose[T, U, V](f: Callable[[U], V], g: Callable[[T], U]) -> Callable[[T], V]:
    """Compose two functions: compose(f, g)(x) = f(g(x))"""
    def composed(x: T) -> V:
        return f(g(x))
    return composed


def pipe[T](*fns: Callable) -> Callable[[T], object]:
    """Apply functions left-to-right."""
    def piped(value: T):
        result = value
        for fn in fns:
            result = fn(result)
        return result
    return piped


def memoize[T, U](fn: Callable[[T], U]) -> Callable[[T], U]:
    """Cache return values."""
    cache: dict[T, U] = {}
    def wrapper(arg: T) -> U:
        if arg not in cache:
            cache[arg] = fn(arg)
        return cache[arg]
    return wrapper


print("\n=== Higher-Order Generic Functions ===")
double = lambda x: x * 2
add_one = lambda x: x + 1
to_str = lambda x: f"value={x}"

double_then_add = compose(add_one, double)
print(f"compose(add_one, double)(5) = {double_then_add(5)}")

pipeline = pipe(double, add_one, to_str)
print(f"pipe(double, add_one, str)(3) = {pipeline(3)}")

@memoize
def fib(n: int) -> int:
    if n <= 1:
        return n
    return fib(n - 1) + fib(n - 2)

print(f"fib(10) = {fib(10)}")
print(f"fib(30) = {fib(30)}")


# ── Generic filter, map, reduce ───────────────────────────────────────────
def filter_items[T](items: list[T], pred: Callable[[T], bool]) -> list[T]:
    return [x for x in items if pred(x)]


def map_items[T, U](items: list[T], fn: Callable[[T], U]) -> list[U]:
    return [fn(x) for x in items]


def reduce_items[T, U](items: list[T], fn: Callable[[U, T], U], init: U) -> U:
    result = init
    for item in items:
        result = fn(result, item)
    return result


print("\n=== Generic filter/map/reduce ===")
nums = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
evens  = filter_items(nums, lambda x: x % 2 == 0)
doubled = map_items(evens, lambda x: x * 2)
total  = reduce_items(doubled, lambda acc, x: acc + x, 0)
print(f"evens={evens}, doubled={doubled}, total={total}")
