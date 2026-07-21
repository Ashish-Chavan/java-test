"""
Python 3.11 Feature: Exception Groups and except* (PEP 654)
ExceptionGroup wraps multiple exceptions that can be raised together.
except* catches specific exception types from a group.
Essential for concurrent code where multiple tasks can fail simultaneously.
"""
import asyncio
from typing import Any


# ── Basic ExceptionGroup ──────────────────────────────────────────────────
print("=== Basic ExceptionGroup ===")

def raise_multiple():
    raise ExceptionGroup("multiple failures", [
        ValueError("bad value"),
        TypeError("wrong type"),
        KeyError("missing key"),
    ])

try:
    raise_multiple()
except* ValueError as eg:
    print(f"Caught ValueErrors: {[str(e) for e in eg.exceptions]}")
except* TypeError as eg:
    print(f"Caught TypeErrors: {[str(e) for e in eg.exceptions]}")
except* KeyError as eg:
    print(f"Caught KeyErrors: {[str(e) for e in eg.exceptions]}")


# ── except* catches matching types, re-raises rest ────────────────────────
print("\n=== Partial catch ===")

try:
    raise ExceptionGroup("mixed", [
        ValueError("v1"),
        ValueError("v2"),
        RuntimeError("rt1"),
        PermissionError("pe1"),
    ])
except* ValueError as eg:
    print(f"Handled ValueErrors: {len(eg.exceptions)}")
    # RuntimeError and PermissionError are re-raised automatically
except* PermissionError as eg:
    print(f"Handled PermissionErrors: {len(eg.exceptions)}")
# RuntimeError propagates — catch it:
except* RuntimeError as eg:
    print(f"Handled RuntimeErrors: {len(eg.exceptions)}")


# ── Nested ExceptionGroups ────────────────────────────────────────────────
print("\n=== Nested ExceptionGroups ===")

nested = ExceptionGroup("outer", [
    ValueError("v1"),
    ExceptionGroup("inner", [
        TypeError("t1"),
        TypeError("t2"),
    ]),
    RuntimeError("r1"),
])

try:
    raise nested
except* TypeError as eg:
    # except* flattens nested groups for matching type
    print(f"TypeErrors (from nested): {[str(e) for e in eg.exceptions]}")
except* (ValueError, RuntimeError) as eg:
    print(f"Value/Runtime errors: {[str(e) for e in eg.exceptions]}")


# ── ExceptionGroup in async concurrent tasks ──────────────────────────────
print("\n=== Async TaskGroup (Python 3.11) ===")

async def task_ok(name: str, delay: float) -> str:
    await asyncio.sleep(delay)
    return f"{name} completed"

async def task_fail(name: str, delay: float, exc: Exception) -> str:
    await asyncio.sleep(delay)
    raise exc

async def run_tasks():
    results = []

    try:
        async with asyncio.TaskGroup() as tg:
            t1 = tg.create_task(task_ok("task1", 0.01))
            t2 = tg.create_task(task_fail("task2", 0.01, ValueError("task2 failed")))
            t3 = tg.create_task(task_ok("task3", 0.01))
            t4 = tg.create_task(task_fail("task4", 0.02, TypeError("task4 failed")))

    except* ValueError as eg:
        print(f"  ValueError group: {[str(e) for e in eg.exceptions]}")
    except* TypeError as eg:
        print(f"  TypeError group: {[str(e) for e in eg.exceptions]}")

    # Successful tasks still have results
    print(f"  t1 result: {t1.result()}")
    print(f"  t3 result: {t3.result()}")

asyncio.run(run_tasks())


# ── Building ExceptionGroups manually ────────────────────────────────────
print("\n=== Collecting and raising ===")

def validate_all(data: dict) -> None:
    errors = []

    if not isinstance(data.get("name"), str):
        errors.append(TypeError("'name' must be a string"))
    elif len(data["name"]) < 2:
        errors.append(ValueError("'name' too short"))

    if not isinstance(data.get("age"), int):
        errors.append(TypeError("'age' must be an int"))
    elif data["age"] < 0:
        errors.append(ValueError("'age' must be non-negative"))

    if "email" not in data:
        errors.append(KeyError("'email' is required"))

    if errors:
        raise ExceptionGroup("validation failed", errors)


try:
    validate_all({"name": "A", "age": -5})
except* TypeError as eg:
    print(f"Type errors: {[str(e) for e in eg.exceptions]}")
except* ValueError as eg:
    print(f"Value errors: {[str(e) for e in eg.exceptions]}")
except* KeyError as eg:
    print(f"Key errors: {[str(e) for e in eg.exceptions]}")


# ── ExceptionGroup properties ──────────────────────────────────────────────
print("\n=== ExceptionGroup properties ===")
eg = ExceptionGroup("demo", [ValueError("a"), ValueError("b"), TypeError("c")])
print(f"message:    {eg.message}")
print(f"exceptions: {eg.exceptions}")
print(f"subgroup ValueError: {eg.subgroup(ValueError)}")
print(f"split: {eg.split(ValueError)}")
