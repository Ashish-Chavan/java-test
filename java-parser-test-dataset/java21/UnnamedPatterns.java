/**
 * Java 21 Feature: Unnamed Patterns and Variables - Preview (JEP 443)
 * Use _ (underscore) to indicate a variable or pattern component
 * that is intentionally unused. Improves readability of pattern code.
 *
 * Compile with: javac --enable-preview --release 21 UnnamedPatterns.java
 */
import java.util.List;
import java.util.Queue;
import java.util.ArrayDeque;

public class UnnamedPatterns {

    sealed interface Shape permits Circle, Rectangle, Triangle {}
    record Circle(double radius)                   implements Shape {}
    record Rectangle(double width, double height)  implements Shape {}
    record Triangle(double a, double b, double c)  implements Shape {}

    record Point(int x, int y) {}
    record ColoredPoint(Point point, String color) {}
    record Wrapper<T>(T value, String label) {}

    sealed interface Result<T> permits Result.Ok, Result.Err {}
    record Result<T>() {
        record Ok<T>(T value)      implements Result<T> {}
        record Err<T>(String msg)  implements Result<T> {}
    }

    public static void main(String[] args) {

        // ── Unnamed variable in for loop (don't need loop variable) ────────
        List<String> items = List.of("a", "b", "c", "d", "e");
        int count = 0;
        for (var _ : items) {   // _ means "I don't need the element, just count"
            count++;
        }
        System.out.println("Count: " + count);

        // ── Unnamed variable in catch ──────────────────────────────────────
        try {
            int result = Integer.parseInt("not-a-number");
        } catch (NumberFormatException _) {
            // _ means we don't need the exception object
            System.out.println("Parse failed (exception details not needed)");
        }

        // ── Unnamed pattern in instanceof ──────────────────────────────────
        Object obj = new Circle(5.0);
        if (obj instanceof Circle _) {
            // We only care that it IS a Circle, not its fields
            System.out.println("It's a circle!");
        }

        // ── Unnamed pattern components in record deconstruction ────────────
        Object cp = new ColoredPoint(new Point(3, 4), "red");
        if (cp instanceof ColoredPoint(Point(int x, int y), _)) {
            // We only need the coordinates, not the color
            System.out.println("Point coords: x=" + x + ", y=" + y);
        }

        if (cp instanceof ColoredPoint(_, String color)) {
            // We only need the color, not the point
            System.out.println("Color: " + color);
        }

        // ── Unnamed patterns in switch ─────────────────────────────────────
        Shape[] shapes = {
            new Circle(5),
            new Rectangle(4, 6),
            new Triangle(3, 4, 5)
        };

        for (Shape s : shapes) {
            String category = switch (s) {
                case Circle _                    -> "round";
                case Rectangle(double w, double h) when w == h -> "square";
                case Rectangle _                 -> "rectangular";
                case Triangle _                  -> "triangular";
            };
            System.out.println(s.getClass().getSimpleName() + " is " + category);
        }

        // ── Unnamed variable in try-with-resources ─────────────────────────
        try (var _ = acquireResource()) {
            System.out.println("Resource used (name not needed)");
        }

        // ── Unnamed in pattern matching when only side effect matters ───────
        List<Result<Integer>> results = List.of(
            new Result.Ok<>(42),
            new Result.Err<>("timeout"),
            new Result.Ok<>(100),
            new Result.Err<>("not found")
        );

        long successCount = results.stream()
            .filter(r -> r instanceof Result.Ok<Integer> _)
            .count();
        System.out.println("Successes: " + successCount);

        // ── Nested unnamed patterns ────────────────────────────────────────
        Object wrapped = new Wrapper<>(new Point(7, 8), "tag");
        if (wrapped instanceof Wrapper<?(Point(int x, _), _)) {
            // Only care about x coordinate, nothing else
            System.out.println("X coordinate only: " + x);
        }

        // ── Unnamed variables in lambda ────────────────────────────────────
        List<String> names = List.of("Alice", "Bob", "Carol");
        names.forEach(_ -> System.out.print("* ")); // don't need element
        System.out.println();
    }

    // Helper: auto-closeable resource where the reference isn't needed
    static AutoCloseable acquireResource() {
        System.out.println("Resource acquired");
        return () -> System.out.println("Resource released");
    }
}
