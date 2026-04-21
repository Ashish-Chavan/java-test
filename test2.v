// ==========================================================
// Simple Verilog Test File: 8-bit Accumulator
// ==========================================================

module simple_adder (
    input  wire [7:0] data_in,
    input  wire       clk,
    input  wire       reset,
    output reg  [7:0] sum
);

    // Internal wire for combinatorial result
    wire [7:0] next_sum;

    // Combinatorial Logic: NOM Hit 1
    // CYCLO: Base (1)
    assign next_sum = sum + data_in;

    // Sequential Logic: NOM Hit 2
    // CYCLO: Base(1) + If(1) = 2
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sum <= 8'b00000000;
        end else begin
            sum <= next_sum;
        end
    end

endmodule
