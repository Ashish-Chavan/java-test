"""
Python 3.13 Feature: Free-Threaded Mode — Experimental (PEP 703)
Python 3.13 ships an optional build without the GIL (--disable-gil).
Standard threading code looks the same — but threads can now run
truly in parallel on multiple CPU cores.

This file demonstrates:
  - Detecting free-threaded mode
  - Thread-safe patterns (needed now that threads truly run in parallel)
  - Comparing GIL vs no-GIL expected behavior
  - Atomic operations and thread-safe data structures
"""
import sys
import threading
import time
from threading import Thread, Lock, RLock, Semaphore, Event, Barrier
from collections import deque
from typing import Any


# ── Detect free-threaded build ────────────────────────────────────────────
def is_free_threaded() -> bool:
    """Check if running on a GIL-disabled Python build."""
    return not sys._is_gil_enabled() if hasattr(sys, "_is_gil_enabled") else False


print(f"=== Thread Safety & Free-Threaded Mode ===")
print(f"Python version: {sys.version}")
print(f"Free-threaded:  {is_free_threaded()}")
print(f"GIL enabled:    {sys._is_gil_enabled() if hasattr(sys, '_is_gil_enabled') else 'unknown'}")


# ── Thread-safe counter (needed in free-threaded mode) ────────────────────
class ThreadSafeCounter:
    """Counter safe for parallel thread access."""

    def __init__(self, initial: int = 0):
        self._value = initial
        self._lock = Lock()

    def increment(self, amount: int = 1) -> int:
        with self._lock:
            self._value += amount
            return self._value

    def decrement(self, amount: int = 1) -> int:
        with self._lock:
            self._value -= amount
            return self._value

    @property
    def value(self) -> int:
        with self._lock:
            return self._value


def race_condition_demo():
    """Shows why locks are needed in free-threaded mode."""
    ITERATIONS = 10_000

    # Unsafe counter — would be fine with GIL, unreliable without
    unsafe_count = [0]

    def increment_unsafe():
        for _ in range(ITERATIONS):
            unsafe_count[0] += 1  # read-modify-write is not atomic!

    # Safe counter — correct with or without GIL
    safe_counter = ThreadSafeCounter()

    def increment_safe():
        for _ in range(ITERATIONS):
            safe_counter.increment()

    threads = [Thread(target=increment_safe) for _ in range(4)]
    for t in threads: t.start()
    for t in threads: t.join()

    expected = 4 * ITERATIONS
    print(f"\nExpected:    {expected}")
    print(f"Safe result: {safe_counter.value} (always correct)")


race_condition_demo()


# ── Thread-safe queue ─────────────────────────────────────────────────────
import queue

class WorkQueue:
    """Producer-consumer queue safe in free-threaded mode."""

    def __init__(self, maxsize: int = 0):
        self._q: queue.Queue = queue.Queue(maxsize=maxsize)
        self._done = Event()

    def put(self, item: Any) -> None:
        self._q.put(item)

    def get(self, timeout: float = 1.0) -> Any:
        return self._q.get(timeout=timeout)

    def task_done(self) -> None:
        self._q.task_done()

    def join(self) -> None:
        self._q.join()

    def stop(self) -> None:
        self._done.set()


def producer_consumer_demo():
    print("\n=== Producer-Consumer ===")
    work_q: queue.Queue = queue.Queue()
    results: list[int] = []
    results_lock = Lock()

    def producer(n: int):
        for i in range(n):
            work_q.put(i * i)
        work_q.put(None)  # sentinel

    def consumer():
        while True:
            item = work_q.get()
            if item is None:
                work_q.put(None)  # pass sentinel to other consumers
                break
            with results_lock:
                results.append(item)
            work_q.task_done()

    t_prod = Thread(target=producer, args=(10,))
    t_cons = [Thread(target=consumer) for _ in range(2)]

    t_prod.start()
    for t in t_cons: t.start()

    t_prod.join()
    for t in t_cons: t.join()

    print(f"Results (sorted): {sorted(results)}")

producer_consumer_demo()


# ── Barrier synchronization ───────────────────────────────────────────────
def barrier_demo():
    print("\n=== Barrier Synchronization ===")
    NUM_THREADS = 3
    barrier = Barrier(NUM_THREADS)
    log_lock = Lock()

    def phase_worker(thread_id: int):
        with log_lock: print(f"  Thread {thread_id}: Phase 1 done")
        barrier.wait()   # all threads meet here
        with log_lock: print(f"  Thread {thread_id}: Phase 2 done")
        barrier.wait()
        with log_lock: print(f"  Thread {thread_id}: Phase 3 done")

    threads = [Thread(target=phase_worker, args=(i,)) for i in range(NUM_THREADS)]
    for t in threads: t.start()
    for t in threads: t.join()

barrier_demo()


# ── sys.monitoring — new in 3.12/3.13 ────────────────────────────────────
print("\n=== sys.monitoring (3.12+) ===")
if hasattr(sys, "monitoring"):
    print("sys.monitoring available")
    print(f"  tool IDs: DEBUGGER={sys.monitoring.DEBUGGER_ID}")
else:
    print("sys.monitoring not available in this build")
