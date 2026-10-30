module d05_core_tb;
    logic clk, rst_n, enable;
    logic [7:0] gray_out;
    logic [7:0] gray_ref;

    d05_core dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .gray_out(gray_out)
    );

    d05_reference ref_i (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .gray_ref(gray_ref)
    );

    always #5 clk = ~clk;

    function automatic integer popcount8(input logic [7:0] x);
        integer k;
        begin
            popcount8 = 0;
            for (k = 0; k < 8; k = k + 1)
                popcount8 = popcount8 + x[k];
        end
    endfunction

    task automatic check;
        begin
            @(posedge clk);
            #1;
            assert(gray_out === gray_ref)
                else $fatal(1, "Mismatch: got=%02h ref=%02h", gray_out, gray_ref);
        end
    endtask

    initial begin
        clk = 0;
        rst_n = 0;
        enable = 0;

        repeat (2) check();

        rst_n = 1;
        check();

        // Hold.
        repeat (2) check();

        // Enable and inspect a complete 256-state cycle.
        enable = 1;

        // The first check observes Gray(1).
        check();

        repeat (254) check();

        // One more edge reaches Gray(0) after rollover.
        check();

        // Explicit local transition checks are performed by the Python exhaustive model.
        $display("D05 core verification PASS");
        $finish;
    end
endmodule
