
module antilog_coefficient_mux (
    input  wire [3:0] segment_address,
    input  wire [1:0] precision_level,
    output reg  [15:0] slope,
    output reg  [15:0] intercept
);

    always @(*) begin
        case (segment_address)
            4'h0: begin slope = 16'h2D56; intercept = 16'h4000; end // m=0.7084 c=1.0000
            4'h1: begin slope = 16'h2F58; intercept = 16'h42D5; end // m=0.7397 c=1.0443
            4'h2: begin slope = 16'h3171; intercept = 16'h45CB; end // m=0.7725 c=1.0905
            4'h3: begin slope = 16'h33A1; intercept = 16'h48E2; end // m=0.8067 c=1.1388
            4'h4: begin slope = 16'h35EA; intercept = 16'h4C1C; end // m=0.8424 c=1.1892
            4'h5: begin slope = 16'h384D; intercept = 16'h4F7B; end // m=0.8797 c=1.2419
            4'h6: begin slope = 16'h3ACB; intercept = 16'h52FF; end // m=0.9187 c=1.2968
            4'h7: begin slope = 16'h3D66; intercept = 16'h56AC; end // m=0.9593 c=1.3543
            4'h8: begin slope = 16'h401E; intercept = 16'h5A82; end // m=1.0018 c=1.4142
            4'h9: begin slope = 16'h42F4; intercept = 16'h5E84; end // m=1.0462 c=1.4768
            4'hA: begin slope = 16'h45EB; intercept = 16'h62B4; end // m=1.0925 c=1.5422
            4'hB: begin slope = 16'h4904; intercept = 16'h6712; end // m=1.1408 c=1.6105
            4'hC: begin slope = 16'h4C3F; intercept = 16'h6BA2; end // m=1.1913 c=1.6818
            4'hD: begin slope = 16'h4F9F; intercept = 16'h7066; end // m=1.2441 c=1.7563
            4'hE: begin slope = 16'h5326; intercept = 16'h7560; end // m=1.2992 c=1.8340
            4'hF: begin slope = 16'h56D4; intercept = 16'h7A93; end // m=1.3567 c=1.9152
        endcase
    end

endmodule
