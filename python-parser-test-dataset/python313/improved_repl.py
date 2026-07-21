"""
Python 3.13 Feature: Improved Interactive Interpreter (REPL) and locals() changes
The new REPL in 3.13 adds:
  - Multiline editing with history
  - Colorized output and tracebacks
  - Paste mode (F3)
  - Block dedenting on double blank line
  - Exit with 'exit' or 'quit' (without parentheses)

locals() changes (PEP 667):
  - In optimized scopes (functions), locals() now returns a fresh
    snapshot each call — mutations are NOT reflected back.
  - Frame.f_locals returns a write-through proxy (for debuggers).
"""
import sys
import inspect
import types
import dis


# ── locals() behavior in Python 3.13 ─────────────────────────────────────
print("=== locals() Semantics (PEP 667) ===")

def demonstrate_locals_snapshot():
    """
    In 3.13, locals() returns a snapshot dict.
    Mutations to the dict do NOT affect actual local variables.
    """
    x = 10
    y = 20

    snapshot = locals()
    print(f"  snapshot = {snapshot}")

    # Mutating the snapshot does NOT change x or y (3.13 clarification)
    snapshot['x'] = 999
    snapshot['z'] = 100

    print(f"  After mutation: x={x}, y={y}")    # unchanged
    print(f"  snapshot now: {snapshot}")

    # A new call to locals() gives another fresh snapshot
    snapshot2 = locals()
    print(f"  New snapshot: {snapshot2}")        # z not in here


demonstrate_locals_snapshot()


# ── Frame locals proxy (for debuggers/tracers) ────────────────────────────
print("\n=== Frame f_locals Proxy ===")

def function_with_frame_access():
    a = 1
    b = 2

    # Get the current frame
    frame = sys._getframe(0)

    # In Python 3.13, frame.f_locals returns a FrameLocalsProxy
    # which is write-through (changes affect actual locals)
    frame_locals = frame.f_locals

    print(f"  Type of frame.f_locals: {type(frame_locals).__name__}")
    print(f"  a={frame_locals.get('a', 'N/A')}, b={frame_locals.get('b', 'N/A')}")

    # In 3.13 with FrameLocalsProxy, this CAN affect local vars
    # (used by debuggers like pdb)
    c = 3
    print(f"  c before refresh: {frame_locals.get('c', 'N/A')}")
    print(f"  c in fresh locals(): {locals().get('c', 'N/A')}")

function_with_frame_access()


# ── Colorized tracebacks (new in 3.13 REPL) ───────────────────────────────
print("\n=== Enhanced Tracebacks ===")

def inner_function(x):
    return 1 / x

def middle_function(value):
    return inner_function(value - value)   # will be zero

def outer_function():
    return middle_function(5)

try:
    outer_function()
except ZeroDivisionError as e:
    # Python 3.13 tracebacks include more context and are colorized in terminal
    print(f"  Caught: {type(e).__name__}: {e}")
    tb = e.__traceback__
    depth = 0
    while tb:
        frame = tb.tb_frame
        print(f"  Frame {depth}: {frame.f_code.co_name} "
              f"line {tb.tb_lineno} in {frame.f_code.co_filename}")
        tb = tb.tb_next
        depth += 1


# ── New REPL features documented as code ─────────────────────────────────
print("\n=== New REPL Features (3.13) ===")

repl_features = {
    "Multiline editing": "Arrow keys move through multiline blocks in history",
    "Colorized output": "Types, values, tracebacks shown with ANSI colors",
    "Paste mode": "F3 toggles paste mode (suppresses auto-indent)",
    "Dedent on blank": "Double blank line exits a block (like IPython)",
    "exit/quit bare": "Can type 'exit' without () to quit",
    "help() improved": "More detailed, better formatted output",
    "sys.last_exc":     "Stores last exception (replaces sys.last_value)",
}

for feature, description in repl_features.items():
    print(f"  {feature:25}: {description}")


# ── sys.last_exc (3.12+, used in REPL) ────────────────────────────────────
print("\n=== sys.last_exc (replaces sys.last_value) ===")

try:
    raise RuntimeError("test exception for sys.last_exc")
except RuntimeError:
    pass

# In interactive mode, sys.last_exc holds the last unhandled exception
if hasattr(sys, "last_exc"):
    print(f"  sys.last_exc available: {type(sys.last_exc).__name__}")
else:
    print("  sys.last_exc not set (only set for unhandled exceptions in REPL)")


# ── Introspection improvements ────────────────────────────────────────────
print("\n=== Introspection ===")

def annotated_function(x: int, y: str = "default") -> bool:
    """A function with annotations."""
    return bool(x)

# Improved in 3.13: __annotations__ evaluation
sig = inspect.signature(annotated_function)
print(f"  Signature: {sig}")
for name, param in sig.parameters.items():
    print(f"    {name}: annotation={param.annotation}, default={param.default}")
