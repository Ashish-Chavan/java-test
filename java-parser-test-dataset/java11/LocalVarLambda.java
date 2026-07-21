/**
 * Java 11 Feature: var in lambda parameters (JEP 323)
 * var can be used in lambda formal parameters to allow annotations
 * on those parameters.
 */
import java.util.List;
import java.util.function.BiFunction;
import java.util.function.Function;
import java.util.stream.Collectors;

public class LocalVarLambda {

    public static void main(String[] args) {

        // Basic var in single-parameter lambda
        Function<String, String> upper = (var s) -> s.toUpperCase();
        System.out.println(upper.apply("hello"));

        // var in multi-parameter lambda
        BiFunction<Integer, Integer, Integer> add = (var a, var b) -> a + b;
        System.out.println(add.apply(3, 7));

        // var in lambda used with streams
        List<String> names = List.of("alice", "bob", "carol");
        List<String> result = names.stream()
            .filter((var name) -> name.length() > 3)
            .map((var name) -> name.substring(0, 1).toUpperCase() + name.substring(1))
            .collect(Collectors.toList());
        System.out.println(result);

        // Demonstrating annotation use-case (the main motivation for this feature)
        List<String> processed = names.stream()
            .map((@SuppressWarnings("unused") var item) -> item.trim())
            .collect(Collectors.toList());
        System.out.println(processed);
    }
}
