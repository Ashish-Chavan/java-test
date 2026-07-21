/**
 * Java 15 Feature: Pattern Matching for instanceof - Preview (JEP 375)
 * Eliminates the need for explicit casts after an instanceof check.
 * The binding variable is in scope only where the pattern is true.
 * Finalized in Java 16 (JEP 394).
 *
 * Compile with: javac --enable-preview --release 15 PatternInstanceofPreview.java
 */
import java.util.ArrayList;
import java.util.List;

public class PatternInstanceofPreview {

    sealed interface Animal permits Dog, Cat, Bird {}
    record Dog(String name) implements Animal {}
    record Cat(String name, boolean indoor) implements Animal {}
    record Bird(String name, String species) implements Animal {}

    public static void main(String[] args) {

        // Traditional instanceof (before Java 15)
        Object obj = "Hello, Pattern Matching!";
        if (obj instanceof String) {
            String s = (String) obj; // explicit cast required
            System.out.println("Traditional: length = " + s.length());
        }

        // Pattern matching instanceof - binding variable 's'
        if (obj instanceof String s) {
            // 's' is already typed as String, no cast needed
            System.out.println("Pattern: length = " + s.length());
            System.out.println("Pattern: upper = " + s.toUpperCase());
        }

        // Binding variable scope - only true in the if-true branch
        Object number = 42;
        if (number instanceof Integer i) {
            System.out.println("Is integer: " + (i * 2));
        }
        // 'i' is NOT in scope here

        // Used in logical AND condition
        Object value = "Java 15";
        if (value instanceof String s && s.startsWith("Java")) {
            System.out.println("Starts with Java: " + s);
        }

        // Negation pattern - binding in else branch
        Object maybeString = "test";
        if (!(maybeString instanceof String s)) {
            System.out.println("Not a string");
        } else {
            // 's' is in scope in the else branch
            System.out.println("Is string: " + s.toUpperCase());
        }

        // Pattern instanceof in a method
        List<Object> mixed = List.of(1, "hello", 3.14, true, "world", 42L);
        for (Object item : mixed) {
            describe(item);
        }

        // With sealed types and animal hierarchy
        List<Animal> animals = List.of(
            new Dog("Rex"),
            new Cat("Whiskers", true),
            new Bird("Tweety", "Canary"),
            new Dog("Buddy")
        );
        animals.forEach(PatternInstanceofPreview::describeAnimal);
    }

    static void describe(Object obj) {
        if (obj instanceof Integer i) {
            System.out.println("int: " + i);
        } else if (obj instanceof String s) {
            System.out.println("String[" + s.length() + "]: " + s);
        } else if (obj instanceof Double d) {
            System.out.printf("double: %.2f%n", d);
        } else if (obj instanceof Boolean b) {
            System.out.println("boolean: " + b);
        } else if (obj instanceof Long l) {
            System.out.println("long: " + l);
        }
    }

    static void describeAnimal(Animal animal) {
        if (animal instanceof Dog d) {
            System.out.println("Dog named: " + d.name());
        } else if (animal instanceof Cat c && c.indoor()) {
            System.out.println("Indoor cat: " + c.name());
        } else if (animal instanceof Cat c) {
            System.out.println("Outdoor cat: " + c.name());
        } else if (animal instanceof Bird b) {
            System.out.println("Bird: " + b.name() + " (" + b.species() + ")");
        }
    }
}
