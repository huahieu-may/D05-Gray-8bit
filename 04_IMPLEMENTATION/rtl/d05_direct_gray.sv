module d05_direct_gray (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       enable,
    output logic [7:0] gray_out,
    output logic [7:0] binary_out
);
    logic [7:0] next_gray;
    logic [7:0] binary_value;
    logic [7:0] binary_next;
    integer i;

    always_comb begin
        binary_value[7] = gray_out[7];

        for (i = 6; i >= 0; i = i - 1)
            binary_value[i] = binary_value[i+1] ^ gray_out[i];

        binary_next = binary_value;
        if (enable)
            binary_next = binary_value + 8'd1;

        next_gray = binary_next ^ (binary_next >> 1);
    end

    always_ff @(posedge clk) begin
        if (!rst_n)
            gray_out <= 8'h00;
        else
            gray_out <= next_gray;
    end

    assign binary_out = binary_value;
endmodule