/**
 * Java 15 Feature: Text Blocks (JEP 378) - Finalized
 * Multi-line string literals delimited by triple quotes.
 * Incidental whitespace is stripped automatically.
 * Supports \s (explicit trailing space) and \ (line continuation).
 */
public class TextBlocks {

    public static void main(String[] args) {

        // Basic text block - JSON
        String json = """
                {
                    "name": "Alice",
                    "age": 30,
                    "active": true
                }
                """;
        System.out.println("JSON:");
        System.out.println(json);

        // HTML text block
        String html = """
                <html>
                    <body>
                        <h1>Hello, World!</h1>
                        <p>Text blocks make HTML easy.</p>
                    </body>
                </html>
                """;
        System.out.println("HTML:");
        System.out.println(html);

        // SQL text block
        String query = """
                SELECT u.name, u.email, o.total
                FROM   users u
                JOIN   orders o ON u.id = o.user_id
                WHERE  o.total > 100
                ORDER  BY o.total DESC
                """;
        System.out.println("SQL:");
        System.out.println(query);

        // \s escape: preserves trailing whitespace on a line
        String padded = """
                red  \s
                green\s
                blue \s
                """;
        System.out.println("Padded lines (each ends with space):");
        padded.lines().forEach(l -> System.out.println("[" + l + "]"));

        // \ escape: line continuation (suppresses newline)
        String continuous = """
                This is a very long string that \
                continues on the next line \
                without a newline character.
                """;
        System.out.println("Continuous: " + continuous);

        // Text block with interpolation via formatted()
        String name = "Bob";
        int score = 95;
        String report = """
                Student Report
                ==============
                Name:  %s
                Score: %d
                Grade: %s
                """.formatted(name, score, score >= 90 ? "A" : "B");
        System.out.println(report);

        // Comparing text block to traditional string
        String traditional = "line 1\n" +
                             "line 2\n" +
                             "line 3\n";
        String block = """
                line 1
                line 2
                line 3
                """;
        System.out.println("Equal: " + traditional.equals(block)); // true
    }
}
