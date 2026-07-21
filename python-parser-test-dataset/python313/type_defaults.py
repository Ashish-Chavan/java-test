"""
Python 3.13 Feature: TypeVar Defaults (PEP 696)
TypeVar, ParamSpec, and TypeVarTuple can now have default values.
Enables better ergonomics for optional generic parameters.
"""
from __future__ import annotations
from typing import TypeVar, Generic, ParamSpec, Callable, overload


# ── TypeVar with default ───────────────────────────────────────────────────
T = TypeVar("T", default=str)      # default is str if not specified
U = TypeVar("U", default=int)


class Container(Generic[T]):
    """Generic container where T defaults to str."""

    def __init__(self, value: T) -> None:
        self.value = value

    def get(self) -> T:
        return self.value

    def __repr__(self) -> str:
        return f"Container[{type(self.value).__name__}]({self.value!r})"


# With explicit type parameter
int_container: Container[int] = Container(42)
str_container: Container[str] = Container("hello")

# Type checker infers Container[str] (the default)
default_container: Container = Container("implicit str")

print("=== TypeVar Defaults ===")
print(int_container)
print(str_container)
print(default_container)


# ── Default in two-parameter generic ─────────────────────────────────────
K = TypeVar("K", default=str)
V = TypeVar("V", default=int)


class Mapping(Generic[K, V]):
    """Mapping where K defaults to str and V to int."""

    def __init__(self) -> None:
        self._data: dict = {}

    def set(self, key: K, value: V) -> None:
        self._data[key] = value

    def get(self, key: K, default: V | None = None) -> V | None:
        return self._data.get(key, default)  # type: ignore

    def items(self) -> list[tuple[K, V]]:
        return list(self._data.items())  # type: ignore

    def __repr__(self) -> str:
        return f"Mapping({self._data!r})"


# Explicit types
str_to_list: Mapping[str, list] = Mapping()
str_to_list.set("fruits", ["apple", "banana"])

# Default types (str -> int)
default_mapping: Mapping = Mapping()
default_mapping.set("count", 42)
default_mapping.set("score", 100)

print("\n=== Two-Parameter Defaults ===")
print(str_to_list)
print(default_mapping)


# ── TypeVar default with bound ────────────────────────────────────────────
class Comparable:
    def __init__(self, value):
        self.value = value
    def __lt__(self, other): return self.value < other.value
    def __le__(self, other): return self.value <= other.value
    def __repr__(self): return f"Comparable({self.value})"


# Bound AND default
CT = TypeVar("CT", bound=Comparable, default=Comparable)


class SortedContainer(Generic[CT]):
    def __init__(self) -> None:
        self._items: list[CT] = []

    def add(self, item: CT) -> None:
        self._items.append(item)
        self._items.sort()

    def __repr__(self) -> str:
        return f"SortedContainer({self._items})"


sc: SortedContainer = SortedContainer()
for v in [3, 1, 4, 1, 5]:
    sc.add(Comparable(v))
print(f"\n{sc}")


# ── ParamSpec with default ────────────────────────────────────────────────
P = ParamSpec("P", default=...)   # default ParamSpec


class Handler(Generic[P]):
    """Callable wrapper with defaulting ParamSpec."""

    def __init__(self, fn: Callable[P, None]) -> None:
        self._fn = fn

    def call(self, *args: P.args, **kwargs: P.kwargs) -> None:
        self._fn(*args, **kwargs)


def log(message: str, level: str = "INFO") -> None:
    print(f"[{level}] {message}")

handler: Handler = Handler(log)
handler.call("Server started")
handler.call("Warning!", level="WARN")


# ── Practical: result type with default error ─────────────────────────────
E = TypeVar("E", default=Exception)
OkT = TypeVar("OkT")


class Result(Generic[OkT, E]):
    """
    Result type where error defaults to Exception.
    Result[int] means Result[int, Exception].
    """

    def __init__(self, value: OkT | None = None, error: E | None = None) -> None:
        self._value = value
        self._error = error

    @classmethod
    def ok(cls, value: OkT) -> Result[OkT, E]:
        return cls(value=value)

    @classmethod
    def err(cls, error: E) -> Result[OkT, E]:
        return cls(error=error)

    def is_ok(self) -> bool:
        return self._error is None

    def unwrap(self) -> OkT:
        if self._error is not None:
            raise self._error
        return self._value  # type: ignore

    def unwrap_or(self, default: OkT) -> OkT:
        return self._value if self.is_ok() else default  # type: ignore

    def __repr__(self) -> str:
        if self.is_ok():
            return f"Ok({self._value!r})"
        return f"Err({self._error!r})"


print("\n=== Result Type with Default Error ===")

# Use default error type (Exception)
ok_result: Result[int] = Result.ok(42)
err_result: Result[int] = Result.err(ValueError("bad input"))

# Use specific error type
io_result: Result[str, IOError] = Result.err(IOError("file not found"))

print(ok_result)
print(err_result)
print(io_result)
print(f"ok.unwrap() = {ok_result.unwrap()}")
print(f"err.unwrap_or(-1) = {err_result.unwrap_or(-1)}")
