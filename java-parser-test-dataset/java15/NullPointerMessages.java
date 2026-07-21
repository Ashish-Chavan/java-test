/**
 * Java 15 Feature: Helpful NullPointerExceptions (JEP 358)
 * The JVM now generates detailed messages for NullPointerExceptions,
 * identifying exactly which variable was null in a chained expression.
 *
 * Before Java 15: "NullPointerException" (no message)
 * After  Java 15: "Cannot invoke "String.length()" because "<local1>" is null"
 *
 * Enable with: -XX:+ShowCodeDetailsInExceptionMessages (default on in Java 15+)
 */
public class NullPointerMessages {

    record Address(String street, String city, String zip) {}
    record Person(String name, Address address, String email) {}
    record Order(Person customer, String item) {}

    public static void main(String[] args) {

        // Example 1: Simple null dereference
        demonstrateSimpleNull();

        // Example 2: Chained method call null
        demonstrateChainedNull();

        // Example 3: Array null
        demonstrateArrayNull();

        // Example 4: Nested object null
        demonstrateNestedNull();

        // Example 5: Safe navigation pattern (the proper fix)
        demonstrateSafeNavigation();
    }

    static void demonstrateSimpleNull() {
        System.out.println("--- Simple Null ---");
        try {
            String s = null;
            int len = s.length(); // NPE: "Cannot invoke "String.length()" because "s" is null"
        } catch (NullPointerException e) {
            System.out.println("NPE: " + e.getMessage());
        }
    }

    static void demonstrateChainedNull() {
        System.out.println("--- Chained Call Null ---");
        try {
            Person person = new Person("Alice", null, "alice@example.com");
            // NPE: "Cannot invoke "NullPointerMessages.Address.city()" because
            //       "person.address()" is null"
            String city = person.address().city();
        } catch (NullPointerException e) {
            System.out.println("NPE: " + e.getMessage());
        }
    }

    static void demonstrateArrayNull() {
        System.out.println("--- Array Null ---");
        try {
            String[] arr = null;
            String s = arr[0]; // NPE: "Cannot load from Object array because "arr" is null"
        } catch (NullPointerException e) {
            System.out.println("NPE: " + e.getMessage());
        }
    }

    static void demonstrateNestedNull() {
        System.out.println("--- Nested Object Null ---");
        try {
            Order order = new Order(null, "Widget");
            // NPE: identifies the exact null in the chain
            String email = order.customer().email().toUpperCase();
        } catch (NullPointerException e) {
            System.out.println("NPE: " + e.getMessage());
        }
    }

    static void demonstrateSafeNavigation() {
        System.out.println("--- Safe Navigation (no NPE) ---");

        Person person1 = new Person("Bob", new Address("123 Main St", "Springfield", "12345"), null);
        Person person2 = new Person("Carol", null, "carol@example.com");

        // Safe null checks
        System.out.println(getCity(person1)); // Springfield
        System.out.println(getCity(person2)); // Unknown city

        // Optional-based safe navigation
        java.util.Optional.ofNullable(person2.address())
            .map(Address::city)
            .ifPresentOrElse(
                city -> System.out.println("City: " + city),
                () -> System.out.println("No address on file")
            );
    }

    static String getCity(Person person) {
        if (person != null && person.address() != null) {
            return person.address().city();
        }
        return "Unknown city";
    }
}
