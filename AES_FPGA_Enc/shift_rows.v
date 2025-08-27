// shift_rows.v
// AES ShiftRows with column-major state layout (MSB-first bytes).

module shift_rows (
    input  [127:0] state_in,
    output [127:0] state_out
);
    // Split into bytes b[0..15], where b[i] = state_in[127 - 8*i -: 8]
    wire [7:0] b[0:15];
    genvar i;
    generate
        for (i=0; i<16; i=i+1) begin : SPLIT
            assign b[i] = state_in[127 - 8*i -: 8];
        end
    endgenerate

    // Row mapping (column-major):
    // Row0: b0,  b4,  b8,  b12 (no shift)
    // Row1: b5,  b9,  b13, b1  (shift by 1)
    // Row2: b10, b14, b2,  b6  (shift by 2)
    // Row3: b15, b3,  b7,  b11 (shift by 3)
    wire [7:0] o[0:15];
    assign o[ 0] = b[ 0]; assign o[ 4] = b[ 4]; assign o[ 8] = b[ 8]; assign o[12] = b[12];
    assign o[ 1] = b[ 5]; assign o[ 5] = b[ 9]; assign o[ 9] = b[13]; assign o[13] = b[ 1];
    assign o[ 2] = b[10]; assign o[ 6] = b[14]; assign o[10] = b[ 2]; assign o[14] = b[ 6];
    assign o[ 3] = b[15]; assign o[ 7] = b[ 3]; assign o[11] = b[ 7]; assign o[15] = b[11];

    // Repack MSB-first
    assign state_out = {
        o[0], o[1], o[2], o[3],
        o[4], o[5], o[6], o[7],
        o[8], o[9], o[10], o[11],
        o[12], o[13], o[14], o[15]
    };
endmodule
