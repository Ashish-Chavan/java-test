"""
Python 3.8 Feature: Assignment Expressions — Walrus Operator := (PEP 572)
Assigns a value to a variable as part of an expression.
Avoids redundant computation and temporary variables.
"""
import re
import math
from typing import List, Optional


# ── Basic walrus usage ─────────────────────────────────────────────────────
data = [1, 2, 3, 4, 5]
if (n := len(data)) > 3:
    print(f"List is long: {n} elements")   # n reused without recalculating


# ── While loop: read-and-test pattern ─────────────────────────────────────
import io
stream = io.StringIO("line one\nline two\nline three\n")

print("Reading lines:")
while chunk := stream.readline():
    print(f"  Got: {chunk.rstrip()}")


# ── Avoiding repeated function calls ──────────────────────────────────────
def expensive_computation(x: int) -> int:
    """Simulate an expensive function."""
    return x * x + 2 * x + 1

values = [1, 5, 3, 8, 2, 9, 4]

# Without walrus: compute twice
filtered_old = [v for v in values if expensive_computation(v) > 20]

# With walrus: compute once, reuse result
filtered_new = [result for v in values if (result := expensive_computation(v)) > 20]
print(f"\nFiltered results: {filtered_new}")


# ── In comprehensions ──────────────────────────────────────────────────────
numbers = range(1, 11)

# Filter AND transform in one pass — compute sqrt only once
sqrt_pairs = [(n, root) for n in numbers if (root := math.sqrt(n)) > 2.5]
print(f"\n(n, sqrt(n)) where sqrt > 2.5:")
for n, root in sqrt_pairs:
    print(f"  n={n}, sqrt={root:.4f}")


# ── Regex: match-and-use pattern ──────────────────────────────────────────
lines = [
    "ERROR 2024-01-15: Disk full",
    "INFO  2024-01-15: Server started",
    "WARN  2024-01-16: Memory low",
    "ERROR 2024-01-16: Connection refused",
    "DEBUG 2024-01-16: Request received",
]

error_pattern = re.compile(r"^ERROR (\d{4}-\d{2}-\d{2}): (.+)")

print("\nErrors found:")
for line in lines:
    if m := error_pattern.match(line):
        print(f"  Date: {m.group(1)}, Msg: {m.group(2)}")


# ── Chained walrus in comprehension ───────────────────────────────────────
raw_data = ["42", "hello", "17", "", "99", "abc", "5"]

parsed = [
    int_val
    for s in raw_data
    if s.strip()
    if (stripped := s.strip()).isdigit()
    if (int_val := int(stripped)) > 10
]
print(f"\nParsed ints > 10: {parsed}")


# ── Sentinel/short-circuit pattern ────────────────────────────────────────
def find_first_match(items: List[str], pattern: str) -> Optional[str]:
    regex = re.compile(pattern)
    return next(
        (match.group() for s in items if (match := regex.search(s))),
        None
    )

words = ["hello", "world", "python38", "walrus", "operator123"]
result = find_first_match(words, r"\d+")
print(f"\nFirst match with digits: {result}")


# ── Nested walrus for pipeline ─────────────────────────────────────────────
def process_pipeline(raw: str) -> Optional[dict]:
    """Multi-stage processing where each step can fail."""
    if not (stripped := raw.strip()):
        return None
    if not (parts := stripped.split(":")) or len(parts) < 2:
        return None
    if not (key := parts[0].strip()):
        return None
    return {"key": key, "value": ":".join(parts[1:]).strip()}


inputs = ["name: Alice", "  age : 30  ", ": no key", "", "city:New York:USA"]
print("\nPipeline results:")
for inp in inputs:
    result = process_pipeline(inp)
    print(f"  {inp!r:25} -> {result}")


# ── In while with complex condition ───────────────────────────────────────
import random
random.seed(42)

total = 0
count = 0
print("\nRolling until sum > 15:")
while (roll := random.randint(1, 6)) and total <= 15:
    total += roll
    count += 1
    print(f"  Roll {count}: {roll} (total={total})")
