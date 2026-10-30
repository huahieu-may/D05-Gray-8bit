module d05_core (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       enable,
    output logic [7:0] gray_out
);
    logic [7:0] binary_state;
    logic [7:0] binary_next;

    always_comb begin
        binary_next = binary_state;
        if (enable)
            binary_next = binary_state + 8'd1;
    end

    always_ff @(posedge clk) begin
        if (!rst_n)
            binary_state <= 8'h00;
        else
            binary_state <= binary_next;
    end

    always_comb begin
        gray_out = binary_state ^ (binary_state >> 1);
    end
endmodule
