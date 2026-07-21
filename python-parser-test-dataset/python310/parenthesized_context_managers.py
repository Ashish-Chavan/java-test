"""
Python 3.10 Feature: Parenthesized Context Managers (PEP 617)
Multiple context managers can now be grouped with parentheses,
enabling multi-line with statements without backslash continuation.
"""
import io
import contextlib
import tempfile
import os
from contextlib import contextmanager, ExitStack
from typing import Generator


# ── Basic: two context managers ──────────────────────────────────────────
input_data  = io.StringIO("Hello from input\nLine two\n")
output_data = io.StringIO()

with (
    input_data as src,
    output_data as dst,
):
    content = src.read()
    dst.write(content.upper())

output_data.seek(0)
print("=== Basic parenthesized with ===")
print(output_data.read())


# ── Three context managers ────────────────────────────────────────────────
@contextmanager
def managed_counter(name: str) -> Generator[list, None, None]:
    items: list = []
    print(f"  [{name}] opening")
    yield items
    print(f"  [{name}] closing with {len(items)} items")


print("=== Three context managers ===")
with (
    managed_counter("A") as list_a,
    managed_counter("B") as list_b,
    managed_counter("C") as list_c,
):
    list_a.extend([1, 2, 3])
    list_b.extend([10, 20])
    list_c.extend([100])
    print(f"  Inside: a={list_a}, b={list_b}, c={list_c}")


# ── Without alias (just for side effects) ────────────────────────────────
@contextmanager
def timer(label: str) -> Generator[None, None, None]:
    import time
    start = time.perf_counter()
    yield
    elapsed = time.perf_counter() - start
    print(f"  {label}: {elapsed*1000:.2f}ms")


@contextmanager
def log_section(name: str) -> Generator[None, None, None]:
    print(f"  >> enter {name}")
    yield
    print(f"  << exit {name}")


print("=== Without alias ===")
with (
    log_section("outer"),
    log_section("inner"),
    timer("both"),
):
    total = sum(i**2 for i in range(10_000))
    print(f"  sum of squares: {total}")


# ── Trailing comma allowed ────────────────────────────────────────────────
buf1 = io.StringIO()
buf2 = io.StringIO()

print("=== Trailing comma ===")
with (
    contextlib.redirect_stdout(buf1),
    contextlib.redirect_stderr(buf2),  # trailing comma OK
):
    print("This goes to buf1")
    import sys
    print("This goes to buf2", file=sys.stderr)

buf1.seek(0)
buf2.seek(0)
print(f"  buf1: {buf1.read().strip()!r}")
print(f"  buf2: {buf2.read().strip()!r}")


# ── Combining file operations ──────────────────────────────────────────────
print("=== File operations ===")
with tempfile.TemporaryDirectory() as tmpdir:
    infile  = os.path.join(tmpdir, "input.txt")
    outfile = os.path.join(tmpdir, "output.txt")

    with open(infile, "w") as f:
        f.write("line one\nline two\nline three\n")

    with (
        open(infile, "r")  as src,
        open(outfile, "w") as dst,
    ):
        for line in src:
            dst.write(line.upper())

    with open(outfile) as f:
        print(f"  Processed output:\n  {f.read().strip()}")


# ── Long context manager expressions ─────────────────────────────────────
class DBConnection:
    def __init__(self, url: str):
        self.url = url

    def __enter__(self):
        print(f"  DB connected: {self.url}")
        return self

    def __exit__(self, *args):
        print(f"  DB disconnected: {self.url}")

    def query(self, sql: str) -> list:
        return [{"id": 1, "name": "test"}]


class Cache:
    def __init__(self, host: str, port: int):
        self.host = host
        self.port = port

    def __enter__(self):
        print(f"  Cache connected: {self.host}:{self.port}")
        return self

    def __exit__(self, *args):
        print(f"  Cache disconnected")

    def get(self, key: str):
        return None


print("=== Database + Cache ===")
with (
    DBConnection("postgresql://localhost/mydb") as db,
    Cache("localhost", 6379) as cache,
):
    cached = cache.get("users")
    if cached is None:
        results = db.query("SELECT * FROM users")
        print(f"  DB results: {results}")
