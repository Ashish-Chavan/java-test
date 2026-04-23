`ifndef TB_DEFS_SVH
`define TB_DEFS_SVH

// Typedef
typedef enum logic [1:0] {
    IDLE,
    START,
    STOP
} state_t;

// Function
function automatic int add(int a, int b);
    return a + b;
endfunction

// Class (SystemVerilog feature)
class packet;
    rand bit [7:0] data;

    function void display();
        $display("Packet data = %0h", data);
    endfunction
endclass

`endif
