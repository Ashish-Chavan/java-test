/**
 * Java 17 Feature: Text Blocks - Stable LTS (JEP 378, finalized Java 15)
 * Java 17 is the LTS release where text blocks are fully stable.
 * This file focuses on the \s and \ escape sequences added at finalization,
 * and advanced indentation/alignment use cases.
 */
import java.util.List;

public class TextBlocksFinalized {

    public static void main(String[] args) {

        // ── \s escape: force trailing whitespace ───────────────────────────
        System.out.println("=== \\s escape (preserve trailing spaces) ===");
        String table = """
                NAME         AGE  CITY       \s
                ------------ ---- ---------- \s
                Alice        30   New York   \s
                Bob          25   London     \s
                Carol        35   Tokyo      \s
                """;
        // Each line ends with one space due to \s
        table.lines().forEach(l -> System.out.println("|" + l + "|"));

        // ── \ escape: line continuation (no newline) ───────────────────────
        System.out.println("\n=== \\ escape (line continuation) ===");
        String sentence = """
                The quick brown fox \
                jumps over the lazy dog. \
                This is all one line.
                """;
        System.out.println(sentence);
        System.out.println("Contains newlines: " + sentence.contains("\n"));

        // ── Indentation control ────────────────────────────────────────────
        System.out.println("=== Indentation ===");
        // Closing """ position controls indentation stripping
        String indented = """
                    first line
                    second line
                    third line
                """; // closing """ at column 16, strips 16 chars of indent
        System.out.println(indented);

        // stripIndent() and translateEscapes() for manual control
        String raw = "    line one\n    line two\n    line three";
        System.out.println("After stripIndent:");
        System.out.println(raw.stripIndent());

        // ── Embedded quotes ────────────────────────────────────────────────
        System.out.println("=== Embedded quotes ===");
        String json = """
                {
                    "message": "Hello, \\"World\\"",
                    "path": "C:\\\\Users\\\\alice",
                    "multiline": "line1\nline2"
                }
                """;
        System.out.println(json);

        // ── Template-style text blocks ─────────────────────────────────────
        System.out.println("=== Template-style ===");
        record Product(String name, double price, int qty) {}
        List<Product> products = List.of(
            new Product("Widget", 9.99, 100),
            new Product("Gadget", 24.95, 50),
            new Product("Doohickey", 4.49, 200)
        );

        String header = """
                ┌─────────────────────────────────────┐
                │ Product Inventory Report             │
                └─────────────────────────────────────┘
                """;
        System.out.print(header);

        for (Product p : products) {
            String row = """
                    Name:  %-20s
                    Price: $%6.2f
                    Qty:   %4d
                    """.formatted(p.name(), p.price(), p.qty());
            System.out.print(row);
        }

        // ── YAML text block ────────────────────────────────────────────────
        System.out.println("=== YAML ===");
        String yaml = """
                server:
                  host: localhost
                  port: 8080
                  ssl: false
                database:
                  url: jdbc:postgresql://localhost/mydb
                  username: admin
                  pool:
                    min: 5
                    max: 20
                """;
        System.out.println(yaml);

        // ── Whitespace visualization ───────────────────────────────────────
        System.out.println("=== translateEscapes ===");
        String withEscapes = "Line 1\\nLine 2\\tTabbed";
        System.out.println("Before: " + withEscapes);
        System.out.println("After:  " + withEscapes.translateEscapes());
    }
}
