/**
 * Java 15 Feature: Sealed Classes - Preview (JEP 360)
 * Sealed classes restrict which other classes may extend or implement them.
 * Compile with: javac --enable-preview --release 15 SealedClassPreview.java
 *
 * Note: Finalized in Java 17 (JEP 409). This file shows the preview syntax,
 * which is identical to the final version.
 */
public class SealedClassPreview {

    // Sealed abstract class - only listed classes can extend it
    sealed abstract static class Shape
        permits Circle, Rectangle, Triangle {
        abstract double area();
        abstract String describe();
    }

    // Each permitted subclass must be: final, sealed, or non-sealed
    final static class Circle extends Shape {
        private final double radius;

        Circle(double radius) {
            this.radius = radius;
        }

        @Override
        public double area() {
            return Math.PI * radius * radius;
        }

        @Override
        public String describe() {
            return "Circle(r=" + radius + ")";
        }
    }

    final static class Rectangle extends Shape {
        private final double width;
        private final double height;

        Rectangle(double width, double height) {
            this.width = width;
            this.height = height;
        }

        @Override
        public double area() {
            return width * height;
        }

        @Override
        public String describe() {
            return "Rectangle(" + width + "x" + height + ")";
        }
    }

    // non-sealed allows further extension of the hierarchy
    non-sealed static class Triangle extends Shape {
        private final double base;
        private final double height;

        Triangle(double base, double height) {
            this.base = base;
            this.height = height;
        }

        @Override
        public double area() {
            return 0.5 * base * height;
        }

        @Override
        public String describe() {
            return "Triangle(b=" + base + ", h=" + height + ")";
        }
    }

    // Further extension allowed because Triangle is non-sealed
    static class RightTriangle extends Triangle {
        RightTriangle(double leg1, double leg2) {
            super(leg1, leg2);
        }

        @Override
        public String describe() {
            return "RightTriangle";
        }
    }

    // Sealed interface example
    sealed interface Result<T> permits Result.Success, Result.Failure {
        record Success<T>(T value) implements Result<T> {}
        record Failure<T>(String error) implements Result<T> {}
    }

    public static void main(String[] args) {
        Shape[] shapes = {
            new Circle(5),
            new Rectangle(4, 6),
            new Triangle(3, 8),
            new RightTriangle(3, 4)
        };

        for (Shape shape : shapes) {
            System.out.printf("%s -> area = %.2f%n", shape.describe(), shape.area());
        }

        // Sealed interface usage
        Result<Integer> success = new Result.Success<>(42);
        Result<Integer> failure = new Result.Failure<>("Not found");

        printResult(success);
        printResult(failure);
    }

    static void printResult(Result<?> result) {
        if (result instanceof Result.Success<?> s) {
            System.out.println("Success: " + s.value());
        } else if (result instanceof Result.Failure<?> f) {
            System.out.println("Failure: " + f.error());
        }
    }
}
