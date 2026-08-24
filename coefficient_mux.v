// ============================================================
// coefficient_mux  (LOG side)
// 16-segment piecewise-linear approximation of log2(1+x), x in [0,1).
//

// ============================================================
module coefficient_mux (
    input  wire [3:0] segment_address,
    input  wire [1:0] precision_level,
    output reg  [15:0] slope,
    output reg  [15:0] intercept
);

    always @(*) begin
        case (segment_address)
            4'h0: begin slope = 16'h5990; intercept = 16'h0000; end // m=1.3994 c=0.0000
            4'h1: begin slope = 16'h5471; intercept = 16'h0599; end // m=1.3194 c=0.0875
            4'h2: begin slope = 16'h4FE0; intercept = 16'h0AE0; end // m=1.2480 c=0.1699
            4'h3: begin slope = 16'h4BC7; intercept = 16'h0FDE; end // m=1.1840 c=0.2479
            4'h4: begin slope = 16'h4814; intercept = 16'h149A; end // m=1.1262 c=0.3219
            4'h5: begin slope = 16'h44BA; intercept = 16'h191C; end // m=1.0738 c=0.3923
            4'h6: begin slope = 16'h41AB; intercept = 16'h1D67; end // m=1.0261 c=0.4594
            4'h7: begin slope = 16'h3EE0; intercept = 16'h2182; end // m=0.9824 c=0.5236
            4'h8: begin slope = 16'h3C4F; intercept = 16'h2570; end // m=0.9423 c=0.5850
            4'h9: begin slope = 16'h39F1; intercept = 16'h2935; end // m=0.9053 c=0.6439
            4'hA: begin slope = 16'h37C1; intercept = 16'h2CD4; end // m=0.8712 c=0.7004
            4'hB: begin slope = 16'h35BA; intercept = 16'h3050; end // m=0.8395 c=0.7549
            4'hC: begin slope = 16'h33D7; intercept = 16'h33AC; end // m=0.8100 c=0.8074
            4'hD: begin slope = 16'h3215; intercept = 16'h36E9; end // m=0.7826 c=0.8580
            4'hE: begin slope = 16'h3071; intercept = 16'h3A0A; end // m=0.7569 c=0.9069
            4'hF: begin slope = 16'h2EE7; intercept = 16'h3D12; end // m=0.7329 c=0.9542
        endcase
    end

endmodule
