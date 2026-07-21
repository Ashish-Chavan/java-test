"""
Python 3.10 Feature: Structural Pattern Matching — Advanced (PEP 634)
Class patterns, guard clauses (if), nested patterns, __match_args__.
"""
from __future__ import annotations
from dataclasses import dataclass
from typing import Optional


# ── Class patterns ────────────────────────────────────────────────────────
@dataclass
class Point:
    x: float
    y: float

@dataclass
class Circle:
    center: Point
    radius: float

@dataclass
class Rectangle:
    top_left: Point
    bottom_right: Point

@dataclass
class Triangle:
    a: Point
    b: Point
    c: Point


def describe_shape(shape) -> str:
    match shape:
        case Circle(center=Point(x=0, y=0), radius=r):
            return f"Circle centered at origin, radius={r}"
        case Circle(center=Point(x=cx, y=cy), radius=r):
            return f"Circle at ({cx},{cy}), radius={r}"
        case Rectangle(
            top_left=Point(x=x1, y=y1),
            bottom_right=Point(x=x2, y=y2)
        ):
            w, h = abs(x2 - x1), abs(y2 - y1)
            return f"Rectangle {w}x{h} at ({x1},{y1})"
        case Triangle(a=Point(x=x1, y=y1), b=_, c=_):
            return f"Triangle starting at ({x1},{y1})"
        case _:
            return f"Unknown: {shape!r}"

shapes = [
    Circle(Point(0, 0), 5),
    Circle(Point(3, 4), 2),
    Rectangle(Point(0, 10), Point(5, 0)),
    Triangle(Point(0, 0), Point(1, 0), Point(0, 1)),
]
print("=== Class Patterns ===")
for s in shapes:
    print(f"  {describe_shape(s)}")


# ── __match_args__: positional class patterns ─────────────────────────────
class Color:
    __match_args__ = ("r", "g", "b")  # enables positional matching

    def __init__(self, r: int, g: int, b: int):
        self.r, self.g, self.b = r, g, b

    def __repr__(self):
        return f"Color({self.r}, {self.g}, {self.b})"


def classify_color(c: Color) -> str:
    match c:
        case Color(255, 0, 0):    return "pure red"
        case Color(0, 255, 0):    return "pure green"
        case Color(0, 0, 255):    return "pure blue"
        case Color(r, g, b) if r == g == b:
            return f"grey (value={r})"
        case Color(r, g, b) if r > g and r > b:
            return f"reddish (r={r})"
        case Color(r, g, b) if g > r and g > b:
            return f"greenish (g={g})"
        case Color(r, g, b) if b > r and b > g:
            return f"bluish (b={b})"
        case Color(r, g, b):
            return f"mixed ({r},{g},{b})"

print("\n=== __match_args__ + Guard Clauses ===")
colors = [
    Color(255, 0, 0), Color(0, 255, 0), Color(0, 0, 255),
    Color(128, 128, 128), Color(200, 50, 50), Color(30, 180, 30),
    Color(255, 165, 0),
]
for c in colors:
    print(f"  {c} -> {classify_color(c)}")


# ── Nested sequence + mapping patterns ────────────────────────────────────
def parse_api_response(response: dict) -> str:
    match response:
        case {"status": "ok", "data": {"users": [first, *rest]}}:
            return f"First user: {first}, and {len(rest)} more"
        case {"status": "ok", "data": {"user": {"name": name, "role": "admin"}}}:
            return f"Admin user: {name}"
        case {"status": "ok", "data": {"user": {"name": name}}}:
            return f"Regular user: {name}"
        case {"status": "error", "code": 404, "message": msg}:
            return f"Not found: {msg}"
        case {"status": "error", "code": code, "message": msg}:
            return f"Error {code}: {msg}"
        case {"status": "ok"}:
            return "OK but no data"
        case _:
            return "Malformed response"

responses = [
    {"status": "ok", "data": {"users": ["alice", "bob", "carol"]}},
    {"status": "ok", "data": {"user": {"name": "dave", "role": "admin"}}},
    {"status": "ok", "data": {"user": {"name": "eve", "role": "viewer"}}},
    {"status": "error", "code": 404, "message": "Resource not found"},
    {"status": "error", "code": 500, "message": "Internal error"},
    {"status": "ok"},
    {"garbage": True},
]
print("\n=== Nested Patterns ===")
for r in responses:
    print(f"  {parse_api_response(r)}")


# ── Pattern matching in recursive data structures ─────────────────────────
def eval_expr(expr) -> int:
    match expr:
        case int(n):
            return n
        case {"op": "+", "left": left, "right": right}:
            return eval_expr(left) + eval_expr(right)
        case {"op": "-", "left": left, "right": right}:
            return eval_expr(left) - eval_expr(right)
        case {"op": "*", "left": left, "right": right}:
            return eval_expr(left) * eval_expr(right)
        case {"op": "/", "left": left, "right": right}:
            return eval_expr(left) // eval_expr(right)
        case {"op": "neg", "value": v}:
            return -eval_expr(v)
        case _:
            raise ValueError(f"Unknown expression: {expr!r}")

ast = {
    "op": "+",
    "left": {"op": "*", "left": 3, "right": 4},
    "right": {"op": "neg", "value": 2},
}
print(f"\n=== Recursive Pattern Matching ===")
print(f"  (3 * 4) + (-2) = {eval_expr(ast)}")
