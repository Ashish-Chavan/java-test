"""
Python 3.11 Feature: Exception Notes (PEP 678)
exc.add_note(str) attaches supplementary information to an exception.
Notes appear in the traceback after the main exception message.
Accessible via exc.__notes__ list.
"""
import traceback
import contextlib
import io


# ── Basic add_note() ──────────────────────────────────────────────────────
print("=== Basic add_note ===")

try:
    try:
        raise ValueError("base error")
    except ValueError as e:
        e.add_note("This happened during startup")
        e.add_note("Check the configuration file")
        raise
except ValueError as e:
    print(f"Exception: {e}")
    print(f"Notes: {e.__notes__}")
    # traceback would show the notes after the exception message


# ── Multiple notes at different call stack levels ─────────────────────────
print("\n=== Notes added at multiple levels ===")

def level3():
    raise KeyError("missing_key")

def level2():
    try:
        level3()
    except KeyError as e:
        e.add_note("Note from level2: key should be set in environment")
        raise

def level1():
    try:
        level2()
    except KeyError as e:
        e.add_note("Note from level1: this is a configuration error")
        raise

try:
    level1()
except KeyError as e:
    print(f"Exception: {e}")
    print(f"All notes:")
    for note in e.__notes__:
        print(f"  - {note}")


# ── Notes with context information ────────────────────────────────────────
print("\n=== Contextual notes ===")

def parse_csv_row(row: str, line_number: int) -> list:
    try:
        values = row.split(",")
        return [int(v.strip()) for v in values]
    except ValueError as e:
        e.add_note(f"Failed parsing line {line_number}: {row!r}")
        e.add_note(f"Expected: comma-separated integers")
        raise

def process_file(lines: list[str]) -> list[list]:
    results = []
    errors = []
    for i, line in enumerate(lines, start=1):
        try:
            results.append(parse_csv_row(line, i))
        except ValueError as e:
            errors.append(e)
    if errors:
        raise ExceptionGroup("CSV parsing errors", errors)
    return results

try:
    process_file(["1,2,3", "4,x,6", "7,8,9", "a,b,c"])
except* ValueError as eg:
    for exc in eg.exceptions:
        print(f"ValueError: {exc}")
        for note in getattr(exc, "__notes__", []):
            print(f"  note: {note}")


# ── Notes in validation ────────────────────────────────────────────────────
print("\n=== Validation with notes ===")

class ValidationError(ValueError):
    pass

def validate_user(data: dict) -> None:
    errors = []

    if not data.get("name"):
        err = ValidationError("name is required")
        err.add_note("'name' field must be a non-empty string")
        err.add_note("Example: {'name': 'Alice'}")
        errors.append(err)

    age = data.get("age")
    if not isinstance(age, int):
        err = ValidationError(f"age must be int, got {type(age).__name__}")
        err.add_note(f"Received value: {age!r}")
        errors.append(err)
    elif age < 0 or age > 150:
        err = ValidationError(f"age {age} out of range [0, 150]")
        err.add_note(f"Received: {age}")
        errors.append(err)

    if errors:
        raise ExceptionGroup("validation failed", errors)

try:
    validate_user({"age": "thirty"})
except* ValidationError as eg:
    for exc in eg.exceptions:
        buf = io.StringIO()
        traceback.print_exception(type(exc), exc, exc.__traceback__, file=buf)
        print(f"Error: {exc}")
        for note in getattr(exc, "__notes__", []):
            print(f"  📝 {note}")


# ── Notes preserve across re-raise ────────────────────────────────────────
print("\n=== Notes survive re-raise ===")

try:
    try:
        try:
            raise RuntimeError("original")
        except RuntimeError as e:
            e.add_note("added at innermost")
            raise
    except RuntimeError as e:
        e.add_note("added at middle")
        raise
except RuntimeError as e:
    e.add_note("added at outermost")
    print(f"Exception: {e}")
    print(f"Notes count: {len(e.__notes__)}")
    for note in e.__notes__:
        print(f"  {note}")
