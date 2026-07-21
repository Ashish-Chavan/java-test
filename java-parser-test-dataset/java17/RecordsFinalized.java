/**
 * Java 17 Feature: Records - Finalized (JEP 395, Java 16)
 * Records are immutable data classes. The compiler auto-generates:
 * constructor, accessors, equals(), hashCode(), toString().
 * Java 17 is the LTS where records are fully production-ready.
 */
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Collectors;

public class RecordsFinalized {

    // ── Basic record ───────────────────────────────────────────────────────
    record Point(double x, double y) {
        // Compact canonical constructor with validation
        Point {
            if (Double.isNaN(x) || Double.isNaN(y)) {
                throw new IllegalArgumentException("Coordinates cannot be NaN");
            }
        }

        // Custom instance method
        double distanceTo(Point other) {
            double dx = this.x - other.x;
            double dy = this.y - other.y;
            return Math.sqrt(dx * dx + dy * dy);
        }

        // Static factory method
        static Point origin() { return new Point(0, 0); }
    }

    // ── Generic record ─────────────────────────────────────────────────────
    record Pair<A, B>(A first, B second) {
        static <A, B> Pair<A, B> of(A a, B b) { return new Pair<>(a, b); }

        Pair<B, A> swap() { return new Pair<>(second, first); }
    }

    // ── Record implementing interface ──────────────────────────────────────
    interface Printable { void print(); }

    record Person(String name, int age, String email) implements Printable {
        // Compact constructor - guard against nulls and invalid age
        Person {
            Objects.requireNonNull(name, "name must not be null");
            Objects.requireNonNull(email, "email must not be null");
            if (age < 0 || age > 150) throw new IllegalArgumentException("Invalid age: " + age);
            name = name.trim(); // can reassign parameters in compact constructor
        }

        // Custom accessor that derived info
        boolean isAdult() { return age >= 18; }

        @Override
        public void print() {
            System.out.printf("Person{name='%s', age=%d, adult=%b}%n", name, age, isAdult());
        }
    }

    // ── Nested / composed records ──────────────────────────────────────────
    record Address(String street, String city, String country) {}

    record Employee(Person person, Address address, String department, double salary) {
        // Custom toString override
        @Override
        public String toString() {
            return String.format("Employee[%s, dept=%s, city=%s]",
                person.name(), department, address.city());
        }
    }

    // ── Record with List field (immutable by convention) ───────────────────
    record Team(String name, List<Person> members) {
        Team {
            members = List.copyOf(members); // defensive copy
        }

        int size() { return members.size(); }
        double averageAge() {
            return members.stream().mapToInt(Person::age).average().orElse(0);
        }
    }

    // ── Record used as Map key (equals/hashCode auto-generated) ───────────
    record Coordinate(int row, int col) {}

    public static void main(String[] args) {

        // Basic record usage
        Point p1 = new Point(3, 4);
        Point p2 = new Point(0, 0);
        System.out.println("p1 = " + p1);
        System.out.println("p1.x() = " + p1.x());
        System.out.printf("distance = %.2f%n", p1.distanceTo(p2));

        // Records have structural equals/hashCode
        Point p3 = new Point(3, 4);
        System.out.println("p1.equals(p3) = " + p1.equals(p3)); // true

        // Generic pair
        Pair<String, Integer> pair = Pair.of("hello", 42);
        System.out.println("pair = " + pair);
        System.out.println("swapped = " + pair.swap());

        // Person with validation
        Person alice = new Person("  Alice  ", 30, "alice@example.com");
        alice.print();
        System.out.println("Name (trimmed): '" + alice.name() + "'");

        // Composed records
        Employee emp = new Employee(
            alice,
            new Address("123 Main St", "Springfield", "USA"),
            "Engineering",
            95_000.0
        );
        System.out.println(emp);

        // Team with list
        Team team = new Team("Dev Team", List.of(
            new Person("Alice", 30, "alice@example.com"),
            new Person("Bob",   25, "bob@example.com"),
            new Person("Carol", 35, "carol@example.com")
        ));
        System.out.printf("Team: %s, size=%d, avgAge=%.1f%n",
            team.name(), team.size(), team.averageAge());

        // Records as Map keys
        Map<Coordinate, String> grid = Map.of(
            new Coordinate(0, 0), "start",
            new Coordinate(0, 1), "path",
            new Coordinate(1, 1), "end"
        );
        System.out.println("grid[0,0] = " + grid.get(new Coordinate(0, 0)));
        System.out.println("grid[1,1] = " + grid.get(new Coordinate(1, 1)));
    }
}
