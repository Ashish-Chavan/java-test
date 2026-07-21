"""
Python 3.7 Feature: Postponed Evaluation of Annotations (PEP 563)
'from __future__ import annotations' makes ALL annotations strings
at runtime (lazy evaluation). This enables:
  - Forward references without quotes
  - Circular type references
  - Annotations referencing not-yet-defined names
"""
from __future__ import annotations   # ← the key import

from typing import Optional, List, Dict, Union, TYPE_CHECKING

# TYPE_CHECKING is False at runtime, True only for type checkers
# Useful for imports only needed for annotations
if TYPE_CHECKING:
    from collections import OrderedDict


# ── Forward reference WITHOUT quotes (only works with __future__ import) ──
class TreeNode:
    def __init__(self, value: int, left: Optional[TreeNode] = None,
                 right: Optional[TreeNode] = None) -> None:
        self.value = value
        self.left = left      # TreeNode not yet fully defined — but fine!
        self.right = right

    def insert(self, value: int) -> TreeNode:
        if value < self.value:
            if self.left is None:
                self.left = TreeNode(value)
            else:
                self.left.insert(value)
        else:
            if self.right is None:
                self.right = TreeNode(value)
            else:
                self.right.insert(value)
        return self

    def inorder(self) -> List[int]:
        result: List[int] = []
        if self.left:
            result.extend(self.left.inorder())
        result.append(self.value)
        if self.right:
            result.extend(self.right.inorder())
        return result


# ── Mutual recursion between classes ─────────────────────────────────────
class Employee:
    name: str
    manager: Optional[Manager]        # Manager defined BELOW — no quotes needed
    reports: List[Employee]

    def __init__(self, name: str) -> None:
        self.name = name
        self.manager = None
        self.reports = []


class Manager(Employee):
    department: str
    budget: float
    team: List[Employee]

    def __init__(self, name: str, department: str, budget: float) -> None:
        super().__init__(name)
        self.department = department
        self.budget = budget
        self.team = []

    def add_report(self, emp: Employee) -> None:
        emp.manager = self
        self.team.append(emp)
        self.reports.append(emp)

    def org_chart(self, indent: int = 0) -> str:
        lines = [" " * indent + f"[Manager] {self.name} ({self.department})"]
        for report in self.team:
            lines.append(" " * (indent + 2) + f"[Employee] {report.name}")
        return "\n".join(lines)


# ── Recursive type aliases ─────────────────────────────────────────────────
# Without __future__ annotations, this would need quotes around 'JsonValue'
JsonValue = Union[str, int, float, bool, None, List[JsonValue], Dict[str, JsonValue]]

def count_json_nodes(obj: JsonValue) -> int:
    if isinstance(obj, (list,)):
        return 1 + sum(count_json_nodes(item) for item in obj)
    elif isinstance(obj, dict):
        return 1 + sum(count_json_nodes(v) for v in obj.values())
    return 1


# ── Annotations are strings at runtime ────────────────────────────────────
def greet(name: str, times: int = 1) -> str:
    return (f"Hello, {name}! " * times).strip()


# With PEP 563, annotations are NOT evaluated eagerly
print("greet annotations:", greet.__annotations__)  # {'name': 'str', ...} as strings

# get_type_hints() resolves them when needed
import typing
resolved = typing.get_type_hints(greet)
print("resolved hints:", resolved)


# ── Class annotations as strings ───────────────────────────────────────────
print("\nTreeNode annotations:", TreeNode.__annotations__)
# These are strings: {'value': 'int', 'left': 'Optional[TreeNode]', ...}


# ── Demo ───────────────────────────────────────────────────────────────────
root = TreeNode(5)
for v in [3, 7, 1, 4, 6, 8]:
    root.insert(v)
print(f"\nBST inorder: {root.inorder()}")

mgr = Manager("Alice", "Engineering", 500_000)
for emp_name in ["Bob", "Carol", "Dave"]:
    mgr.add_report(Employee(emp_name))
print(f"\nOrg chart:\n{mgr.org_chart()}")

sample_json: JsonValue = {
    "name": "test",
    "scores": [1, 2, 3],
    "meta": {"active": True, "tags": ["a", "b"]}
}
print(f"\nJSON nodes: {count_json_nodes(sample_json)}")
