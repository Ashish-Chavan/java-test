/**
 * Java 17 Feature: Sealed Interfaces (JEP 409)
 * Interfaces can also be sealed, constraining their implementors.
 * Particularly powerful for algebraic data types / discriminated unions.
 */
import java.util.List;
import java.util.Optional;
import java.util.function.Function;

public class SealedInterfaces {

    // ── Result type (like Rust's Result<T,E> or Haskell's Either) ──────────

    sealed interface Result<T>
        permits Result.Success, Result.Failure {

        boolean isSuccess();

        record Success<T>(T value) implements Result<T> {
            public boolean isSuccess() { return true; }
        }

        record Failure<T>(String error, Throwable cause) implements Result<T> {
            Failure(String error) { this(error, null); }
            public boolean isSuccess() { return false; }
        }

        // Static factory methods
        static <T> Result<T> success(T value) { return new Success<>(value); }
        static <T> Result<T> failure(String error) { return new Failure<>(error); }
        static <T> Result<T> failure(String error, Throwable cause) {
            return new Failure<>(error, cause);
        }

        // Map over the success value
        default <U> Result<U> map(Function<T, U> fn) {
            if (this instanceof Success<T> s) {
                return Result.success(fn.apply(s.value()));
            } else if (this instanceof Failure<T> f) {
                return new Failure<>(f.error(), f.cause());
            }
            throw new IllegalStateException();
        }

        // Get value or default
        default T getOrElse(T defaultValue) {
            return this instanceof Success<T> s ? s.value() : defaultValue;
        }
    }

    // ── JSON value types (like a mini-JSON AST) ────────────────────────────

    sealed interface JsonValue
        permits JsonNull, JsonBool, JsonNumber, JsonString, JsonArray, JsonObject {}

    record JsonNull() implements JsonValue {
        @Override public String toString() { return "null"; }
    }

    record JsonBool(boolean value) implements JsonValue {
        @Override public String toString() { return String.valueOf(value); }
    }

    record JsonNumber(double value) implements JsonValue {
        @Override public String toString() {
            return value == Math.floor(value) ? String.valueOf((long) value)
                                              : String.valueOf(value);
        }
    }

    record JsonString(String value) implements JsonValue {
        @Override public String toString() { return "\"" + value + "\""; }
    }

    record JsonArray(List<JsonValue> elements) implements JsonValue {
        @Override public String toString() { return elements.toString(); }
    }

    record JsonObject(List<Entry> fields) implements JsonValue {
        record Entry(String key, JsonValue value) {}
        @Override public String toString() {
            return fields.stream()
                .map(e -> "\"" + e.key() + "\": " + e.value())
                .reduce("{", (a, b) -> a + (a.equals("{") ? "" : ", ") + b) + "}";
        }
    }

    // ── Command pattern with sealed interface ──────────────────────────────

    sealed interface Command
        permits Command.CreateUser, Command.DeleteUser,
                Command.UpdateEmail, Command.ResetPassword {

        record CreateUser(String username, String email) implements Command {}
        record DeleteUser(String userId) implements Command {}
        record UpdateEmail(String userId, String newEmail) implements Command {}
        record ResetPassword(String userId) implements Command {}
    }

    public static void main(String[] args) {

        // Result type
        Result<Integer> success = Result.success(42);
        Result<Integer> failure = Result.failure("Not found");

        System.out.println(success.isSuccess() + ": " + success.getOrElse(-1));
        System.out.println(failure.isSuccess() + ": " + failure.getOrElse(-1));

        Result<String> mapped = success.map(i -> "Value is " + i);
        System.out.println(mapped.getOrElse("no value"));

        // JSON value types
        JsonValue doc = new JsonObject(List.of(
            new JsonObject.Entry("name",   new JsonString("Alice")),
            new JsonObject.Entry("age",    new JsonNumber(30)),
            new JsonObject.Entry("active", new JsonBool(true)),
            new JsonObject.Entry("notes",  new JsonNull()),
            new JsonObject.Entry("scores", new JsonArray(List.of(
                new JsonNumber(95), new JsonNumber(87), new JsonNumber(92)
            )))
        ));
        System.out.println(doc);
        System.out.println("Type: " + describeJson(doc));

        // Command pattern
        List<Command> commands = List.of(
            new Command.CreateUser("alice", "alice@example.com"),
            new Command.UpdateEmail("u1", "new@example.com"),
            new Command.ResetPassword("u2"),
            new Command.DeleteUser("u3")
        );
        commands.forEach(SealedInterfaces::processCommand);
    }

    static String describeJson(JsonValue v) {
        if (v instanceof JsonNull)        return "null";
        if (v instanceof JsonBool b)      return "boolean(" + b.value() + ")";
        if (v instanceof JsonNumber n)    return "number(" + n.value() + ")";
        if (v instanceof JsonString s)    return "string(\"" + s.value() + "\")";
        if (v instanceof JsonArray a)     return "array[" + a.elements().size() + "]";
        if (v instanceof JsonObject o)    return "object{" + o.fields().size() + "}";
        throw new IllegalArgumentException();
    }

    static void processCommand(Command cmd) {
        if (cmd instanceof Command.CreateUser c)
            System.out.println("CREATE: " + c.username() + " <" + c.email() + ">");
        else if (cmd instanceof Command.DeleteUser d)
            System.out.println("DELETE: " + d.userId());
        else if (cmd instanceof Command.UpdateEmail u)
            System.out.println("UPDATE EMAIL: " + u.userId() + " -> " + u.newEmail());
        else if (cmd instanceof Command.ResetPassword r)
            System.out.println("RESET PASSWORD: " + r.userId());
    }
}
