"""
Python 3.6 Feature: Asynchronous Generators (PEP 525) and
                    Asynchronous Comprehensions (PEP 530)
async def functions can now contain yield, making them async generators.
async for and async with are supported inside comprehensions.
"""
import asyncio
from typing import AsyncGenerator, AsyncIterator, List


# ── Async generator function ───────────────────────────────────────────────
async def countdown(start: int, step: int = 1) -> AsyncGenerator[int, None]:
    """Async generator that counts down with simulated delay."""
    current = start
    while current >= 0:
        await asyncio.sleep(0)   # yield control to event loop
        yield current
        current -= step


async def read_chunks(data: bytes, chunk_size: int = 4) -> AsyncGenerator[bytes, None]:
    """Simulate async chunked reading."""
    offset = 0
    while offset < len(data):
        await asyncio.sleep(0)
        yield data[offset:offset + chunk_size]
        offset += chunk_size


async def fibonacci() -> AsyncGenerator[int, None]:
    """Infinite async Fibonacci generator."""
    a, b = 0, 1
    while True:
        await asyncio.sleep(0)
        yield a
        a, b = b, a + b


# ── Async generator with async for ────────────────────────────────────────
async def consume_countdown():
    print("Countdown:")
    async for value in countdown(5):
        print(f"  {value}")


async def read_data():
    data = b"Hello, async world!"
    chunks = []
    async for chunk in read_chunks(data, chunk_size=5):
        chunks.append(chunk)
    print(f"Chunks: {[c.decode() for c in chunks]}")


# ── Async generator with return value (StopAsyncIteration) ────────────────
async def limited_range(n: int) -> AsyncGenerator[int, None]:
    for i in range(n):
        await asyncio.sleep(0)
        yield i
    # Implicit StopAsyncIteration at end


# ── Async comprehensions (PEP 530) ────────────────────────────────────────
async def async_comprehensions():
    # Async list comprehension
    squares = [i ** 2 async for i in limited_range(6)]
    print(f"Squares: {squares}")

    # Async list comprehension with filter
    evens = [i async for i in limited_range(10) if i % 2 == 0]
    print(f"Evens: {evens}")

    # Async set comprehension
    unique_mods = {i % 3 async for i in limited_range(9)}
    print(f"Unique mods: {sorted(unique_mods)}")

    # Async dict comprehension
    value_map = {i: i ** 3 async for i in limited_range(5)}
    print(f"Cubes map: {value_map}")

    # Async generator expression
    gen_expr = (i * 10 async for i in limited_range(4))
    results = []
    async for val in gen_expr:
        results.append(val)
    print(f"Generator expr: {results}")


# ── Async context manager with async generator ─────────────────────────────
class AsyncResource:
    """Simulates an async-managed resource."""

    async def __aenter__(self):
        await asyncio.sleep(0)
        print("  Resource acquired")
        return self

    async def __aexit__(self, *args):
        await asyncio.sleep(0)
        print("  Resource released")

    async def fetch(self, key: str) -> str:
        await asyncio.sleep(0)
        return f"value_for_{key}"


async def process_with_resource():
    async with AsyncResource() as res:
        data = await res.fetch("config")
        print(f"  Fetched: {data}")


# ── Combining async generators with aclose() ──────────────────────────────
async def infinite_counter(start: int = 0) -> AsyncGenerator[int, None]:
    try:
        n = start
        while True:
            await asyncio.sleep(0)
            yield n
            n += 1
    finally:
        print("  Counter generator closed cleanly")


async def take_first_n(agen: AsyncGenerator[int, None], n: int) -> List[int]:
    results = []
    async for val in agen:
        results.append(val)
        if len(results) >= n:
            break
    await agen.aclose()  # explicit cleanup
    return results


# ── First N Fibonacci ──────────────────────────────────────────────────────
async def first_n_fibonacci(n: int) -> List[int]:
    result = []
    async for val in fibonacci():
        result.append(val)
        if len(result) >= n:
            break
    return result


# ── Main runner ────────────────────────────────────────────────────────────
async def main():
    print("=== Async Generator: countdown ===")
    await consume_countdown()

    print("\n=== Async Generator: chunked read ===")
    await read_data()

    print("\n=== Async Comprehensions ===")
    await async_comprehensions()

    print("\n=== Async Context Manager ===")
    await process_with_resource()

    print("\n=== Limited async generator ===")
    counter_gen = infinite_counter(100)
    values = await take_first_n(counter_gen, 5)
    print(f"First 5 from 100: {values}")

    print("\n=== First 10 Fibonacci ===")
    fibs = await first_n_fibonacci(10)
    print(f"Fibonacci: {fibs}")


if __name__ == "__main__":
    asyncio.run(main())
