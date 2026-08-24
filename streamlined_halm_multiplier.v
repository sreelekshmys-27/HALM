// ============================================================
// streamlined_halm_multiplier (TOP)
//
module streamlined_halm_multiplier (
    input  wire        clk,
    input  wire        reset,
    input  wire [15:0] operand_a,
    input  wire [15:0] operand_b,
    input  wire        start,
    output reg  [15:0] result,
    output reg          done,
    output reg  [7:0]  power_estimate
);

    // Internal signals
    wire [9:0] mantissa_a, mantissa_b;   // fractional fields x_a, x_b (see fix #1 above)
    wire [4:0] exponent_a, exponent_b;
    wire       sign_a, sign_b;
    wire [1:0] precision_level;
    wire [1:0] compensation_level;
    wire [10:0] log_result_a, log_result_b;  // Q0.11
    wire [11:0] log_sum;                      // Q1.11
    wire [16:0] antilog_result_ext;           // Q3.14, value in [1,4)
    wire [9:0] compressed_mantissa;
    wire       exp_adjust;
    wire [9:0] adjusted_mantissa;
    wire [5:0] final_exponent_comb;           // extra bit for adjust + overflow visibility
    wire final_sign;

    // State machine
    reg [2:0] state;
    localparam IDLE            = 3'b000;
    localparam ADAPTIVE        = 3'b001;
    localparam LOGARITHMIC     = 3'b010;
    localparam ADDITION        = 3'b011;
    localparam ANTILOGARITHMIC = 3'b100;
    localparam POST_PROCESS    = 3'b101;
    localparam COMPLETE        = 3'b110;

    // Field extraction
    assign sign_a     = operand_a[15];
    assign sign_b     = operand_b[15];
    assign exponent_a = operand_a[14:10];
    assign exponent_b = operand_b[14:10];
    assign mantissa_a = operand_a[9:0];   // fix #1: fractional field, not {1,x}
    assign mantissa_b = operand_b[9:0];   // fix #1

    // Adaptive processing stage
    adaptive_processing_stage adaptive_stage (
        .clk(clk), .reset(reset),
        .mantissa_a(mantissa_a), .mantissa_b(mantissa_b),
        .exponent_a(exponent_a), .exponent_b(exponent_b),
        .precision_level(precision_level),
        .compensation_level(compensation_level)
    );

    // Logarithmic approximation stage
    logarithmic_approximation_stage log_stage (
        .clk(clk), .reset(reset),
        .mantissa_a(mantissa_a), .mantissa_b(mantissa_b),
        .precision_level(precision_level),
        .log_result_a(log_result_a), .log_result_b(log_result_b)
    );

    // Addition stage (combinational; result is registered into log_sum
    // implicitly by being sampled combinationally into the next stage's
    // registered inputs -- see antilogarithmic_approximation_stage)
    assign log_sum = {1'b0, log_result_a} + {1'b0, log_result_b};

    // Antilogarithmic approximation stage
    antilogarithmic_approximation_stage antilog_stage (
        .clk(clk), .reset(reset),
        .log_sum(log_sum),
        .precision_level(precision_level),
        .antilog_result_ext(antilog_result_ext)
    );

    // Post-processing stage
    post_processing_stage post_stage (
        .clk(clk), .reset(reset),
        .antilog_result_ext(antilog_result_ext),
        .compensation_level(compensation_level),
        .compressed_mantissa(compressed_mantissa),
        .exp_adjust(exp_adjust),
        .adjusted_mantissa(adjusted_mantissa)
    );

    // Result assembly
    assign final_sign = sign_a ^ sign_b;
    // fix #2: include exp_adjust; bias subtraction for FP16 bias=15
    assign final_exponent_comb = {1'b0, exponent_a} + {1'b0, exponent_b} - 6'd15 + {5'b0, exp_adjust};

    // Main control logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state          <= IDLE;
            done           <= 1'b0;
            result         <= 16'b0;
            power_estimate <= 8'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start)
                        state <= ADAPTIVE;
                end

                ADAPTIVE:        state <= LOGARITHMIC;
                LOGARITHMIC:     state <= ADDITION;
                ADDITION:        state <= ANTILOGARITHMIC;
                ANTILOGARITHMIC: state <= POST_PROCESS;
                POST_PROCESS:    state <= COMPLETE;

                COMPLETE: begin
                    // fix #3: pack the full 10-bit mantissa (1+5+10=16 bits)
                    result         <= {final_sign, final_exponent_comb[4:0], adjusted_mantissa};
                    done           <= 1'b1;
                    power_estimate <= get_power_estimate(precision_level);
                    state          <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

    // Placeholder relative power indicator -- see NOTE at top of file.
    function [7:0] get_power_estimate;
        input [1:0] precision;
        case (precision)
            2'b00: get_power_estimate = 8'd7;   // LOW
            2'b01: get_power_estimate = 8'd12;  // MEDIUM
            2'b10: get_power_estimate = 8'd18;  // HIGH
            2'b11: get_power_estimate = 8'd25;  // ULTRA_HIGH
        endcase
    endfunction

endmodule
