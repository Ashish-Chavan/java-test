/**
 * Java 21 Feature: Virtual Threads - Finalized (JEP 444)
 * Virtual threads are lightweight threads managed by the JVM, not the OS.
 * They enable high-throughput concurrent applications without reactive
 * programming complexity. Millions of virtual threads can coexist.
 */
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.*;
import java.util.stream.IntStream;

public class VirtualThreads {

    public static void main(String[] args) throws Exception {
        basicVirtualThread();
        threadPerTaskExecutor();
        millionVirtualThreads();
        structuredConcurrency();
        virtualVsPlatformComparison();
    }

    // ── Basic virtual thread creation ──────────────────────────────────────
    static void basicVirtualThread() throws InterruptedException {
        System.out.println("=== Basic Virtual Threads ===");

        // Option 1: Thread.ofVirtual()
        Thread vThread = Thread.ofVirtual()
            .name("my-virtual-thread")
            .start(() -> {
                System.out.println("Running in: " + Thread.currentThread());
                System.out.println("Is virtual: " + Thread.currentThread().isVirtual());
            });
        vThread.join();

        // Option 2: Thread.startVirtualThread()
        Thread t = Thread.startVirtualThread(() ->
            System.out.println("Quick virtual thread: " + Thread.currentThread().isVirtual())
        );
        t.join();

        // Option 3: Thread.ofVirtual().unstarted() for deferred start
        Thread unstarted = Thread.ofVirtual()
            .name("deferred")
            .unstarted(() -> System.out.println("Deferred start"));
        unstarted.start();
        unstarted.join();
    }

    // ── ExecutorService with virtual thread-per-task ───────────────────────
    static void threadPerTaskExecutor() throws InterruptedException {
        System.out.println("\n=== Virtual Thread Executor ===");

        // newVirtualThreadPerTaskExecutor: each task gets its own virtual thread
        try (ExecutorService executor = Executors.newVirtualThreadPerTaskExecutor()) {
            List<Future<String>> futures = new ArrayList<>();

            for (int i = 0; i < 10; i++) {
                int taskId = i;
                futures.add(executor.submit(() -> {
                    // Simulate I/O (blocking is fine with virtual threads)
                    Thread.sleep(Duration.ofMillis(50));
                    return "Task " + taskId + " done on " + Thread.currentThread();
                }));
            }

            for (Future<String> f : futures) {
                try {
                    System.out.println(f.get());
                } catch (ExecutionException e) {
                    System.out.println("Error: " + e.getCause().getMessage());
                }
            }
        }
    }

    // ── Launching a million virtual threads (not possible with platform threads) ──
    static void millionVirtualThreads() throws Exception {
        System.out.println("\n=== One Million Virtual Threads ===");

        int count = 100_000; // using 100k for demo (1M works the same way)
        CountDownLatch latch = new CountDownLatch(count);
        Instant start = Instant.now();

        try (ExecutorService executor = Executors.newVirtualThreadPerTaskExecutor()) {
            IntStream.range(0, count).forEach(_ ->
                executor.submit(() -> {
                    latch.countDown();
                    // Each thread does minimal work — virtual threads have tiny footprint
                    return Thread.currentThread().isVirtual();
                })
            );
        }

        latch.await();
        Duration elapsed = Duration.between(start, Instant.now());
        System.out.printf("Launched %,d virtual threads in %dms%n", count, elapsed.toMillis());
    }

    // ── Structured Concurrency (preview in 21) ─────────────────────────────
    static void structuredConcurrency() throws Exception {
        System.out.println("\n=== Structured Concurrency Preview ===");

        // Virtual threads integrate naturally with structured concurrency
        try (ExecutorService scope = Executors.newVirtualThreadPerTaskExecutor()) {
            Future<String> userFuture  = scope.submit(() -> fetchUser(1));
            Future<String> orderFuture = scope.submit(() -> fetchOrders(1));

            // Both run concurrently on virtual threads
            String user   = userFuture.get();
            String orders = orderFuture.get();
            System.out.println("User: " + user);
            System.out.println("Orders: " + orders);
        }
    }

    // ── Virtual vs Platform thread comparison ─────────────────────────────
    static void virtualVsPlatformComparison() throws Exception {
        System.out.println("\n=== Virtual vs Platform Thread Properties ===");

        Thread platform = new Thread(() -> {}, "platform");
        Thread virtual  = Thread.ofVirtual().name("virtual").unstarted(() -> {});

        System.out.println("Platform thread:");
        System.out.println("  name:      " + platform.getName());
        System.out.println("  isVirtual: " + platform.isVirtual());
        System.out.println("  isDaemon:  " + platform.isDaemon());

        System.out.println("Virtual thread:");
        System.out.println("  name:      " + virtual.getName());
        System.out.println("  isVirtual: " + virtual.isVirtual());
        System.out.println("  isDaemon:  " + virtual.isDaemon()); // always daemon

        // ThreadFactory for virtual threads
        ThreadFactory factory = Thread.ofVirtual().name("worker-", 0).factory();
        Thread w1 = factory.newThread(() -> {});
        Thread w2 = factory.newThread(() -> {});
        System.out.println("Factory threads: " + w1.getName() + ", " + w2.getName());
    }

    // Simulated I/O-bound operations (blocking is fine with virtual threads)
    static String fetchUser(int id) throws InterruptedException {
        Thread.sleep(Duration.ofMillis(100)); // simulate DB call
        return "User{id=" + id + ", name=Alice}";
    }

    static String fetchOrders(int id) throws InterruptedException {
        Thread.sleep(Duration.ofMillis(80)); // simulate HTTP call
        return "Orders{userId=" + id + ", count=3}";
    }
}
