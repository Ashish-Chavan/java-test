"""
Python 3.6 Feature: Variable Annotations (PEP 526)
Syntax for annotating variables with type hints, both at module
level, class level, and inside functions. Stored in __annotations__.
"""
from typing import ClassVar, Dict, List, Optional, Tuple


# ── Module-level variable annotations ─────────────────────────────────────
MAX_RETRIES: int = 3
BASE_URL: str = "https://api.example.com"
DEBUG: bool = False
ALLOWED_HOSTS: List[str] = ["localhost", "127.0.0.1"]
CONFIG: Dict[str, str] = {}

# Annotation without assignment (declaration only)
PENDING_COUNT: int  # no value assigned — just declares the type

# ── Class-level annotations ────────────────────────────────────────────────
class Point:
    # Instance variable annotations (no value = just type hint)
    x: float
    y: float
    label: Optional[str]

    # ClassVar: belongs to the class, not instances
    count: ClassVar[int] = 0
    origin: ClassVar["Point"]

    def __init__(self, x: float, y: float, label: Optional[str] = None) -> None:
        self.x = x
        self.y = y
        self.label = label
        Point.count += 1

    def distance_to(self, other: "Point") -> float:
        return ((self.x - other.x) ** 2 + (self.y - other.y) ** 2) ** 0.5


Point.origin = Point(0.0, 0.0, "origin")


class Rectangle:
    top_left: Point
    bottom_right: Point
    fill_color: str = "white"
    border_color: str = "black"
    border_width: float = 1.0

    def __init__(self, top_left: Point, bottom_right: Point) -> None:
        self.top_left = top_left
        self.bottom_right = bottom_right

    @property
    def width(self) -> float:
        return abs(self.bottom_right.x - self.top_left.x)

    @property
    def height(self) -> float:
        return abs(self.bottom_right.y - self.top_left.y)

    @property
    def area(self) -> float:
        return self.width * self.height


# ── Function-level annotations ─────────────────────────────────────────────
def process_items(items: List[str]) -> Dict[str, int]:
    result: Dict[str, int] = {}
    count: int = 0

    for item in items:
        cleaned: str = item.strip().lower()
        if cleaned:
            result[cleaned] = len(cleaned)
            count += 1

    print(f"Processed {count} items")
    return result


def parse_coordinates(raw: str) -> Tuple[float, float]:
    parts: List[str] = raw.split(",")
    x: float = float(parts[0].strip())
    y: float = float(parts[1].strip())
    return x, y


# ── Inspecting __annotations__ ─────────────────────────────────────────────
print("Module annotations:", {
    k: v for k, v in globals().items()
    if not k.startswith("_") and isinstance(v, type)
})

print("Point class annotations:")
for attr, annotation in Point.__annotations__.items():
    print(f"  {attr}: {annotation}")

print("\nRectangle class annotations:")
for attr, annotation in Rectangle.__annotations__.items():
    print(f"  {attr}: {annotation}")


# ── Practical usage ────────────────────────────────────────────────────────
p1 = Point(1.0, 2.0, "A")
p2 = Point(4.0, 6.0, "B")
print(f"\nDistance from {p1.label} to {p2.label}: {p1.distance_to(p2):.4f}")
print(f"Points created: {Point.count}")

rect = Rectangle(Point(0, 10), Point(5, 0))
print(f"Rectangle: {rect.width}x{rect.height}, area={rect.area}")

data = process_items(["  Apple  ", "banana", " Cherry ", "", "apple"])
print(f"Result: {data}")

coords = parse_coordinates("  3.5 ,  -2.1  ")
print(f"Coords: {coords}")


# ── Forward references (string annotations) ────────────────────────────────
class Node:
    value: int
    next_node: Optional["Node"]  # forward reference as string
    children: List["Node"]

    def __init__(self, value: int) -> None:
        self.value = value
        self.next_node = None
        self.children = []


node1 = Node(1)
node2 = Node(2)
node1.next_node = node2
node1.children = [Node(3), Node(4)]
print(f"\nNode: {node1.value} -> {node1.next_node.value}")
print(f"Children: {[c.value for c in node1.children]}")
