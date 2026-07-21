/**
 * Java 21 Feature: Pattern Matching for switch - Finalized (JEP 441)
 * Switch can now match on the TYPE of the selector expression,
 * not just constants. Works with sealed types for exhaustiveness.
 */
public class SwitchPatternMatching {

    sealed interface Shape permits Circle, Rectangle, Triangle, Polygon {}
    record Circle(double radius)                  implements Shape {}
    record Rectangle(double width, double height) implements Shape {}
    record Triangle(double base, double height)   implements Shape {}
    record Polygon(int sides, double sideLength)  implements Shape {}

    sealed interface Expr permits Num, Add, Mul, Neg {}
    record Num(int value)        implements Expr {}
    record Add(Expr left, Expr right) implements Expr {}
    record Mul(Expr left, Expr right) implements Expr {}
    record Neg(Expr expr)        implements Expr {}

    public static void main(String[] args) {

        // ── Pattern switch on sealed type (exhaustive, no default needed) ──
        Shape[] shapes = {
            new Circle(5),
            new Rectangle(4, 6),
            new Triangle(3, 8),
            new Polygon(6, 4)
        };
        for (Shape s : shapes) {
            System.out.printf("%-25s area = %.2f%n", s, area(s));
        }

        // ── Pattern switch on Object ───────────────────────────────────────
        Object[] values = { 42, "hello", 3.14, true, null, new int[]{1,2,3} };
        for (Object v : values) {
            System.out.println(describeObject(v));
        }

        // ── Pattern switch with null case ──────────────────────────────────
        String[] inputs = { "hello", null, "world" };
        for (String input : inputs) {
            System.out.println(handleNull(input));
        }

        // ── Pattern switch returning value ─────────────────────────────────
        Expr expression = new Add(new Mul(new Num(3), new Num(4)), new Neg(new Num(2)));
        System.out.println("\nExpression: " + format(expression));
        System.out.println("Evaluates to: " + eval(expression));
    }

    // Exhaustive switch over sealed type - compiler verifies all cases covered
    static double area(Shape shape) {
        return switch (shape) {
            case Circle c       -> Math.PI * c.radius() * c.radius();
            case Rectangle r    -> r.width() * r.height();
            case Triangle t     -> 0.5 * t.base() * t.height();
            case Polygon p      -> (p.sides() * p.sideLength() * p.sideLength())
                                   / (4 * Math.tan(Math.PI / p.sides()));
        };
    }

    // Pattern switch on Object with default
    static String describeObject(Object obj) {
        return switch (obj) {
            case Integer i       -> "Integer: " + i;
            case String s        -> "String[" + s.length() + "]: " + s;
            case Double d        -> String.format("Double: %.2f", d);
            case Boolean b       -> "Boolean: " + b;
            case int[] arr       -> "int[]: length=" + arr.length;
            case null            -> "null value";
            default              -> "Other: " + obj.getClass().getSimpleName();
        };
    }

    // Explicit null handling in switch
    static String handleNull(String s) {
        return switch (s) {
            case null    -> "Got null!";
            case "hello" -> "Hello there!";
            default      -> "Other string: " + s;
        };
    }

    // Recursive switch over expression tree
    static int eval(Expr expr) {
        return switch (expr) {
            case Num n  -> n.value();
            case Add a  -> eval(a.left()) + eval(a.right());
            case Mul m  -> eval(m.left()) * eval(m.right());
            case Neg n  -> -eval(n.expr());
        };
    }

    static String format(Expr expr) {
        return switch (expr) {
            case Num n  -> String.valueOf(n.value());
            case Add a  -> "(" + format(a.left()) + " + " + format(a.right()) + ")";
            case Mul m  -> "(" + format(m.left()) + " * " + format(m.right()) + ")";
            case Neg n  -> "(-" + format(n.expr()) + ")";
        };
    }
}
