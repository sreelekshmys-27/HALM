`timescale 1ns/1ps


module tb_streamlined_halm_multiplier;

    reg clk;
    reg reset;
    reg start;
    reg [15:0] operand_a;
    reg [15:0] operand_b;

    wire [15:0] result;
    wire done;
    wire [7:0] power_estimate;

    streamlined_halm_multiplier DUT (
        .clk(clk),
        .reset(reset),
        .operand_a(operand_a),
        .operand_b(operand_b),
        .start(start),
        .result(result),
        .done(done),
        .power_estimate(power_estimate)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("halm.vcd");
        $dumpvars(0, tb_streamlined_halm_multiplier);
    end

    function real fp16_to_real;
        input [15:0] fp;
        reg sign;
        reg [4:0] exp;
        reg [10:0] mant;
        real val;
        begin
            if (fp == 16'b0) begin
                fp16_to_real = 0.0;
            end else begin
                sign = fp[15];
                exp  = fp[14:10];
                mant = {1'b1, fp[9:0]};

                val = mant / 1024.0;
                val = val * (2.0 ** (exp - 15));

                if (sign) val = -val;
                fp16_to_real = val;
            end
        end
    endfunction

    real total_ed, total_red;
    real total_abs_ed, total_abs_red;
    real MED, MRED, MAED, MARED;
    integer count;

    reg [15:0] prev_result;
    integer toggle_count;

    always @(posedge clk) begin
        toggle_count = toggle_count + $countones(result ^ prev_result);
        prev_result = result;
    end

    task compute_error;
        input real exact, approx;
        real ed, red;
        begin
            ed  = exact - approx;
            red = (exact != 0) ? ed / exact : 0;

            total_ed      = total_ed + ed;
            total_red     = total_red + red;
            total_abs_ed  = total_abs_ed + (ed < 0 ? -ed : ed);
            total_abs_red = total_abs_red + (red < 0 ? -red : red);

            count = count + 1;
        end
    endtask

    task apply_test;
        input [15:0] a, b;
        real real_a, real_b, exact, approx;
        integer wait_cycles;
        begin
            @(posedge clk);
            operand_a = a;
            operand_b = b;
            start = 1;

            @(posedge clk);
            start = 0;

            // Bounded wait to avoid hanging the simulation if `done`
            // is never asserted (e.g. a wiring bug) -- 6-stage
            // pipeline should complete within ~10 cycles.
            wait_cycles = 0;
            while (!done && wait_cycles < 50) begin
                @(posedge clk);
                wait_cycles = wait_cycles + 1;
            end

            if (!done) begin
                $display("TIMEOUT waiting for done: A=%h B=%h", a, b);
            end else begin
                real_a = fp16_to_real(a);
                real_b = fp16_to_real(b);
                exact  = real_a * real_b;
                approx = fp16_to_real(result);

                compute_error(exact, approx);

                $display("TIME=%0t | A=%h B=%h | Exact=%f Approx=%f | Error=%f | PowerLvlProxy=%d",
                         $time, a, b, exact, approx, exact-approx, power_estimate);
            end

            @(posedge clk);
        end
    endtask

    initial begin
        clk = 0;
        reset = 1;
        start = 0;
        operand_a = 0;
        operand_b = 0;

        total_ed = 0;
        total_red = 0;
        total_abs_ed = 0;
        total_abs_red = 0;
        count = 0;
        toggle_count = 0;
        prev_result = 0;

        #20 reset = 0;

        // Directed tests
        apply_test(16'h3C00, 16'h4000); // 1 * 2
        apply_test(16'h4000, 16'h4000); // 2 * 2
        apply_test(16'h4200, 16'h3800); // 3 * 0.5
        apply_test(16'hC000, 16'h4000); // -2 * 2
        apply_test(16'h0000, 16'h3C00); // zero case
        apply_test(16'h7BFF, 16'h0400); // extreme values

        // Random tests
        repeat (200) begin
            apply_test($random, $random);
        end

        if (count > 0) begin
            MED   = total_ed / count;
            MRED  = total_red / count;
            MAED  = total_abs_ed / count;
            MARED = total_abs_red / count;
        end else begin
            MED = 0; MRED = 0; MAED = 0; MARED = 0;
        end

        $display("\n========= FINAL RESULTS =========");
        $display("TOTAL TESTS = %0d", count);
        $display("MED   = %e", MED);
        $display("MRED  = %e", MRED);
        $display("MAED  = %e", MAED);
        $display("MARED = %e", MARED);
        $display("Toggle Count (activity proxy, NOT power) = %0d", toggle_count);
        $display("=================================\n");

        #50;
        $finish;
    end

endmodule
