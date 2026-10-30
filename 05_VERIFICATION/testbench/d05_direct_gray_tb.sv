`timescale 1ns/1ps

module d05_direct_gray_tb;
    logic clk = 0;
    logic rst_n = 0;
    logic enable = 0;

    wire [7:0] gray_out, binary_out;

    reg [7:0] expected_binary = 0;
    reg [255:0] seen_gray;

    integer checks = 0;
    integer gray_checks = 0;
    integer i;

    d05_direct_gray dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .gray_out(gray_out),
        .binary_out(binary_out)
    );

    always #5 clk = ~clk;

    // Dem so bit 1.
    function automatic integer popcount8(input [7:0] x);
        integer k;
        begin
            popcount8 = 0;
            for (k = 0; k < 8; k = k + 1)
                popcount8 = popcount8 + x[k];
        end
    endfunction

    // Giai ma Gray ve nhi phan de doi chieu.
    function automatic [7:0] decode_gray(input [7:0] g);
        integer k;
        begin
            decode_gray[7] = g[7];
            for (k = 6; k >= 0; k = k - 1)
                decode_gray[k] = decode_gray[k+1] ^ g[k];
        end
    endfunction

    task automatic tick(
        input bit reset_value,
        input bit enable_value
    );
        reg [7:0] previous_gray;
        begin
            @(negedge clk);
            previous_gray = gray_out;
            rst_n = reset_value;
            enable = enable_value;

            if (!reset_value)
                expected_binary = 0;
            else if (enable_value)
                expected_binary = expected_binary + 8'd1;

            @(posedge clk);
            #1;
            checks = checks + 1;

            if (binary_out !== expected_binary)
                $fatal(1, "Sai binary: got=%0d expected=%0d",
                       binary_out, expected_binary);

            if (decode_gray(gray_out) !== expected_binary)
                $fatal(1, "Sai Gray: gray=%02h binary=%0d",
                       gray_out, expected_binary);

            if (reset_value && enable_value) begin
                if (popcount8(gray_out ^ previous_gray) !== 1)
                    $fatal(1, "Gray doi khac 1 bit: %02h -> %02h",
                           previous_gray, gray_out);

                gray_checks = gray_checks + 1;
            end

            if (reset_value && !enable_value &&
                gray_out !== previous_gray)
                $fatal(1, "Enable=0 nhung Gray van thay doi");
        end
    endtask

    initial begin
        $dumpfile("d05_direct_wave.vcd");
        $dumpvars(0, d05_direct_gray_tb);

        repeat (2) tick(0, 0);
        repeat (2) tick(1, 0);

        // Kiem du 256 buoc, gom ca quay vong.
        seen_gray = 0;
        seen_gray[gray_out] = 1;

        for (i = 1; i <= 256; i = i + 1) begin
            tick(1, 1);

            if (i < 256) begin
                if (seen_gray[gray_out])
                    $fatal(1, "Chuoi Gray lap som tai buoc %0d", i);

                seen_gray[gray_out] = 1;
            end
        end

        if (seen_gray !== {256{1'b1}} || binary_out !== 8'd0)
            $fatal(1, "Chua phu du 256 trang thai");

        $display("PASS: du 256 buoc va quay vong 255 -> 0");

        // Dung tai 255, giu 3 nhip, sau do dem tiep.
        repeat (255) tick(1, 1);
        repeat (3) tick(1, 0);
        tick(1, 1);
        $display("PASS: giu dem tai 255 va dem tiep");

        // Reset giua chung, reset uu tien hon enable.
        repeat (37) tick(1, 1);
        tick(0, 1);
        tick(1, 0);
        $display("PASS: reset giua chung");

        // Bat/tat enable xen ke.
        for (i = 0; i < 20; i = i + 1)
            tick(1, (i % 2) == 0);

        $display("PASS: enable xen ke");

        $display(
            "D05 PASS: %0d lan kiem, %0d buoc Gray doi dung 1 bit",
            checks, gray_checks
        );

        $finish;
    end
endmodule
