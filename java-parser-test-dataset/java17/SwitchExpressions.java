/**
 * Java 17 Feature: Switch Expressions - Stable (JEP 361, finalized Java 14)
 * Java 17 is the LTS where switch expressions are fully stable.
 * Key syntax: arrow cases (->), yield, multi-label cases.
 */
public class SwitchExpressions {

    enum Day { MON, TUE, WED, THU, FRI, SAT, SUN }
    enum Season { SPRING, SUMMER, AUTUMN, WINTER }

    sealed interface Coin permits Penny, Nickel, Dime, Quarter {}
    record Penny()   implements Coin {}
    record Nickel()  implements Coin {}
    record Dime()    implements Coin {}
    record Quarter() implements Coin {}

    public static void main(String[] args) {

        // ── Arrow-case switch expression ───────────────────────────────────
        for (Day day : Day.values()) {
            String type = switch (day) {
                case MON, TUE, WED, THU, FRI -> "Weekday";
                case SAT, SUN                 -> "Weekend";
            };
            System.out.println(day + " -> " + type);
        }

        // ── Switch expression with yield ───────────────────────────────────
        Day today = Day.WED;
        int hoursOfWork = switch (today) {
            case MON, TUE, WED, THU, FRI -> 8;
            case SAT -> {
                System.out.println("Half day Saturday");
                yield 4;
            }
            case SUN -> {
                System.out.println("Day off");
                yield 0;
            }
        };
        System.out.println("Hours of work: " + hoursOfWork);

        // ── Switch expression returning computed value ──────────────────────
        for (Season season : Season.values()) {
            String activity = switch (season) {
                case SPRING -> "Hiking";
                case SUMMER -> "Swimming";
                case AUTUMN -> "Apple picking";
                case WINTER -> "Skiing";
            };
            System.out.println(season + " -> " + activity);
        }

        // ── Switch statement with arrow cases (no fall-through) ────────────
        int code = 404;
        switch (code) {
            case 200 -> System.out.println("OK");
            case 201 -> System.out.println("Created");
            case 400 -> System.out.println("Bad Request");
            case 401 -> System.out.println("Unauthorized");
            case 404 -> System.out.println("Not Found");
            case 500 -> System.out.println("Internal Server Error");
            default  -> System.out.println("Unknown code: " + code);
        }

        // ── Switch on String ───────────────────────────────────────────────
        String[] commands = {"start", "stop", "restart", "status", "unknown"};
        for (String cmd : commands) {
            int exitCode = switch (cmd) {
                case "start"   -> startService();
                case "stop"    -> stopService();
                case "restart" -> { stopService(); yield startService(); }
                case "status"  -> checkStatus();
                default        -> { System.out.println("Unknown: " + cmd); yield -1; }
            };
            System.out.println(cmd + " -> exit code " + exitCode);
        }

        // ── Switch on sealed type (preview of pattern switch) ──────────────
        Coin[] coins = { new Penny(), new Nickel(), new Dime(), new Quarter() };
        int total = 0;
        for (Coin coin : coins) {
            int value = coinValue(coin);
            total += value;
            System.out.println(coin.getClass().getSimpleName() + " = " + value + "¢");
        }
        System.out.println("Total: " + total + "¢");
    }

    static int startService()  { System.out.print("Starting... "); return 0; }
    static int stopService()   { System.out.print("Stopping... "); return 0; }
    static int checkStatus()   { System.out.print("Running... ");  return 0; }

    static int coinValue(Coin coin) {
        if (coin instanceof Penny)   return 1;
        if (coin instanceof Nickel)  return 5;
        if (coin instanceof Dime)    return 10;
        if (coin instanceof Quarter) return 25;
        throw new IllegalArgumentException();
    }
}
