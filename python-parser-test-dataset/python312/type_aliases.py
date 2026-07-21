"""
Python 3.12 Feature: Type Aliases with 'type' statement (PEP 695)
The new 'type' keyword creates explicit, clean type aliases.
Replaces the old: MyAlias = Union[int, str]  (just assignment)
and the verbose: MyAlias: TypeAlias = Union[int, str]
"""
from __future__ import annotations
from typing import TypeAlias    # old approach — for comparison


# ── Old approach (before 3.12) ────────────────────────────────────────────
OldVector: TypeAlias = list[float]
OldMatrix: TypeAlias = list[list[float]]
OldJsonValue: TypeAlias = int | float | str | bool | None | list | dict


# ── New 'type' statement (Python 3.12) ────────────────────────────────────
type Vector   = list[float]
type Matrix   = list[list[float]]
type Point2D  = tuple[float, float]
type Point3D  = tuple[float, float, float]


# ── Scalar and primitive aliases ──────────────────────────────────────────
type UserId   = int
type Username = str
type Score    = float
type Url      = str
type Json     = int | float | str | bool | None | list[Json] | dict[str, Json]


# ── Complex nested aliases ────────────────────────────────────────────────
type Headers          = dict[str, str]
type QueryParams      = dict[str, str | list[str]]
type RequestBody      = bytes | str | None
type ResponseBody     = bytes | str | dict | list | None
type Callback[T]      = (T) -> None                  # generic alias (see generic file)
type Predicate[T]     = (T) -> bool
type Transform[T, U]  = (T) -> U


# ── Domain-specific aliases ───────────────────────────────────────────────
type Latitude   = float
type Longitude  = float
type Coordinate = tuple[Latitude, Longitude]
type BoundingBox = tuple[Coordinate, Coordinate]

type RGB   = tuple[int, int, int]
type RGBA  = tuple[int, int, int, int]
type Color = RGB | RGBA


# ── Recursive type alias ──────────────────────────────────────────────────
type Tree[T] = T | list[Tree[T]]                     # recursive with generics


# ── Functions using the new aliases ───────────────────────────────────────
def dot(a: Vector, b: Vector) -> float:
    assert len(a) == len(b), "Vectors must have same length"
    return sum(x * y for x, y in zip(a, b))


def transpose(m: Matrix) -> Matrix:
    if not m:
        return []
    return [[row[i] for row in m] for i in range(len(m[0]))]


def distance(p1: Coordinate, p2: Coordinate) -> float:
    import math
    lat1, lon1 = p1
    lat2, lon2 = p2
    return math.sqrt((lat2 - lat1) ** 2 + (lon2 - lon1) ** 2)


def to_hex(color: Color) -> str:
    if len(color) == 3:
        r, g, b = color
        return f"#{r:02X}{g:02X}{b:02X}"
    r, g, b, a = color
    return f"#{r:02X}{g:02X}{b:02X}{a:02X}"


def flatten_tree(tree: Tree) -> list:
    if not isinstance(tree, list):
        return [tree]
    result = []
    for item in tree:
        result.extend(flatten_tree(item))
    return result


# ── Demo ────────────────────────────────────────────────────────────────
print("=== Type Aliases (type statement) ===")

v1: Vector = [1.0, 2.0, 3.0]
v2: Vector = [4.0, 5.0, 6.0]
print(f"dot([1,2,3], [4,5,6]) = {dot(v1, v2)}")

m: Matrix = [[1, 2, 3], [4, 5, 6]]
print(f"transpose: {transpose(m)}")

nyc: Coordinate = (40.7128, -74.0060)
london: Coordinate = (51.5074, -0.1278)
print(f"distance NYC-London (approx): {distance(nyc, london):.2f} degrees")

orange: RGB = (255, 165, 0)
print(f"Orange hex: {to_hex(orange)}")

semi_transparent: RGBA = (255, 0, 0, 128)
print(f"Semi-red hex: {to_hex(semi_transparent)}")

tree_data: Tree = [1, [2, [3, 4], 5], [6, 7]]
print(f"Flattened tree: {flatten_tree(tree_data)}")

# Inspect the type alias
print(f"\ntype(Vector) = {type(Vector)}")      # <class 'typing.TypeAliasType'>
print(f"Vector.__name__ = {Vector.__name__}")
print(f"Vector.__value__ = {Vector.__value__}")
