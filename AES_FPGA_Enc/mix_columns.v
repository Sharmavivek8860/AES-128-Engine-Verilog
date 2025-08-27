// mix_columns.v
// AES MixColumns for column-major state (MSB-first bytes).

module mix_columns (
    input  [127:0] state_in,
    output [127:0] state_out
);
    // Split into bytes b[0..15]
    wire [7:0] b[0:15];
    genvar i;
    generate
        for (i=0; i<16; i=i+1) begin : SPLIT
            assign b[i] = state_in[127 - 8*i -: 8];
        end
    endgenerate

    // GF(2^8) helpers
    function [7:0] xtime; input [7:0] a;
        begin xtime = a[7] ? ((a<<1) ^ 8'h1b) : (a<<1); end
    endfunction
    function [7:0] mul2; input [7:0] a; begin mul2 = xtime(a); end endfunction
    function [7:0] mul3; input [7:0] a; begin mul3 = xtime(a) ^ a; end endfunction

    // Mix each column
    `define MIXCOL(a0,a1,a2,a3,r0,r1,r2,r3) \
        assign r0 = mul2(a0) ^ mul3(a1) ^      (a2) ^      (a3); \
        assign r1 =      (a0) ^ mul2(a1) ^ mul3(a2) ^      (a3); \
        assign r2 =      (a0) ^      (a1) ^ mul2(a2) ^ mul3(a3); \
        assign r3 = mul3(a0) ^      (a1) ^      (a2) ^ mul2(a3)

    wire [7:0] r0,r1,r2,r3, r4,r5,r6,r7, r8,r9,r10,r11, r12,r13,r14,r15;

    // Columns are grouped as bytes: (0,1,2,3), (4,5,6,7), (8,9,10,11), (12,13,14,15)
    `MIXCOL(b[0], b[1], b[2], b[3],    r0,  r1,  r2,  r3);
    `MIXCOL(b[4], b[5], b[6], b[7],    r4,  r5,  r6,  r7);
    `MIXCOL(b[8], b[9], b[10], b[11],  r8,  r9,  r10, r11);
    `MIXCOL(b[12],b[13],b[14],b[15],  r12, r13, r14, r15);

    assign state_out = {
        r0, r1, r2, r3,
        r4, r5, r6, r7,
        r8, r9, r10, r11,
        r12, r13, r14, r15
    };

    `undef MIXCOL
endmodule
