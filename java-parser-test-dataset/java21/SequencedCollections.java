/**
 * Java 21 Feature: Sequenced Collections (JEP 431)
 * New interfaces SequencedCollection, SequencedSet, SequencedMap
 * add first/last element access and reversed-view methods to
 * the Java Collections Framework.
 */
import java.util.*;

public class SequencedCollections {

    public static void main(String[] args) {

        // ── SequencedCollection: List ──────────────────────────────────────
        System.out.println("=== List as SequencedCollection ===");
        List<String> list = new ArrayList<>(List.of("alpha", "beta", "gamma", "delta"));

        // New methods: getFirst(), getLast(), addFirst(), addLast(), removeFirst(), removeLast()
        System.out.println("First: " + list.getFirst());
        System.out.println("Last:  " + list.getLast());

        list.addFirst("zeta");
        list.addLast("omega");
        System.out.println("After addFirst/addLast: " + list);

        String removed = list.removeFirst();
        System.out.println("Removed first: " + removed + ", list: " + list);

        // reversed() returns a view in reverse order
        SequencedCollection<String> reversed = list.reversed();
        System.out.println("Reversed view: " + reversed);
        System.out.println("First of reversed == Last of original: " +
            reversed.getFirst().equals(list.getLast()));

        // ── SequencedCollection: Deque ─────────────────────────────────────
        System.out.println("\n=== Deque as SequencedCollection ===");
        Deque<Integer> deque = new ArrayDeque<>(List.of(10, 20, 30, 40, 50));

        System.out.println("First: " + deque.getFirst());
        System.out.println("Last:  " + deque.getLast());

        deque.addFirst(5);
        deque.addLast(55);
        System.out.println("After adds: " + deque);

        for (Integer i : deque.reversed()) {
            System.out.print(i + " ");
        }
        System.out.println();

        // ── SequencedSet: LinkedHashSet ────────────────────────────────────
        System.out.println("\n=== LinkedHashSet as SequencedSet ===");
        SequencedSet<String> seqSet = new LinkedHashSet<>(
            List.of("apple", "banana", "cherry", "date")
        );

        System.out.println("First: " + seqSet.getFirst());
        System.out.println("Last:  " + seqSet.getLast());

        seqSet.addFirst("avocado");    // moves to front or stays if already present
        seqSet.addLast("elderberry");
        System.out.println("Set: " + seqSet);
        System.out.println("Reversed set: " + seqSet.reversed());

        // ── SequencedMap: LinkedHashMap ────────────────────────────────────
        System.out.println("\n=== LinkedHashMap as SequencedMap ===");
        SequencedMap<String, Integer> seqMap = new LinkedHashMap<>();
        seqMap.put("one",   1);
        seqMap.put("two",   2);
        seqMap.put("three", 3);
        seqMap.put("four",  4);

        // firstEntry() and lastEntry()
        Map.Entry<String, Integer> first = seqMap.firstEntry();
        Map.Entry<String, Integer> last  = seqMap.lastEntry();
        System.out.println("First entry: " + first.getKey() + "=" + first.getValue());
        System.out.println("Last entry:  " + last.getKey()  + "=" + last.getValue());

        // putFirst() and putLast()
        seqMap.putFirst("zero", 0);
        seqMap.putLast("five", 5);
        System.out.println("After putFirst/putLast: " + seqMap);

        // pollFirstEntry() and pollLastEntry()
        Map.Entry<String, Integer> polledFirst = seqMap.pollFirstEntry();
        Map.Entry<String, Integer> polledLast  = seqMap.pollLastEntry();
        System.out.println("Polled first: " + polledFirst);
        System.out.println("Polled last:  " + polledLast);
        System.out.println("Map after polling: " + seqMap);

        // reversed() view of map
        SequencedMap<String, Integer> reversedMap = seqMap.reversed();
        System.out.println("Reversed map: " + reversedMap);
        System.out.println("First of reversed: " + reversedMap.firstEntry());

        // ── TreeMap also has sequenced access ──────────────────────────────
        System.out.println("\n=== TreeMap as SequencedMap ===");
        SequencedMap<Integer, String> treeMap = new TreeMap<>(Map.of(
            3, "three", 1, "one", 4, "four", 2, "two"
        ));
        System.out.println("First: " + treeMap.firstEntry());
        System.out.println("Last:  " + treeMap.lastEntry());
        System.out.println("Reversed: " + treeMap.reversed());

        // ── Practical use: history/LRU-style access ────────────────────────
        System.out.println("\n=== Practical: Recent Command History ===");
        SequencedCollection<String> history = new ArrayDeque<>();
        String[] commands = {"ls", "cd /tmp", "mkdir test", "vim file.txt", "git status"};
        for (String cmd : commands) {
            history.addLast(cmd);
            if (history.size() > 3) history.removeFirst(); // keep last 3
        }
        System.out.println("Last 3 commands: " + history);
        System.out.println("Most recent: " + history.getLast());
    }
}
