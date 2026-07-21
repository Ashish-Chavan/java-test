/**
 * Java 11 Feature: New String Methods
 * isBlank(), strip(), stripLeading(), stripTrailing(), lines(), repeat()
 * These are Unicode-aware improvements over older trim()/isEmpty() methods.
 */
public class NewStringMethods {

    public static void main(String[] args) {

        // isBlank() - true if empty or only whitespace (Unicode-aware)
        String empty = "";
        String spaces = "   ";
        String content = "  hello  ";
        System.out.println(empty.isBlank());       // true
        System.out.println(spaces.isBlank());      // true
        System.out.println(content.isBlank());     // false

        // strip() - Unicode-aware whitespace removal (vs trim() which is ASCII-only)
        String padded = "  \u2003hello\u2003  "; // \u2003 is em space
        System.out.println("[" + padded.strip() + "]");
        System.out.println("[" + padded.stripLeading() + "]");
        System.out.println("[" + padded.stripTrailing() + "]");

        // lines() - splits string into stream of lines
        String multiline = "line one\nline two\nline three";
        multiline.lines()
                 .map(String::strip)
                 .forEach(System.out::println);

        // repeat() - repeats string n times
        String dash = "-";
        System.out.println(dash.repeat(20));

        String separator = "=-";
        System.out.println(separator.repeat(10));

        // Combining new methods in a practical use case
        String rawInput = "  \n  hello world  \n  ";
        long nonBlankLines = rawInput.lines()
                                     .filter(line -> !line.isBlank())
                                     .map(String::strip)
                                     .count();
        System.out.println("Non-blank lines: " + nonBlankLines);
    }
}
