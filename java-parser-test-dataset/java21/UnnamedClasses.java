/**
 * Java 21 Feature: Unnamed Classes and Instance Main Methods - Preview (JEP 445)
 * Reduces ceremony for small programs:
 * - No class declaration needed (unnamed class)
 * - main() can be an instance method (no static required)
 * - main() doesn't need String[] args parameter
 *
 * Compile with: javac --enable-preview --release 21 UnnamedClasses.java
 * Run with:     java  --enable-preview UnnamedClasses
 *
 * This file shows BOTH the new style (unnamed/simplified) and
 * the traditional style for comparison.
 */
import java.util.List;
import java.util.stream.Collectors;

// ── Traditional Java program (for comparison) ──────────────────────────────
// public class Main {
//     public static void main(String[] args) {
//         System.out.println("Hello, World!");
//     }
// }

// ── Unnamed class: no class declaration, instance main(), no args ──────────
// (The following top-level code IS the unnamed class)

void main() {
    System.out.println("Hello from an unnamed class!");

    // Instance methods are available directly
    greet("World");
    greet("Java 21");

    // Regular Java code works as expected
    var numbers = List.of(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
    var evens = numbers.stream()
        .filter(n -> n % 2 == 0)
        .collect(Collectors.toList());
    System.out.println("Evens: " + evens);
    System.out.println("Sum of evens: " + evens.stream().mapToInt(Integer::intValue).sum());

    // Calling instance helper methods
    System.out.println(formatTable(
        List.of("Alice", "Bob", "Carol"),
        List.of(30, 25, 35)
    ));

    // Using records defined at top level
    var person = new Person("Dave", 28);
    System.out.println(describe(person));
}

// Instance methods in unnamed class (no static modifier needed)
void greet(String name) {
    System.out.println("Hello, " + name + "!");
}

String formatTable(List<String> names, List<Integer> ages) {
    var sb = new StringBuilder("Name        Age\n");
    sb.append("----------- ---\n");
    for (int i = 0; i < names.size(); i++) {
        sb.append(String.format("%-12s%d%n", names.get(i), ages.get(i)));
    }
    return sb.toString();
}

String describe(Person p) {
    return STR."Person: \{p.name()}, age \{p.age()}, adult=\{p.age() >= 18}";
}

// Records and other type declarations are fine in unnamed class files
record Person(String name, int age) {}
