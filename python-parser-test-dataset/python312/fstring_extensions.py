"""
Python 3.12 Feature: f-string Extensions (PEP 701)
f-strings can now:
  1. Reuse the same quote character inside {} expressions
  2. Span multiple lines (backslash line continuation in {})
  3. Contain comments inside {} expressions
  4. Nest arbitrarily deep
"""


# ── 1. Reuse same quote character inside expressions ──────────────────────
print("=== Reuse Same Quote Character ===")

# Before 3.12: had to switch quote style
name = "Alice"
data = {"key": "value", "name": "Bob"}

# Old approach: use different quote type inside
old = f"{'hello'.upper()}"
old2 = f"{data['key']}"          # works but mixed quotes

# Python 3.12: use the SAME quote type freely
new = f"{'hello'.upper()}"       # same quotes now unambiguous
new2 = f"{data["key"]}"          # double quotes inside double-quoted f-string!
new3 = f"name is {'Alice'!r}"    # string literal with same quotes
new4 = f"{'yes' if True else 'no'}"

print(old, "==", new)
print(f"{data['name']} == {data["name"]}")    # both work in 3.12
print(new3)
print(new4)


# ── 2. Multi-line expressions inside {} ───────────────────────────────────
print("\n=== Multi-line Expressions ===")

items = ["apple", "banana", "cherry", "date", "elderberry"]
scores = {"alice": 95, "bob": 87, "carol": 92}

# Multi-line comprehension inside f-string
result = f"""Items: {
    ', '.join(
        item.upper()
        for item in items
        if len(item) > 5
    )
}"""
print(result)

# Multi-line dict/condition
summary = f"Top scorer: {
    max(
        scores.items(),
        key=lambda kv: kv[1]
    )[0].title()
}"
print(summary)


# ── 3. Comments inside {} expressions ─────────────────────────────────────
print("\n=== Comments in Expressions ===")

values = [1, 2, 3, 4, 5]
total = f"Total: {
    sum(
        v * 2            # double each value
        for v in values  # iterate over all values
        if v % 2 == 0    # only even values
    )
}"
print(total)


# ── 4. Deeply nested f-strings ────────────────────────────────────────────
print("\n=== Nested f-strings ===")

x = 42
# Multiple levels of nesting
nested1 = f"outer {f'middle {f"inner {x}"}'}"
print(nested1)

# Practical nested example: building formatted table
headers = ["Name", "Score", "Grade"]
rows = [
    ("Alice", 95, "A"),
    ("Bob",   82, "B"),
    ("Carol", 71, "C"),
]

table = f"""
{" | ".join(f"{h:^10}" for h in headers)}
{"-+-".join("-" * 10 for _ in headers)}
{chr(10).join(
    f"{name:^10} | {score:^10} | {grade:^10}"
    for name, score, grade in rows
)}"""
print(table)


# ── 5. f-strings with backslash escapes ──────────────────────────────────
print("\n=== Backslash in f-string expressions ===")

lines = ["hello", "world", "python"]

# In Python 3.12, backslash allowed inside {}
joined = f"Lines:\n{chr(10).join(f'  {i+1}. {line}' for i, line in enumerate(lines))}"
print(joined)


# ── 6. Complex practical example ──────────────────────────────────────────
print("\n=== Practical: JSON builder ===")

config = {
    "app": "MyApp",
    "version": "1.0",
    "features": ["auth", "api", "cache"],
    "limits": {"rate": 100, "burst": 200},
}

# Building JSON-like output with same-quote f-strings
json_output = f"""{{
  "app": "{config["app"]}",
  "version": "{config["version"]}",
  "feature_count": {len(config["features"])},
  "features": [{", ".join(f'"{f}"' for f in config["features"])}],
  "rate_limit": {config["limits"]["rate"]}
}}"""
print(json_output)
