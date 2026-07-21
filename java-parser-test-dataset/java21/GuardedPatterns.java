/**
 * Java 21 Feature: Guarded Patterns with 'when' (JEP 441)
 * Pattern cases in switch can have a guard clause: case Type t when condition
 * This replaces the old &&-in-instanceof pattern with cleaner switch syntax.
 */
import java.util.List;

public class GuardedPatterns {

    sealed interface Payment permits Payment.Cash, Payment.Card, Payment.Crypto {}

    record Payment() {
        record Cash(double amount)                                  implements Payment {}
        record Card(String last4, double amount, boolean contactless) implements Payment {}
        record Crypto(String coin, double amount, String wallet)    implements Payment {}
    }

    sealed interface Event permits Login, Purchase, Refund, Suspension {}
    record Login(String userId, String ipAddress, boolean success) implements Event {}
    record Purchase(String userId, double amount, String item)     implements Event {}
    record Refund(String userId, double amount, String reason)     implements Event {}
    record Suspension(String userId, String reason)                implements Event {}

    public static void main(String[] args) {

        // ── Guarded patterns in switch ─────────────────────────────────────
        Payment[] payments = {
            new Payment.Cash(50.0),
            new Payment.Cash(1200.0),
            new Payment.Card("4242", 99.99, true),
            new Payment.Card("1234", 5000.0, false),
            new Payment.Crypto("BTC", 0.005, "bc1qxy2kgdygjrsqtzq2n"),
            new Payment.Crypto("ETH", 10.0, "0xAbCd")
        };

        for (Payment p : payments) {
            System.out.println(classifyPayment(p));
        }

        // ── Guarded patterns with multiple conditions ──────────────────────
        System.out.println("\n--- Event Processing ---");
        List<Event> events = List.of(
            new Login("u001", "192.168.1.1", true),
            new Login("u002", "10.0.0.1", false),
            new Login("u003", "185.220.101.5", false),  // suspicious IP
            new Purchase("u001", 29.99, "Book"),
            new Purchase("u004", 15000.0, "Laptop"),    // high-value
            new Refund("u001", 29.99, "Wrong item"),
            new Refund("u005", 5000.0, "Fraud"),        // high-value refund
            new Suspension("u002", "Too many failed logins")
        );
        events.forEach(e -> System.out.println(processEvent(e)));

        // ── Guarded pattern in if-else ─────────────────────────────────────
        System.out.println("\n--- Grade Classification ---");
        int[] scores = { 98, 85, 72, 65, 55, 40 };
        for (int score : scores) {
            System.out.println("Score " + score + " -> " + grade(score));
        }
    }

    static String classifyPayment(Payment payment) {
        return switch (payment) {
            // Cash payments: small vs large
            case Payment.Cash c when c.amount() <= 100  -> "Small cash: $" + c.amount();
            case Payment.Cash c when c.amount() <= 500  -> "Medium cash: $" + c.amount();
            case Payment.Cash c                          -> "Large cash (flag): $" + c.amount();

            // Card: contactless small vs regular vs high-value
            case Payment.Card c when c.contactless() && c.amount() < 50
                -> "Contactless tap: $" + c.amount() + " (card *" + c.last4() + ")";
            case Payment.Card c when c.amount() > 1000
                -> "HIGH-VALUE card payment: $" + c.amount() + " (card *" + c.last4() + ") - REVIEW";
            case Payment.Card c
                -> "Card payment: $" + c.amount() + " (card *" + c.last4() + ")";

            // Crypto: known coins vs unknown
            case Payment.Crypto cr when cr.coin().equals("BTC") || cr.coin().equals("ETH")
                -> "Crypto (" + cr.coin() + "): " + cr.amount();
            case Payment.Crypto cr
                -> "Unknown crypto (" + cr.coin() + ") - VERIFY";
        };
    }

    static String processEvent(Event event) {
        return switch (event) {
            case Login l when l.success()
                -> "[INFO]  Login OK: " + l.userId() + " from " + l.ipAddress();
            case Login l when l.ipAddress().startsWith("185.")
                -> "[ALERT] Suspicious login attempt: " + l.userId() + " from " + l.ipAddress();
            case Login l
                -> "[WARN]  Failed login: " + l.userId() + " from " + l.ipAddress();

            case Purchase p when p.amount() > 10_000
                -> "[ALERT] High-value purchase: " + p.userId() + " $" + p.amount() + " - " + p.item();
            case Purchase p
                -> "[INFO]  Purchase: " + p.userId() + " $" + p.amount() + " - " + p.item();

            case Refund r when r.amount() > 1000 || r.reason().equalsIgnoreCase("fraud")
                -> "[ALERT] Suspicious refund: " + r.userId() + " $" + r.amount() + " (" + r.reason() + ")";
            case Refund r
                -> "[INFO]  Refund: " + r.userId() + " $" + r.amount();

            case Suspension s
                -> "[ACTION] Account suspended: " + s.userId() + " - " + s.reason();
        };
    }

    static String grade(int score) {
        return switch (score) {
            case int s when s >= 90 -> "A";
            case int s when s >= 80 -> "B";
            case int s when s >= 70 -> "C";
            case int s when s >= 60 -> "D";
            default                 -> "F";
        };
    }
}
