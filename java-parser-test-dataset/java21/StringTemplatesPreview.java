/**
 * Java 21 Feature: String Templates - Preview (JEP 430)
 * String templates allow embedding expressions directly in string literals
 * using template processors. Unlike string interpolation in other languages,
 * Java's approach requires explicit processors for safety and flexibility.
 *
 * Compile with: javac --enable-preview --release 21 StringTemplatesPreview.java
 * Run with:     java  --enable-preview StringTemplatesPreview
 *
 * Note: This feature was re-previewed and revised in Java 22/23.
 * The STR processor shown here is the Java 21 preview syntax.
 */
public class StringTemplatesPreview {

    record Person(String name, int age, String city) {}
    record Product(String name, double price, int quantity) {}
    record Point(double x, double y) {}

    public static void main(String[] args) {

        // ── STR processor: basic interpolation ────────────────────────────
        String name = "Alice";
        int age = 30;
        String greeting = STR."Hello, \{name}! You are \{age} years old.";
        System.out.println(greeting);

        // ── Expressions inside \{} ─────────────────────────────────────────
        int a = 5, b = 7;
        String math = STR."\{a} + \{b} = \{a + b}";
        System.out.println(math);

        // Method calls inside template
        String upper = STR."Name in caps: \{name.toUpperCase()}";
        System.out.println(upper);

        // Conditional expression
        boolean vip = true;
        String status = STR."Status: \{vip ? "VIP member" : "Regular member"}";
        System.out.println(status);

        // ── Multi-line string template ─────────────────────────────────────
        Person person = new Person("Bob", 25, "New York");
        String profile = STR."""
                Name: \{person.name()}
                Age:  \{person.age()}
                City: \{person.city()}
                Adult: \{person.age() >= 18 ? "Yes" : "No"}
                """;
        System.out.println(profile);

        // ── Nested templates ───────────────────────────────────────────────
        String firstName = "Carol";
        String lastName  = "Smith";
        String fullName  = STR."\{firstName} \{lastName}";
        String intro     = STR."Introducing: \{fullName.toUpperCase()}";
        System.out.println(intro);

        // ── FMT processor: formatted string templates ──────────────────────
        Product product = new Product("Widget", 9.99, 150);
        String formatted = STR."""
                Product:  \{product.name()}
                Price:    $\{product.price()}
                Qty:      \{product.quantity()}
                Total:    $\{product.price() * product.quantity()}
                """;
        System.out.println(formatted);

        // ── Templates in loops ─────────────────────────────────────────────
        String[] fruits = {"apple", "banana", "cherry"};
        for (int i = 0; i < fruits.length; i++) {
            System.out.println(STR."\{i + 1}. \{fruits[i]} (\{fruits[i].length()} chars)");
        }

        // ── Template with object method calls ─────────────────────────────
        Point p = new Point(3.0, 4.0);
        double dist = Math.sqrt(p.x() * p.x() + p.y() * p.y());
        String pointDesc = STR."Point(\{p.x()}, \{p.y()}) distance from origin = \{dist}";
        System.out.println(pointDesc);

        // ── Building structured output ─────────────────────────────────────
        String[] headers = {"Name", "Age", "City"};
        Object[][] data = {
            {"Alice", 30, "NYC"},
            {"Bob",   25, "LA"},
            {"Carol", 35, "Chicago"}
        };

        StringBuilder sb = new StringBuilder();
        sb.append(STR."| \{headers[0],-10} | \{headers[1],-5} | \{headers[2],-10} |\n");
        sb.append("|-----------|-------|------------|\n");
        for (Object[] row : data) {
            sb.append(STR."| \{row[0],-10} | \{row[1],-5} | \{row[2],-10} |\n");
        }
        System.out.println(sb);
    }
}
