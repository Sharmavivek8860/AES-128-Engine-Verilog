// inv_shift_rows.v
module inv_shift_rows (
    input  [127:0] state_in,
    output [127:0] state_out
);
    wire [7:0] s[0:15];
    genvar i;
    generate
        for (i=0; i<16; i=i+1) begin : SPLIT
            assign s[i] = state_in[127 - 8*i -: 8];
        end
    endgenerate

    // Inverse mapping to recover column-major b[0..15]
    wire [7:0] b[0:15];
    assign b[0]  = s[0];
    assign b[1]  = s[13];
    assign b[2]  = s[10];
    assign b[3]  = s[7];
    assign b[4]  = s[4];
    assign b[5]  = s[1];
    assign b[6]  = s[14];
    assign b[7]  = s[11];
    assign b[8]  = s[8];
    assign b[9]  = s[5];
    assign b[10] = s[2];
    assign b[11] = s[15];
    assign b[12] = s[12];
    assign b[13] = s[9];
    assign b[14] = s[6];
    assign b[15] = s[3];

    assign state_out = {
        b[0], b[1], b[2], b[3],
        b[4], b[5], b[6], b[7],
        b[8], b[9], b[10], b[11],
        b[12], b[13], b[14], b[15]
    };
endmodule
