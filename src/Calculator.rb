# A calculator built to handle errors and invalid input.
class RobustCalculator
  # A single method to perform an operation.
  def calculate(a, b, operator)
    begin
      # First, check if inputs are numeric using an if/else statement.
      unless a.is_a?(Numeric) && b.is_a?(Numeric)
        # Raise a custom error if they are not numbers.
        raise TypeError, "Both inputs must be numbers."
      end

      # Use if/elsif/else to determine which operation to perform.
      if operator == '+'
        a + b
      elsif operator == '-'
        a - b
      elsif operator == '/'
        # A nested 'if' to explicitly check for zero before division.
        raise ZeroDivisionError, "Cannot divide by zero." if b.zero?
        a.to_f / b
      else
        "Unknown operator: '#{operator}'" # Handle unknown operators.
      end
      
    rescue TypeError => e
      "Error: #{e.message}"
    rescue ZeroDivisionError => e
      "Error: #{e.message}"
    end
  end
end
