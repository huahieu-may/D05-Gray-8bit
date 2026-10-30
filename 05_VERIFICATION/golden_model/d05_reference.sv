module d05_reference (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       enable,
    output logic [7:0] gray_ref
);
    logic [7:0] binary_state;

    always_ff @(posedge clk) begin
        if (!rst_n)
            binary_state <= 8'h00;
        else if (enable)
            binary_state <= binary_state + 8'd1;
    end

    always_comb begin
        gray_ref = binary_state ^ (binary_state >> 1);
    end
endmodule
