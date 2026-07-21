/**
 * Java 17 Feature: Sealed Classes - Finalized (JEP 409)
 * Sealed classes and interfaces restrict which other classes/interfaces
 * may extend or implement them. Each permitted subtype must be:
 *   - final        (no further extension)
 *   - sealed       (extends the restriction)
 *   - non-sealed   (opens back up to any extension)
 */
public class SealedClasses {

    // ── Sealed class hierarchy for an expression tree ──────────────────────

    sealed abstract static class Expr
        permits Literal, Add, Multiply, Negate {
        abstract int eval();
    }

    // final: cannot be subclassed
    final static class Literal extends Expr {
        final int value;
        Literal(int value) { this.value = value; }

        @Override public int eval() { return value; }
        @Override public String toString() { return String.valueOf(value); }
    }

    final static class Add extends Expr {
        final Expr left, right;
        Add(Expr left, Expr right) { this.left = left; this.right = right; }

        @Override public int eval() { return left.eval() + right.eval(); }
        @Override public String toString() { return "(" + left + " + " + right + ")"; }
    }

    final static class Multiply extends Expr {
        final Expr left, right;
        Multiply(Expr left, Expr right) { this.left = left; this.right = right; }

        @Override public int eval() { return left.eval() * right.eval(); }
        @Override public String toString() { return "(" + left + " * " + right + ")"; }
    }

    // non-sealed: allows further extension outside this file
    non-sealed static class Negate extends Expr {
        final Expr operand;
        Negate(Expr operand) { this.operand = operand; }

        @Override public int eval() { return -operand.eval(); }
        @Override public String toString() { return "(-" + operand + ")"; }
    }

    // Further extends Negate because it is non-sealed
    static class AbsoluteValue extends Negate {
        AbsoluteValue(Expr operand) { super(operand); }

        @Override public int eval() { return Math.abs(super.eval()); }
        @Override public String toString() { return "|" + operand + "|"; }
    }

    // ── Sealed interface for HTTP response outcomes ─────────────────────────

    sealed interface HttpOutcome
        permits HttpOutcome.Ok, HttpOutcome.ClientError, HttpOutcome.ServerError {

        int statusCode();
        String message();

        record Ok(String body) implements HttpOutcome {
            public int statusCode() { return 200; }
            public String message() { return "OK"; }
        }

        record ClientError(int statusCode, String reason) implements HttpOutcome {
            public String message() { return "Client Error: " + reason; }
        }

        record ServerError(int statusCode, String cause) implements HttpOutcome {
            public String message() { return "Server Error: " + cause; }
        }
    }

    // ── Sealed with intermediate sealed layer ───────────────────────────────

    sealed interface Vehicle permits Car, Truck, Motorcycle {}

    sealed interface Car extends Vehicle permits Car.Sedan, Car.SUV, Car.Coupe {
        record Sedan(String model) implements Car {}
        record SUV(String model, boolean awd) implements Car {}
        record Coupe(String model) implements Car {}
    }

    final static class Truck implements Vehicle {
        final String model;
        final double payloadTons;
        Truck(String model, double payloadTons) {
            this.model = model;
            this.payloadTons = payloadTons;
        }
    }

    final static class Motorcycle implements Vehicle {
        final String model;
        Motorcycle(String model) { this.model = model; }
    }

    public static void main(String[] args) {

        // Expression tree evaluation
        Expr expr = new Add(
            new Multiply(new Literal(3), new Literal(4)),
            new Negate(new Literal(2))
        );
        System.out.println(expr + " = " + expr.eval()); // (3*4)+(-2) = 10

        Expr abs = new AbsoluteValue(new Literal(-7));
        System.out.println(abs + " = " + abs.eval()); // |-7| = 7

        // HTTP outcome handling
        HttpOutcome[] outcomes = {
            new HttpOutcome.Ok("{\"status\": \"up\"}"),
            new HttpOutcome.ClientError(404, "Not Found"),
            new HttpOutcome.ServerError(500, "Internal Server Error")
        };
        for (HttpOutcome outcome : outcomes) {
            System.out.printf("[%d] %s%n", outcome.statusCode(), outcome.message());
        }

        // Vehicle hierarchy
        Vehicle[] fleet = {
            new Car.Sedan("Camry"),
            new Car.SUV("RAV4", true),
            new Truck("F-150", 1.5),
            new Motorcycle("CBR500R")
        };
        for (Vehicle v : fleet) {
            System.out.println(describeVehicle(v));
        }
    }

    static String describeVehicle(Vehicle v) {
        if (v instanceof Car.Sedan s)      return "Sedan: " + s.model();
        if (v instanceof Car.SUV s)        return "SUV: " + s.model() + (s.awd() ? " AWD" : "");
        if (v instanceof Truck t)          return "Truck: " + t.model + " (" + t.payloadTons + "t)";
        if (v instanceof Motorcycle m)     return "Motorcycle: " + m.model;
        return "Unknown vehicle";
    }
}
