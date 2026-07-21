"""
Python 3.9 Feature: Built-in Generic Types (PEP 585)
Use list[], dict[], tuple[], set[], etc. directly in type hints
without importing from typing. Eliminates List, Dict, Tuple, Set imports.
"""
from __future__ import annotations   # for runtime use in 3.9


# ── Before Python 3.9 (typing module required) ────────────────────────────
# from typing import List, Dict, Tuple, Set, FrozenSet, Type, Deque

# ── Python 3.9+: use builtins directly ────────────────────────────────────
# list, dict, tuple, set, frozenset, type, deque, etc.


# ── Function annotations ──────────────────────────────────────────────────
def process_names(names: list[str]) -> list[str]:
    return [n.strip().title() for n in names if n.strip()]


def word_count(text: str) -> dict[str, int]:
    counts: dict[str, int] = {}
    for word in text.lower().split():
        counts[word] = counts.get(word, 0) + 1
    return counts


def top_n(counts: dict[str, int], n: int) -> list[tuple[str, int]]:
    return sorted(counts.items(), key=lambda x: x[1], reverse=True)[:n]


def unique_chars(s: str) -> frozenset[str]:
    return frozenset(s)


# ── Variable annotations ──────────────────────────────────────────────────
scores: list[int] = [85, 92, 78, 96, 88]
index: dict[str, list[int]] = {
    "math":    [90, 85, 92],
    "english": [78, 82, 88],
    "science": [95, 91, 87],
}
matrix: list[list[float]] = [
    [1.0, 0.0, 0.0],
    [0.0, 1.0, 0.0],
    [0.0, 0.0, 1.0],
]


# ── Nested generics ────────────────────────────────────────────────────────
def group_by_first_letter(words: list[str]) -> dict[str, list[str]]:
    groups: dict[str, list[str]] = {}
    for word in words:
        key = word[0].upper()
        groups.setdefault(key, []).append(word)
    return groups


def parse_config(lines: list[str]) -> dict[str, dict[str, str]]:
    config: dict[str, dict[str, str]] = {}
    section: str = "default"
    for line in lines:
        line = line.strip()
        if line.startswith("[") and line.endswith("]"):
            section = line[1:-1]
            config[section] = {}
        elif "=" in line:
            key, _, val = line.partition("=")
            config.setdefault(section, {})[key.strip()] = val.strip()
    return config


# ── Collections module generics ────────────────────────────────────────────
from collections import deque, defaultdict, Counter, OrderedDict

def sliding_window(data: list[int], size: int) -> list[tuple[int, ...]]:
    window: deque[int] = deque(maxlen=size)
    results: list[tuple[int, ...]] = []
    for item in data:
        window.append(item)
        if len(window) == size:
            results.append(tuple(window))
    return results


def frequency_map(items: list[str]) -> defaultdict[str, int]:
    freq: defaultdict[str, int] = defaultdict(int)
    for item in items:
        freq[item] += 1
    return freq


# ── Type aliases using built-in generics ──────────────────────────────────
Matrix = list[list[float]]
Graph  = dict[str, list[str]]
Record = dict[str, str | int | float | bool]    # uses PEP 604 union too

def transpose(m: Matrix) -> Matrix:
    if not m:
        return []
    return [[m[row][col] for row in range(len(m))] for col in range(len(m[0]))]


def bfs(graph: Graph, start: str) -> list[str]:
    visited: set[str] = set()
    queue: deque[str] = deque([start])
    order: list[str] = []
    while queue:
        node = queue.popleft()
        if node not in visited:
            visited.add(node)
            order.append(node)
            queue.extend(graph.get(node, []))
    return order


# ── Demo ───────────────────────────────────────────────────────────────────
print("=== Built-in Generic Types ===")
names = process_names(["  alice ", "BOB", " carol ", ""])
print(f"Names: {names}")

text = "the quick brown fox jumps over the lazy dog the fox"
counts = word_count(text)
print(f"Top 3 words: {top_n(counts, 3)}")

words = ["apple", "banana", "avocado", "blueberry", "cherry", "apricot"]
groups = group_by_first_letter(words)
print(f"Grouped: {groups}")

config_lines = [
    "[database]", "host=localhost", "port=5432",
    "[cache]", "host=redis", "port=6379", "ttl=3600",
]
config = parse_config(config_lines)
print(f"Config: {config}")

data = [1, 2, 3, 4, 5, 6]
windows = sliding_window(data, 3)
print(f"Windows: {windows}")

graph: Graph = {
    "A": ["B", "C"],
    "B": ["D"],
    "C": ["D", "E"],
    "D": [],
    "E": [],
}
print(f"BFS from A: {bfs(graph, 'A')}")

m: Matrix = [[1, 2, 3], [4, 5, 6]]
print(f"Transposed: {transpose(m)}")
