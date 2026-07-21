"""
Python 3.8 Feature: f-string = specifier for self-documenting expressions
f"{expr=}" expands to the expression text + its repr value.
Invaluable for debugging — replaces print("x =", x).
"""
import math
from datetime import date


# ── Basic = specifier ──────────────────────────────────────────────────────
x = 42
y = 3.14
name = "Alice"

print(f"{x=}")          # x=42
print(f"{y=}")          # y=3.14
print(f"{name=}")       # name='Alice'


# ── Works with any expression ─────────────────────────────────────────────
a, b = 10, 3
print(f"{a + b=}")          # a + b=13
print(f"{a * b=}")          # a * b=30
print(f"{a / b=}")          # a / b=3.3333333333333335
print(f"{a ** b=}")         # a ** b=1000
print(f"{a % b=}")          # a % b=1


# ── With format specifiers ─────────────────────────────────────────────────
pi = math.pi
print(f"{pi=:.4f}")         # pi=3.1416
print(f"{pi=:.2e}")         # pi=3.14e+00

value = 255
print(f"{value=:#010b}")    # binary with prefix, width 10
print(f"{value=:#04x}")     # hex with prefix


# ── Preserves whitespace around = ─────────────────────────────────────────
print(f"{x = }")            # x = 42  (spaces preserved)
print(f"{ x = }")           #  x = 42


# ── Method calls and properties ───────────────────────────────────────────
s = "  hello world  "
print(f"{s.strip()=}")
print(f"{s.upper()=}")
print(f"{len(s)=}")
print(f"{s.split()=}")


# ── Collections ───────────────────────────────────────────────────────────
items = [3, 1, 4, 1, 5, 9, 2, 6]
print(f"\n{items=}")
print(f"{sorted(items)=}")
print(f"{len(items)=}")
print(f"{sum(items)=}")
print(f"{max(items)=}")
print(f"{min(items)=}")


# ── Conditionals and boolean ───────────────────────────────────────────────
threshold = 5
print(f"\n{threshold=}")
print(f"{x > threshold=}")
print(f"{x == 42=}")
print(f"{name.startswith('A')=}")


# ── Useful in functions for debugging ────────────────────────────────────
def compute_bmi(weight_kg: float, height_m: float) -> float:
    bmi = weight_kg / height_m ** 2
    # These prints show both the expression and its value
    print(f"  {weight_kg=}, {height_m=}")
    print(f"  {height_m ** 2=:.4f}")
    print(f"  {bmi=:.2f}")
    return bmi

print("\nBMI calculation:")
bmi = compute_bmi(70, 1.75)
category = "Normal" if 18.5 <= bmi <= 24.9 else "Outside normal range"
print(f"  {category=}")


# ── With objects ──────────────────────────────────────────────────────────
today = date(2024, 3, 15)
print(f"\n{today=}")
print(f"{today.year=}")
print(f"{today.month=}")
print(f"{today.isoformat()=}")


# ── Nested expressions ────────────────────────────────────────────────────
numbers = [1, 2, 3, 4, 5]
print(f"\n{[n**2 for n in numbers]=}")
print(f"{sum(n**2 for n in numbers)=}")
print(f"{dict(zip('abc', numbers))=}")


# ── Real debugging scenario ───────────────────────────────────────────────
def process(data: list) -> list:
    result = []
    for i, item in enumerate(data):
        transformed = item * 2 + 1
        if transformed > 5:
            print(f"  DEBUG: {i=}, {item=}, {transformed=}")
            result.append(transformed)
    return result

print("\nProcessing [1,2,3,4,5]:")
output = process([1, 2, 3, 4, 5])
print(f"{output=}")
