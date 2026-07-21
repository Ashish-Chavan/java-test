"""
Python 3.7 Feature: breakpoint() builtin (PEP 553) and
                    contextvars module (PEP 567)
breakpoint() is a built-in that calls sys.breakpointhook()
contextvars provides Context, ContextVar, and Token for
managing context-local state in async/concurrent code.
"""
import asyncio
import contextvars
import sys
from typing import Any, Optional


# ── breakpoint() builtin ──────────────────────────────────────────────────
# breakpoint() replaces: import pdb; pdb.set_trace()
# Controlled by PYTHONBREAKPOINT env var:
#   PYTHONBREAKPOINT=0            → disables all breakpoints
#   PYTHONBREAKPOINT=ipdb.set_trace → uses ipdb instead
#   PYTHONBREAKPOINT=             → uses default pdb

def controlled_breakpoint_demo():
    """Shows the breakpoint hook mechanism without actually pausing."""
    original_hook = sys.breakpointhook

    call_log = []

    def mock_debugger(*args, **kwargs):
        call_log.append(("breakpoint called", args, kwargs))

    sys.breakpointhook = mock_debugger

    x = 42
    y = "hello"
    breakpoint()   # calls mock_debugger instead of pdb

    sys.breakpointhook = original_hook

    print(f"Breakpoint was intercepted: {call_log[0][0]}")
    print("(In real usage: breakpoint() drops into pdb or configured debugger)")


controlled_breakpoint_demo()


# ── contextvars: ContextVar ────────────────────────────────────────────────
# Context variables hold values that are local to an execution context.
# Unlike threading.local(), they work correctly with async/await.

# Define context variables at module level
current_user: contextvars.ContextVar[str] = contextvars.ContextVar(
    "current_user", default="anonymous"
)
request_id: contextvars.ContextVar[str] = contextvars.ContextVar(
    "request_id", default=""
)
log_level: contextvars.ContextVar[str] = contextvars.ContextVar(
    "log_level", default="INFO"
)


def get_logger_prefix() -> str:
    user = current_user.get()
    req  = request_id.get()
    level = log_level.get()
    return f"[{level}] user={user} req={req}"


def log(message: str) -> None:
    print(f"{get_logger_prefix()} | {message}")


# ── Token: resetting context variables ────────────────────────────────────
def process_request(user: str, req_id: str) -> None:
    """Simulate request processing with context vars."""
    # set() returns a Token for later reset
    user_token = current_user.set(user)
    req_token  = request_id.set(req_id)

    try:
        log("Request started")
        do_database_work()
        log("Request completed")
    finally:
        # Reset to previous values using tokens
        current_user.reset(user_token)
        request_id.reset(req_token)


def do_database_work() -> None:
    log("Querying database")
    log("Processing rows")


print("\n=== Context Variables Demo ===")
log("Server starting")

process_request("alice", "req-001")
process_request("bob", "req-002")

log("Both requests done")
print(f"current_user after requests: {current_user.get()}")   # back to 'anonymous'


# ── contextvars with asyncio ───────────────────────────────────────────────
async def handle_request(user: str, req_id: str, delay: float) -> dict:
    """Each coroutine has its own context snapshot."""
    current_user.set(user)
    request_id.set(req_id)

    log(f"Async handler started (delay={delay}s)")
    await asyncio.sleep(delay)

    # Context is preserved across await points within same task
    log(f"Async handler resumed")
    return {"user": current_user.get(), "req_id": request_id.get()}


async def async_demo():
    print("\n=== Async Context Variables ===")

    # Run concurrently — each task has its OWN context copy
    results = await asyncio.gather(
        handle_request("user_A", "async-001", 0.02),
        handle_request("user_B", "async-002", 0.01),
        handle_request("user_C", "async-003", 0.03),
    )

    for r in results:
        print(f"  Result: {r}")

    # Top-level context unchanged
    print(f"  Top-level user: {current_user.get()}")   # still 'anonymous'


asyncio.run(async_demo())


# ── contextvars.copy_context() ─────────────────────────────────────────────
print("\n=== Context Copying ===")

current_user.set("parent")
ctx: contextvars.Context = contextvars.copy_context()

def run_in_context():
    print(f"  In copied context: {current_user.get()}")   # sees 'parent'
    current_user.set("child")
    print(f"  After set in copy: {current_user.get()}")   # 'child'

ctx.run(run_in_context)
print(f"  Parent after copy.run: {current_user.get()}")   # still 'parent'
