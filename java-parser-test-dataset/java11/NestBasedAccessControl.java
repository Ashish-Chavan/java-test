/**
 * Java 11 Feature: Nest-Based Access Control (JEP 181)
 * Nested classes are now "nestmates" and can access each other's
 * private members directly without synthetic bridge methods.
 * Reflective access also respects nest membership via getNestHost()
 * and getNestMembers().
 */
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.Arrays;

public class NestBasedAccessControl {

    // Private field accessible to nestmates
    private String secretMessage = "Hello from outer class";

    // Private method accessible to nestmates
    private void privateMethod() {
        System.out.println("Private outer method called");
    }

    class InnerReader {
        void read() {
            // Direct access to private field of outer class - no bridge method needed
            System.out.println("Inner reads: " + secretMessage);

            // Direct invocation of private method of outer class
            privateMethod();
        }

        private String innerSecret = "Inner secret";
    }

    static class StaticNested {
        private int value = 42;

        void display(NestBasedAccessControl outer) {
            // Access outer private field directly
            System.out.println("Static nested reads: " + outer.secretMessage);
            outer.secretMessage = "Modified by static nested";
        }
    }

    static class AnotherNested {
        void accessSibling() {
            StaticNested sibling = new StaticNested();
            // Accessing private field of sibling nestmate
            System.out.println("Sibling value: " + sibling.value);
        }
    }

    public static void main(String[] args) throws Exception {

        NestBasedAccessControl outer = new NestBasedAccessControl();

        // Nest-based access in action
        InnerReader reader = outer.new InnerReader();
        reader.read();

        StaticNested nested = new StaticNested();
        nested.display(outer);
        System.out.println("After modification: " + outer.secretMessage);

        AnotherNested another = new AnotherNested();
        another.accessSibling();

        // Reflective nest membership inspection
        System.out.println("\n--- Nest Reflection ---");
        Class<?> nestHost = NestBasedAccessControl.class.getNestHost();
        System.out.println("Nest host of outer: " + nestHost.getSimpleName());

        Class<?> innerNestHost = InnerReader.class.getNestHost();
        System.out.println("Nest host of InnerReader: " + innerNestHost.getSimpleName());

        Class<?>[] nestMembers = NestBasedAccessControl.class.getNestMembers();
        System.out.println("Nest members:");
        Arrays.stream(nestMembers)
              .map(Class::getSimpleName)
              .forEach(name -> System.out.println("  " + name));

        // Reflective access to private members within a nest (no setAccessible needed)
        Field innerField = InnerReader.class.getDeclaredField("innerSecret");
        innerField.setAccessible(true); // still required for reflection, but JVM respects nestmate
        System.out.println("Reflected inner field: " + innerField.get(reader));
    }
}
