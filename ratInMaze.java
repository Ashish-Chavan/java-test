// Java Program to find all paths for a rat in a maze
// from source (0,0) to destination (n-1, n-1)

import java.util.*;

 class GfG {

    static String dir = "DLRU";
    static int[] dr = {1, 0, 0, -1};
    static int[] dc = {0, -1, 1, 0};

    // Check if a cell is valid (inside the maze and open)
    static boolean isValid(int r, int c, int n, int[][] maze) {
        return r >= 0 && c >= 0 && r < n && c < n && maze[r][c] == 1;
    }

    // Function to find all valid paths
    static void findPath(int r, int c, int[][] maze, String path,
                                    ArrayList<String> res) {
        int n = maze.length;

        // If destination is reached, store the path
        if (r == n - 1 && c == n - 1) {
            res.add(path);
            return;
        }

        // Mark current cell as blocked
        maze[r][c] = 0;

        for (int i = 0; i < 4; i++) {
            int nr = r + dr[i], nc = c + dc[i];
            if (isValid(nr, nc, n, maze)) {
                findPath(nr, nc, maze, path + dir.charAt(i), res);
            }
        }

        // Unmark current cell
        maze[r][c] = 1;  
    }

    // Function to find all paths and return them
    static ArrayList<String> ratInMaze(int[][] maze) {
        ArrayList<String> result = new ArrayList<>();
        int n = maze.length;
        String path = "";

        if (maze[0][0] != 0 && maze[n - 1][n - 1] != 0) {
            findPath(0, 0, maze, path, result);
        }

        return result;
    }

    public static void main(String[] args) {
        int[][] maze = {
            {1, 0, 0, 0},
            {1, 1, 0, 1},
            {1, 1, 0, 0},
            {0, 1, 1, 1}
        };

        ArrayList<String> result = ratInMaze(maze);

        if (result.isEmpty()) {
            System.out.println(-1);
        } else {
            for (String p : result) {
                System.out.print(p + " ");
            }
            System.out.println();
        }
    }
}
