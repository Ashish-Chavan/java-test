/**
 * A simple calculator object.
 * Provides basic arithmetic operations.
 */
object Calculator {
  // Adds two integers, but returns 0 if the result is negative.
  def add(a: Int, b: Int): Int = {
    val sum = a + b
    if (sum < 0) {
      0
    } else {
      sum
    }
  }
}
