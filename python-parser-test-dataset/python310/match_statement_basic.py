"""
Python 3.10 Feature: Structural Pattern Matching — Basic (PEP 634)
match/case statement supporting:
  - Literal patterns
  - Capture patterns (binding variables)
  - Sequence patterns
  - Mapping patterns
  - Wildcard pattern (_)
"""
from __future__ import annotations


# ── Literal patterns ───────────────────────────────────────────────────────
def http_status(code: int) -> str:
    match code:
        case 200: return "OK"
        case 201: return "Created"
        case 204: return "No Content"
        case 301: return "Moved Permanently"
        case 302: return "Found"
        case 400: return "Bad Request"
        case 401: return "Unauthorized"
        case 403: return "Forbidden"
        case 404: return "Not Found"
        case 500: return "Internal Server Error"
        case 503: return "Service Unavailable"
        case _:   return f"Unknown ({code})"

for code in [200, 404, 500, 999]:
    print(f"HTTP {code}: {http_status(code)}")


# ── Capture patterns (binding variables) ──────────────────────────────────
def describe_number(n: int) -> str:
    match n:
        case 0:
            return "zero"
        case 1 | 2 | 3:
            return f"small positive: {n}"
        case x if x < 0:
            return f"negative: {x}"
        case x if x > 1000:
            return f"large: {x}"
        case x:
            return f"other: {x}"

for n in [0, 2, -5, 50, 9999]:
    print(f"  {n} -> {describe_number(n)}")


# ── Sequence patterns ──────────────────────────────────────────────────────
def process_command(command: list) -> str:
    match command:
        case []:
            return "Empty command"
        case ["quit"] | ["exit"] | ["q"]:
            return "Quitting..."
        case ["help"]:
            return "Available commands: quit, help, go, look, get"
        case ["go", direction]:
            return f"Going {direction}"
        case ["go", direction, speed]:
            return f"Going {direction} at {speed}"
        case ["get", item]:
            return f"Getting {item}"
        case ["get", item, "from", container]:
            return f"Getting {item} from {container}"
        case [first, *rest]:
            return f"Unknown command: {first!r}, args: {rest}"

commands = [
    [],
    ["quit"],
    ["help"],
    ["go", "north"],
    ["go", "south", "fast"],
    ["get", "sword"],
    ["get", "key", "from", "chest"],
    ["unknown", "arg1", "arg2"],
]
print()
for cmd in commands:
    print(f"  {cmd} -> {process_command(cmd)}")


# ── Mapping patterns ───────────────────────────────────────────────────────
def handle_event(event: dict) -> str:
    match event:
        case {"type": "click", "x": x, "y": y}:
            return f"Click at ({x}, {y})"
        case {"type": "keydown", "key": "Enter"}:
            return "Enter pressed"
        case {"type": "keydown", "key": key}:
            return f"Key pressed: {key!r}"
        case {"type": "scroll", "delta": delta} if delta > 0:
            return f"Scroll up: {delta}"
        case {"type": "scroll", "delta": delta}:
            return f"Scroll down: {abs(delta)}"
        case {"type": type_, **rest}:
            return f"Event type={type_!r}, extra={rest}"
        case _:
            return "Unknown event"

events = [
    {"type": "click", "x": 100, "y": 200},
    {"type": "keydown", "key": "Enter"},
    {"type": "keydown", "key": "Escape"},
    {"type": "scroll", "delta": 3},
    {"type": "scroll", "delta": -5},
    {"type": "resize", "width": 800, "height": 600},
    {"type": "unknown"},
    {},
]
print()
for ev in events:
    print(f"  {ev} -> {handle_event(ev)}")


# ── OR patterns ────────────────────────────────────────────────────────────
def classify_day(day: str) -> str:
    match day.lower():
        case "monday" | "tuesday" | "wednesday" | "thursday" | "friday":
            return "weekday"
        case "saturday" | "sunday":
            return "weekend"
        case _:
            return "unknown"

for day in ["Monday", "Saturday", "holiday"]:
    print(f"  {day} -> {classify_day(day)}")


# ── match on None, True, False ────────────────────────────────────────────
def handle_value(val) -> str:
    match val:
        case None:    return "nothing"
        case True:    return "yes"
        case False:   return "no"
        case int(n):  return f"integer: {n}"
        case str(s):  return f"string: {s!r}"
        case _:       return f"other: {val!r}"

for v in [None, True, False, 42, "hello", 3.14]:
    print(f"  {v!r} -> {handle_value(v)}")
