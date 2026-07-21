/**
 * Java 21 Feature: Record Patterns - Finalized (JEP 440)
 * Deconstruct record values in pattern matching, binding their
 * components directly. Supports nesting for deep destructuring.
 */
import java.util.List;

public class RecordPatterns {

    // Domain model
    record Point(int x, int y) {}
    record Line(Point start, Point end) {}
    record Color(int r, int g, int b) {}
    record ColoredPoint(Point point, Color color) {}

    sealed interface Shape permits Circ, Rect, Group {}
    record Circ(Point center, double radius)           implements Shape {}
    record Rect(Point topLeft, Point bottomRight)      implements Shape {}
    record Group(List<Shape> shapes)                   implements Shape {}

    sealed interface Tree<T> permits Tree.Leaf, Tree.Branch {}

    record Tree<T>() {
        record Leaf<T>(T value)                                    implements Tree<T> {}
        record Branch<T>(Tree<T> left, T value, Tree<T> right)    implements Tree<T> {}
    }

    public static void main(String[] args) {

        // ── Basic record pattern deconstruction ────────────────────────────
        Object obj = new Point(3, 4);

        // Old way (Java 16 pattern instanceof)
        if (obj instanceof Point p) {
            System.out.println("Old way: x=" + p.x() + ", y=" + p.y());
        }

        // New way (Java 21 record pattern - destructure directly)
        if (obj instanceof Point(int x, int y)) {
            System.out.println("Record pattern: x=" + x + ", y=" + y);
        }

        // ── Nested record patterns ─────────────────────────────────────────
        Object line = new Line(new Point(0, 0), new Point(10, 10));

        // Deep destructuring in one pattern
        if (line instanceof Line(Point(int x1, int y1), Point(int x2, int y2))) {
            System.out.printf("Line from (%d,%d) to (%d,%d)%n", x1, y1, x2, y2);
            double length = Math.sqrt(Math.pow(x2 - x1, 2) + Math.pow(y2 - y1, 2));
            System.out.printf("Length: %.2f%n", length);
        }

        // ── Record patterns in switch ──────────────────────────────────────
        Shape[] shapes = {
            new Circ(new Point(0, 0), 5.0),
            new Rect(new Point(1, 1), new Point(5, 4)),
            new Group(List.of(
                new Circ(new Point(2, 2), 1.0),
                new Rect(new Point(0, 0), new Point(3, 3))
            ))
        };

        for (Shape s : shapes) {
            System.out.println(describeShape(s));
        }

        // ── Colored point with nested pattern ─────────────────────────────
        Object cp = new ColoredPoint(new Point(5, 10), new Color(255, 0, 128));
        if (cp instanceof ColoredPoint(Point(int px, int py), Color(int r, int g, int b))) {
            System.out.printf("ColoredPoint at (%d,%d) color=rgb(%d,%d,%d)%n",
                px, py, r, g, b);
        }

        // ── Record pattern with guard (when) ──────────────────────────────
        List<Object> items = List.of(
            new Point(0, 0),
            new Point(3, 4),
            new Point(-1, 5),
            new ColoredPoint(new Point(1, 1), new Color(0, 255, 0))
        );
        items.forEach(RecordPatterns::analyzePoint);

        // ── Generic record pattern tree traversal ──────────────────────────
        Tree<Integer> tree = new Tree.Branch<>(
            new Tree.Branch<>(
                new Tree.Leaf<>(1),
                3,
                new Tree.Leaf<>(4)
            ),
            5,
            new Tree.Leaf<>(9)
        );
        System.out.println("\nTree sum: " + sum(tree));
        System.out.println("Tree depth: " + depth(tree));
    }

    static String describeShape(Shape shape) {
        return switch (shape) {
            // Nested record pattern in switch
            case Circ(Point(int cx, int cy), double r)
                -> String.format("Circle at (%d,%d) r=%.1f area=%.2f",
                    cx, cy, r, Math.PI * r * r);
            case Rect(Point(int x1, int y1), Point(int x2, int y2))
                -> String.format("Rect (%d,%d)-(%d,%d) area=%d",
                    x1, y1, x2, y2, Math.abs((x2-x1)*(y2-y1)));
            case Group(List<Shape> inner)
                -> "Group of " + inner.size() + " shapes";
        };
    }

    static void analyzePoint(Object obj) {
        switch (obj) {
            case Point(int x, int y) when x == 0 && y == 0
                -> System.out.println("Origin point");
            case Point(int x, int y) when x < 0 || y < 0
                -> System.out.println("Point in negative quadrant: (" + x + "," + y + ")");
            case Point(int x, int y)
                -> System.out.printf("Point: (%d,%d) dist=%.2f%n", x, y,
                    Math.sqrt(x*x + y*y));
            case ColoredPoint(Point(int x, int y), Color(int r, int g, int b)) when g > 200
                -> System.out.println("Vibrant green-ish point at (" + x + "," + y + ")");
            default
                -> System.out.println("Unknown: " + obj);
        }
    }

    static int sum(Tree<Integer> tree) {
        return switch (tree) {
            case Tree.Leaf<Integer>(Integer v)                             -> v;
            case Tree.Branch<Integer>(Tree<Integer> l, Integer v, Tree<Integer> r)
                -> sum(l) + v + sum(r);
        };
    }

    static int depth(Tree<?> tree) {
        return switch (tree) {
            case Tree.Leaf<?> ignored                    -> 1;
            case Tree.Branch<?(Tree<?> l, var v, Tree<?> r)
                -> 1 + Math.max(depth(l), depth(r));
        };
    }
}
