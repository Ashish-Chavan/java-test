"""
Python 3.10 Feature: Union Type Syntax with | (PEP 604)
Use X | Y instead of Union[X, Y] in type hints.
Works in annotations, isinstance(), and issubclass().
"""
from __future__ import annotations
from typing import get_type_hints


# ── Basic | union in annotations ──────────────────────────────────────────
def parse_int(value: str | int | float) -> int:
    if isinstance(value, int):
        return value
    if isinstance(value, float):
        return int(value)
    return int(value.strip())


def stringify(value: int | float | bool | None) -> str:
    if value is None:
        return "null"
    if isinstance(value, bool):
        return str(value).lower()
    return str(value)


print("=== Basic | Union ===")
print(parse_int("42"))
print(parse_int(3.7))
print(parse_int(100))

print(stringify(None))
print(stringify(True))
print(stringify(42))
print(stringify(3.14))


# ── X | None replaces Optional[X] ────────────────────────────────────────
def find_user(user_id: int) -> dict | None:
    users = {1: {"name": "Alice"}, 2: {"name": "Bob"}}
    return users.get(user_id)


def get_name(user: dict | None) -> str:
    if user is None:
        return "Unknown"
    return user["name"]


print(f"\nUser 1: {get_name(find_user(1))}")
print(f"User 9: {get_name(find_user(9))}")


# ── Nested unions ──────────────────────────────────────────────────────────
JsonPrimitive = int | float | str | bool | None
JsonValue = JsonPrimitive | list | dict


def describe_json(val: JsonValue) -> str:
    match val:
        case None:             return "null"
        case bool(b):          return f"bool({b})"
        case int(n):           return f"int({n})"
        case float(f):         return f"float({f})"
        case str(s):           return f"str({s!r})"
        case list(items):      return f"array[{len(items)}]"
        case dict(obj):        return f"object{{{len(obj)} keys}}"


print("\n=== JSON Types ===")
for val in [None, True, 42, 3.14, "hello", [1, 2, 3], {"a": 1}]:
    print(f"  {val!r:20} -> {describe_json(val)}")


# ── isinstance() with | (runtime union) ──────────────────────────────────
def safe_divide(a: int | float, b: int | float) -> float | None:
    if not isinstance(a, int | float):     # | works in isinstance too!
        raise TypeError(f"Expected number, got {type(a)}")
    if not isinstance(b, int | float):
        raise TypeError(f"Expected number, got {type(b)}")
    if b == 0:
        return None
    return a / b


print(f"\n10 / 3 = {safe_divide(10, 3):.4f}")
print(f"5 / 0 = {safe_divide(5, 0)}")
print(f"isinstance check: {isinstance('x', int | str | float)}")
print(f"isinstance check: {isinstance(42,  int | str | float)}")


# ── Complex type aliases with | ────────────────────────────────────────────
Number   = int | float
Vector2D = tuple[Number, Number]
Vector3D = tuple[Number, Number, Number]
Vector   = Vector2D | Vector3D


def dot_product(a: Vector, b: Vector) -> Number:
    if len(a) != len(b):
        raise ValueError("Vectors must have same dimension")
    return sum(x * y for x, y in zip(a, b))


def magnitude(v: Vector) -> float:
    return sum(x**2 for x in v) ** 0.5


print(f"\nDot product (2D): {dot_product((1, 2), (3, 4))}")
print(f"Dot product (3D): {dot_product((1, 2, 3), (4, 5, 6))}")
print(f"Magnitude: {magnitude((3.0, 4.0)):.4f}")


# ── In class annotations ──────────────────────────────────────────────────
class Response:
    status: int
    body: str | bytes | None
    headers: dict[str, str]
    error: Exception | None

    def __init__(self, status: int, body: str | bytes | None = None):
        self.status = status
        self.body = body
        self.headers = {}
        self.error = None

    def text(self) -> str | None:
        if isinstance(self.body, bytes):
            return self.body.decode()
        return self.body

    def is_ok(self) -> bool:
        return 200 <= self.status < 300


resp = Response(200, b"Hello World")
print(f"\nResponse: status={resp.status}, ok={resp.is_ok()}, text={resp.text()!r}")

err_resp = Response(404)
err_resp.error = FileNotFoundError("not found")
print(f"Error response: {err_resp.is_ok()}, error={err_resp.error}")


# ── Callable with | ────────────────────────────────────────────────────────
from typing import Callable

Handler = Callable[[str], str | None]

def apply_handler(handler: Handler, data: str) -> str:
    result = handler(data)
    return result if result is not None else ""


def uppercase_handler(s: str) -> str | None:
    return s.upper() if s.strip() else None


print(f"\nHandler: {apply_handler(uppercase_handler, 'hello')!r}")
print(f"Handler: {apply_handler(uppercase_handler, '   ')!r}")
