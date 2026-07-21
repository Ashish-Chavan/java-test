/**
 * Java 17 Feature: Pattern Matching for instanceof - Finalized (JEP 394, Java 16)
 * Stable in Java 17. Binding variable is scoped precisely to where
 * the match is guaranteed true, including in complex boolean expressions.
 */
import java.util.Collection;
import java.util.List;
import java.util.Map;

public class PatternMatchingInstanceof {

    // Domain types for richer examples
    sealed interface Shape permits Circle, Rectangle, Triangle {}
    record Circle(double radius) implements Shape {}
    record Rectangle(double w, double h) implements Shape {}
    record Triangle(double a, double b, double c) implements Shape {}

    sealed interface Node permits LeafNode, BranchNode {}
    record LeafNode(String label) implements Node {}
    record BranchNode(String label, List<Node> children) implements Node {}

    public static void main(String[] args) {

        // ── Basic pattern variable ──────────────────────────────────────────
        Object obj = "Hello from Java 17";
        if (obj instanceof String s) {
            // 's' available here
            System.out.println("Length: " + s.length() + ", Upper: " + s.toUpperCase());
        }

        // ── Pattern in boolean AND (short-circuit) ─────────────────────────
        Object maybeString = "pattern matching";
        if (maybeString instanceof String s && s.length() > 5) {
            System.out.println("Long string: " + s);
        }

        // ── Negation form ──────────────────────────────────────────────────
        Object notString = 42;
        if (!(notString instanceof String s)) {
            // 's' NOT in scope here (match failed)
            System.out.println("Not a string, it's: " + notString.getClass().getSimpleName());
        }
        // 's' also not in scope outside

        // ── Replaces instanceof + cast pattern ─────────────────────────────
        List<Object> mixed = List.of("text", 100, 3.14, List.of(1, 2), true, 'X');
        for (Object item : mixed) {
            System.out.println(classify(item));
        }

        // ── With sealed type hierarchy ──────────────────────────────────────
        List<Shape> shapes = List.of(
            new Circle(5.0),
            new Rectangle(3.0, 4.0),
            new Triangle(3.0, 4.0, 5.0)
        );
        shapes.forEach(s -> System.out.printf("%-30s area=%.2f%n", s, area(s)));

        // ── Nested pattern in collection ───────────────────────────────────
        List<Object> nested = List.of(
            "simple",
            List.of("a", "b", "c"),
            Map.of("key", "value"),
            new int[]{1, 2, 3}
        );
        nested.forEach(PatternMatchingInstanceof::describeContainer);

        // ── Tree traversal using pattern matching ──────────────────────────
        Node tree = new BranchNode("root", List.of(
            new LeafNode("child1"),
            new BranchNode("child2", List.of(
                new LeafNode("grandchild1"),
                new LeafNode("grandchild2")
            )),
            new LeafNode("child3")
        ));
        System.out.println("\nTree:");
        printTree(tree, 0);
    }

    static String classify(Object obj) {
        if (obj instanceof String s)     return "String: \"" + s + "\"";
        if (obj instanceof Integer i)    return "Integer: " + i;
        if (obj instanceof Double d)     return String.format("Double: %.2f", d);
        if (obj instanceof List<?> l)    return "List[" + l.size() + "]";
        if (obj instanceof Boolean b)    return "Boolean: " + b;
        if (obj instanceof Character c)  return "Char: '" + c + "'";
        return "Unknown: " + obj.getClass().getSimpleName();
    }

    static double area(Shape s) {
        if (s instanceof Circle c)       return Math.PI * c.radius() * c.radius();
        if (s instanceof Rectangle r)    return r.w() * r.h();
        if (s instanceof Triangle t) {
            // Heron's formula
            double sp = (t.a() + t.b() + t.c()) / 2;
            return Math.sqrt(sp * (sp - t.a()) * (sp - t.b()) * (sp - t.c()));
        }
        throw new IllegalArgumentException("Unknown shape: " + s);
    }

    static void describeContainer(Object obj) {
        if (obj instanceof Collection<?> c && !c.isEmpty()) {
            System.out.println("Non-empty collection, size: " + c.size());
        } else if (obj instanceof Map<?, ?> m) {
            System.out.println("Map with " + m.size() + " entries");
        } else if (obj instanceof int[] arr) {
            System.out.println("int[] of length " + arr.length);
        } else if (obj instanceof String s) {
            System.out.println("String: " + s);
        }
    }

    static void printTree(Node node, int depth) {
        String indent = "  ".repeat(depth);
        if (node instanceof LeafNode leaf) {
            System.out.println(indent + "- " + leaf.label());
        } else if (node instanceof BranchNode branch) {
            System.out.println(indent + "+ " + branch.label());
            branch.children().forEach(child -> printTree(child, depth + 1));
        }
    }
}
