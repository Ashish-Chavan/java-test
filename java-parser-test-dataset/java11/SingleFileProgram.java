/**
 * Java 11 Feature: Launch Single-File Source-Code Programs (JEP 330)
 * Java 11 allows running a single .java file directly with:
 *     java SingleFileProgram.java arg1 arg2
 * The file is compiled in-memory and the first class found with a
 * main() method is executed. No explicit javac step needed.
 *
 * This file also demonstrates helper classes defined within the same
 * source file (only the first class is public).
 */

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

public class SingleFileProgram {

    public static void main(String[] args) {
        System.out.println("Running as single-file program");
        System.out.println("Arguments: " + Arrays.toString(args));

        Greeter greeter = new Greeter("World");
        greeter.greet();

        Calculator calc = new Calculator();
        System.out.println("3 + 4 = " + calc.add(3, 4));
        System.out.println("10 * 5 = " + calc.multiply(10, 5));

        List<String> words = List.of("single", "file", "programs", "are", "convenient");
        String summary = words.stream()
            .filter(w -> w.length() > 4)
            .map(String::toUpperCase)
            .collect(Collectors.joining(", "));
        System.out.println("Long words: " + summary);
    }
}

// Additional helper classes in the same file
// Only SingleFileProgram (first class) may be public
class Greeter {
    private final String target;

    Greeter(String target) {
        this.target = target;
    }

    void greet() {
        System.out.println("Hello, " + target + "!");
    }
}

class Calculator {
    int add(int a, int b) {
        return a + b;
    }

    int multiply(int a, int b) {
        return a * b;
    }
}
