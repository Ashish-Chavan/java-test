"""
Python 3.6 Feature: f-string literals (PEP 498)
Formatted string literals — embed expressions directly inside string
literals using a minimal syntax. Faster than .format() and % formatting.
"""
import math
from datetime import datetime


# ── Basic f-string ─────────────────────────────────────────────────────────
name = "Alice"
age = 30
print(f"Hello, {name}! You are {age} years old.")

# ── Expressions inside f-strings ───────────────────────────────────────────
a, b = 7, 3
print(f"{a} + {b} = {a + b}")
print(f"{a} * {b} = {a * b}")
print(f"Max: {max(a, b)}, Min: {min(a, b)}")

# ── Method calls ───────────────────────────────────────────────────────────
greeting = "hello world"
print(f"Title: {greeting.title()}")
print(f"Upper: {greeting.upper()}")
print(f"Words: {len(greeting.split())}")

# ── Format specifiers ──────────────────────────────────────────────────────
pi = math.pi
print(f"Pi (2dp):   {pi:.2f}")
print(f"Pi (10dp):  {pi:.10f}")
print(f"Pi (sci):   {pi:.3e}")
print(f"Percentage: {0.856:.1%}")

# ── Width and alignment ────────────────────────────────────────────────────
for fruit, qty in [("apple", 5), ("banana", 12), ("cherry", 3)]:
    print(f"{fruit:<12} qty={qty:>4}")

# ── Nested braces (literal brace) ─────────────────────────────────────────
print(f"Set literal: {{1, 2, 3}}")
print(f"Dict: {{'key': 'value'}}")

# ── Multiline f-strings ────────────────────────────────────────────────────
person = {"name": "Bob", "city": "London", "score": 87.5}
report = (
    f"Name:  {person['name']}\n"
    f"City:  {person['city']}\n"
    f"Score: {person['score']:.1f}\n"
)
print(report)

# ── Conditional expressions ────────────────────────────────────────────────
score = 72
grade = f"{'Pass' if score >= 50 else 'Fail'} ({score}/100)"
print(grade)

# ── Date formatting ────────────────────────────────────────────────────────
now = datetime(2024, 3, 15, 14, 30, 0)
print(f"Date: {now:%Y-%m-%d}")
print(f"Time: {now:%H:%M:%S}")
print(f"Full: {now:%A, %B %d %Y at %I:%M %p}")

# ── Nested f-strings ───────────────────────────────────────────────────────
width = 10
value = 42
print(f"{'Padded':>{width}}")
print(f"{value:{width}.2f}")

# ── f-string with dictionary ───────────────────────────────────────────────
config = {"host": "localhost", "port": 5432, "db": "myapp"}
dsn = f"postgresql://{config['host']}:{config['port']}/{config['db']}"
print(f"DSN: {dsn}")

# ── f-string in function ───────────────────────────────────────────────────
def describe_point(x: float, y: float) -> str:
    distance = math.sqrt(x**2 + y**2)
    return f"Point({x}, {y}) — distance from origin: {distance:.4f}"

print(describe_point(3, 4))
print(describe_point(-1.5, 2.7))

# ── Repr vs str in f-strings ───────────────────────────────────────────────
class Color:
    def __init__(self, r, g, b):
        self.r, self.g, self.b = r, g, b
    def __str__(self):
        return f"rgb({self.r}, {self.g}, {self.b})"
    def __repr__(self):
        return f"Color(r={self.r}, g={self.g}, b={self.b})"

red = Color(255, 0, 0)
print(f"str:  {red}")
print(f"repr: {red!r}")
print(f"ascii: {red!a}")
