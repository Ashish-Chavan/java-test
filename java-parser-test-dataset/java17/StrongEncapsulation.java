/**
 * Java 17 Feature: Strong Encapsulation of JDK Internals (JEP 403)
 * Java 17 strongly encapsulates all JDK internal APIs by default.
 * Code that used to access sun.* or com.sun.* internal APIs now
 * requires explicit --add-opens flags.
 *
 * This file demonstrates:
 * 1. The public APIs to use INSTEAD of internals
 * 2. How to detect and handle encapsulation at runtime
 * 3. Patterns for migrating away from internal API usage
 */
import java.lang.reflect.InaccessibleObjectException;
import java.lang.management.ManagementFactory;
import java.lang.management.MemoryMXBean;
import java.lang.management.RuntimeMXBean;
import java.util.Base64;
import java.util.HexFormat;
import java.util.List;

public class StrongEncapsulation {

    public static void main(String[] args) {

        // ── 1. Use public APIs instead of sun.misc.BASE64Encoder ──────────
        System.out.println("=== Base64 (public API since Java 8) ===");
        String original = "Hello, Strong Encapsulation!";
        byte[] encoded = Base64.getEncoder().encode(original.getBytes());
        String encodedStr = new String(encoded);
        System.out.println("Encoded: " + encodedStr);

        byte[] decoded = Base64.getDecoder().decode(encoded);
        System.out.println("Decoded: " + new String(decoded));

        // ── 2. Use HexFormat instead of internal hex utilities ─────────────
        System.out.println("\n=== HexFormat (Java 17, replaces internal hex utils) ===");
        HexFormat hex = HexFormat.of();
        byte[] bytes = { (byte) 0xDE, (byte) 0xAD, (byte) 0xBE, (byte) 0xEF };
        System.out.println("Hex: " + hex.formatHex(bytes));
        System.out.println("Upper: " + HexFormat.of().withUpperCase().formatHex(bytes));

        byte[] parsed = hex.parseHex("cafebabe");
        System.out.println("Parsed length: " + parsed.length);

        // ── 3. Management APIs instead of internal JVM APIs ───────────────
        System.out.println("\n=== Management MXBeans (public API) ===");
        MemoryMXBean memBean = ManagementFactory.getMemoryMXBean();
        System.out.println("Heap used: " +
            memBean.getHeapMemoryUsage().getUsed() / (1024 * 1024) + " MB");

        RuntimeMXBean runtimeBean = ManagementFactory.getRuntimeMXBean();
        System.out.println("JVM name: " + runtimeBean.getVmName());
        System.out.println("JVM version: " + runtimeBean.getVmVersion());
        System.out.println("Uptime: " + runtimeBean.getUptime() + "ms");

        // ── 4. Runtime.version() instead of sun.misc internals ─────────────
        System.out.println("\n=== Runtime.Version (Java 9+) ===");
        Runtime.Version version = Runtime.version();
        System.out.println("Feature: " + version.feature());
        System.out.println("Interim: " + version.interim());
        System.out.println("Update:  " + version.update());
        System.out.println("Patch:   " + version.patch());
        System.out.println("Full:    " + version);

        // ── 5. Demonstrating InaccessibleObjectException ───────────────────
        System.out.println("\n=== Encapsulation Enforcement ===");
        demonstrateEncapsulation();

        // ── 6. ProcessHandle instead of internal process utilities ─────────
        System.out.println("\n=== ProcessHandle (Java 9+, replaces internal APIs) ===");
        ProcessHandle current = ProcessHandle.current();
        System.out.println("PID: " + current.pid());
        current.info().command().ifPresent(cmd -> System.out.println("Command: " + cmd));
        current.info().user().ifPresent(user -> System.out.println("User: " + user));

        // ── 7. StackWalker instead of sun.reflect.Reflection ──────────────
        System.out.println("\n=== StackWalker (Java 9+, replaces sun.reflect) ===");
        demonstrateStackWalker();
    }

    static void demonstrateEncapsulation() {
        // Attempting to access a JDK internal class via reflection
        try {
            Class<?> unsafeClass = Class.forName("sun.misc.Unsafe");
            java.lang.reflect.Field field = unsafeClass.getDeclaredField("theUnsafe");
            field.setAccessible(true); // This throws InaccessibleObjectException in Java 17
            System.out.println("Accessed Unsafe (unexpected in Java 17+)");
        } catch (InaccessibleObjectException e) {
            System.out.println("Blocked (expected): " + e.getMessage().split("\n")[0]);
        } catch (ClassNotFoundException | NoSuchFieldException e) {
            System.out.println("Internal API not found: " + e.getClass().getSimpleName());
        }
    }

    static void demonstrateStackWalker() {
        StackWalker walker = StackWalker.getInstance(StackWalker.Option.RETAIN_CLASS_REFERENCE);

        List<String> frames = walker.walk(stream ->
            stream.limit(5)
                  .map(f -> f.getClassName() + "." + f.getMethodName() + ":" + f.getLineNumber())
                  .toList()
        );
        frames.forEach(f -> System.out.println("  " + f));

        // Caller class (replaces sun.reflect.Reflection.getCallerClass)
        Class<?> caller = walker.getCallerClass();
        System.out.println("Caller class: " + caller.getSimpleName());
    }
}
