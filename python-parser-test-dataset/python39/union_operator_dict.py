"""
Python 3.9 Feature: Dictionary Union Operators (PEP 584)
  d1 | d2   → creates new merged dict (d2 wins on conflicts)
  d1 |= d2  → updates d1 in-place with d2
"""


# ── Basic merge with | ─────────────────────────────────────────────────────
defaults = {"timeout": 30, "retries": 3, "debug": False, "host": "localhost"}
overrides = {"timeout": 60, "debug": True, "port": 8080}

# Right side wins on key conflicts
merged = defaults | overrides
print(f"defaults: {defaults}")
print(f"overrides: {overrides}")
print(f"merged:  {merged}")
# timeout=60 (override), retries=3 (default), debug=True (override), port=8080 (new)

# Original dicts are unchanged
print(f"defaults unchanged: {defaults}")


# ── In-place update with |= ────────────────────────────────────────────────
config = {"host": "localhost", "port": 5432, "user": "admin"}
env_vars = {"port": 5433, "password": "secret", "ssl": True}

config |= env_vars
print(f"\nconfig after |=: {config}")


# ── Chained merges ─────────────────────────────────────────────────────────
base     = {"a": 1, "b": 2}
layer1   = {"b": 20, "c": 3}
layer2   = {"c": 30, "d": 4}
layer3   = {"d": 40, "e": 5}

# Later layers win — like CSS cascade or config layering
result = base | layer1 | layer2 | layer3
print(f"\nChained: {result}")   # a=1, b=20, c=30, d=40, e=5


# ── Comparison with old approaches ────────────────────────────────────────
d1 = {"x": 1, "y": 2}
d2 = {"y": 20, "z": 3}

# Old way 1: {**d1, **d2}
old1 = {**d1, **d2}

# Old way 2: d1.copy(); d.update(d2)
old2 = d1.copy()
old2.update(d2)

# New way
new = d1 | d2

assert old1 == old2 == new
print(f"\nAll three methods equal: {new}")


# ── Practical: config layering system ─────────────────────────────────────
class ConfigManager:
    """Layered configuration using dict union operators."""

    def __init__(self):
        self._defaults: dict = {}
        self._file_config: dict = {}
        self._env_config: dict = {}
        self._runtime_config: dict = {}

    def set_defaults(self, **kwargs):
        self._defaults = kwargs

    def load_file(self, config: dict):
        self._file_config = config

    def load_env(self, env: dict):
        self._env_config = env

    def set_runtime(self, **kwargs):
        self._runtime_config = kwargs

    @property
    def effective(self) -> dict:
        # Later layers override earlier — union chaining
        return (
            self._defaults
            | self._file_config
            | self._env_config
            | self._runtime_config
        )


cfg = ConfigManager()
cfg.set_defaults(host="localhost", port=8080, debug=False, log_level="INFO", workers=4)
cfg.load_file({"port": 9000, "log_level": "DEBUG", "db_url": "postgresql://localhost/app"})
cfg.load_env({"debug": True, "secret_key": "env_secret"})
cfg.set_runtime(workers=8)

print(f"\nEffective config: {cfg.effective}")


# ── With non-string keys ───────────────────────────────────────────────────
int_keys1 = {1: "one",   2: "two"}
int_keys2 = {2: "TWO",   3: "three"}
print(f"\nInt keys merged: {int_keys1 | int_keys2}")

tuple_keys1 = {(0, 0): "origin", (1, 0): "right"}
tuple_keys2 = {(0, 1): "up",     (1, 0): "RIGHT"}
print(f"Tuple keys merged: {tuple_keys1 | tuple_keys2}")


# ── |= with other mapping types ────────────────────────────────────────────
from collections import OrderedDict, defaultdict

ordered = OrderedDict([("a", 1), ("b", 2)])
ordered |= {"c": 3, "b": 20}
print(f"\nOrderedDict after |=: {dict(ordered)}")

counter: dict[str, int] = {"apples": 3, "bananas": 5}
new_stock = {"bananas": 2, "cherries": 8}
counter |= new_stock   # bananas overwritten (not added — use Counter for that)
print(f"Counter after |=: {counter}")


# ── Functional pattern: merge many dicts ──────────────────────────────────
from functools import reduce

dicts = [
    {"source": "file"},
    {"version": "1.0"},
    {"author": "Alice"},
    {"license": "MIT"},
]
combined = reduce(lambda a, b: a | b, dicts)
print(f"\nReduced: {combined}")

# Or with walrus
merged_all: dict = {}
for d in dicts:
    merged_all |= d
print(f"In-place: {merged_all}")
