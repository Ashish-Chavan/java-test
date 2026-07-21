"""
Python 3.8 Feature: Positional-Only Parameters (PEP 570)
The / marker in a function signature means all parameters
before it are positional-only (cannot be passed as keyword args).
Works in conjunction with * (keyword-only marker from PEP 3102).
"""
from typing import Optional, Union


# ── Basic positional-only syntax ───────────────────────────────────────────
def greet(name, /, greeting="Hello"):
    """'name' is positional-only; 'greeting' is normal."""
    return f"{greeting}, {name}!"

print(greet("Alice"))                  # OK: positional
print(greet("Bob", "Hi"))              # OK: both positional
print(greet("Carol", greeting="Hey"))  # OK: greeting as keyword

try:
    greet(name="Dave")                 # ERROR: name is positional-only
except TypeError as e:
    print(f"TypeError: {e}")


# ── Positional-only + keyword-only + normal ────────────────────────────────
def mixed(pos_only, /, normal, *, kw_only):
    """
    pos_only: positional-only (before /)
    normal:   can be positional OR keyword (between / and *)
    kw_only:  keyword-only (after *)
    """
    return f"pos={pos_only}, normal={normal}, kw={kw_only}"

print(mixed(1, 2, kw_only=3))          # all positional + kw
print(mixed(1, normal=2, kw_only=3))   # normal as keyword
try:
    mixed(1, 2, 3)                     # ERROR: kw_only needs keyword
except TypeError as e:
    print(f"TypeError: {e}")


# ── Naming freedom: positional-only params can shadow kwargs ───────────────
def create_user(name, age, /, **kwargs):
    """name and age are positional-only — 'name' can appear in kwargs too."""
    user = {"name": name, "age": age}
    user.update(kwargs)
    return user

# 'name' in kwargs doesn't conflict with positional-only 'name'
user = create_user("Alice", 30, name_alias="Al", city="NYC")
print(f"\n{user}")


# ── Mathematical functions benefit from positional-only ────────────────────
def pow(base, /, exponent=2):
    """base is positional-only, matching mathematical convention."""
    return base ** exponent

print(f"\npow(3):       {pow(3)}")
print(f"pow(3, 3):    {pow(3, 3)}")
print(f"pow(2, 10):   {pow(2, 10)}")


# ── Operator-style functions ───────────────────────────────────────────────
def add(x, y, /):
    return x + y

def multiply(x, y, /):
    return x * y

def clamp(value, /, lo, hi):
    """value is positional-only; lo/hi can be named."""
    return max(lo, min(value, hi))

print(f"\nadd(3, 4):                {add(3, 4)}")
print(f"clamp(15, lo=0, hi=10):   {clamp(15, lo=0, hi=10)}")
print(f"clamp(-5, 0, 10):         {clamp(-5, 0, 10)}")


# ── Subclassing: positional-only avoids keyword conflicts ─────────────────
class Shape:
    def __init__(self, color, /, *, filled=False):
        self.color = color
        self.filled = filled

class Circle(Shape):
    def __init__(self, color, /, radius=1.0, *, filled=False):
        super().__init__(color, filled=filled)
        self.radius = radius

    def area(self):
        import math
        return math.pi * self.radius ** 2

    def __repr__(self):
        return f"Circle(color={self.color!r}, radius={self.radius}, filled={self.filled})"

c1 = Circle("red", 5.0, filled=True)
c2 = Circle("blue")
print(f"\n{c1}, area={c1.area():.2f}")
print(f"{c2}, area={c2.area():.2f}")


# ── All three parameter kinds together ────────────────────────────────────
def full_example(
    a, b,           # positional-only
    /,
    c, d="default", # regular (positional or keyword)
    *,
    e, f="kwonly"   # keyword-only
):
    return f"a={a}, b={b}, c={c}, d={d}, e={e}, f={f}"

result = full_example(1, 2, 3, e=5)
print(f"\n{result}")

result2 = full_example(1, 2, c=3, d=4, e=5, f=6)
print(result2)


# ── Practical: wrap C-extension style APIs ────────────────────────────────
def sorted_key(iterable, /, *, key=None, reverse=False):
    """Mirrors the built-in sorted() which has positional-only iterable."""
    return sorted(iterable, key=key, reverse=reverse)

data = [3, 1, 4, 1, 5, 9, 2, 6]
print(f"\nSorted: {sorted_key(data)}")
print(f"Sorted desc: {sorted_key(data, reverse=True)}")
print(f"Sorted by neg: {sorted_key(data, key=lambda x: -x)}")
