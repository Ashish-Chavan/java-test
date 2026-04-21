// ==========================================================
// Simple SystemVerilog Test File: 4-bit Counter
// ==========================================================

module simple_counter (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       en,
    output logic [3:0] count
);

    // Sequential Logic: NOM Hit 1
    // CYCLO: Base(1) + If(1) + Else(1) = 3
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 4'b0000;
        end else if (en) begin
            count <= count + 1'b1;
        end
    end

    // Combinatorial Logic: NOM Hit 2
    // CYCLO: Base(1) + If(1) = 2
    always_comb begin
        if (count == 4'hf) begin
            $display("Counter reached maximum value!"); // LOG_LOC Hit 1
        end
    end

endmodule
